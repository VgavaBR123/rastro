// Estado da conta (Riverpod StateNotifier). Offline-first: gravar nao exige
// conta; ela so e necessaria para sincronizar. Uma sessao guardada abre o app
// logado mesmo sem rede, e o /me so confirma/atualiza quando ha conexao.
library;

import 'package:flutter_riverpod/legacy.dart';

import 'auth_api.dart';
import 'auth_models.dart';
import 'session_store.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final bool busy;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.busy = false,
    this.error,
  });

  bool get isSignedIn => status == AuthStatus.signedIn;
}

class AuthController extends StateNotifier<AuthState> {
  final AuthApi _api;
  final SessionStore _store;

  /// Chamado depois de entrar na conta (ex.: agendar o sync dos pendentes).
  final void Function()? onSignedIn;

  /// Antes de sair da conta, com o token ainda guardado: tirar o aparelho do
  /// push e encerrar o Rastro Seguro (F08). Falha ou demora nao impedem sair.
  final Future<void> Function()? beforeSignOut;

  AuthController(this._api, this._store, {this.onSignedIn, this.beforeSignOut})
    : super(const AuthState());

  Future<void> load() async {
    final AuthSession? session;
    try {
      session = await _store.read();
    } on Object {
      // Keystore/Keychain indisponivel ou corrompido: segue deslogado.
      if (mounted) state = const AuthState(status: AuthStatus.signedOut);
      return;
    }
    if (session == null) {
      state = const AuthState(status: AuthStatus.signedOut);
      return;
    }
    state = AuthState(status: AuthStatus.signedIn, user: session.user);
    try {
      final profile = await _api.me(session.token);
      await _store.write(AuthSession(token: session.token, user: profile.user));
      if (mounted) {
        state = AuthState(status: AuthStatus.signedIn, user: profile.user);
      }
    } on AuthException catch (e) {
      // Token revogado/expirado: sai. Sem rede: continua logado com o cache.
      if (e.isUnauthorized) await _signOutLocally();
    }
  }

  Future<bool> register(String email, String password, String displayName) =>
      _enter(
        () => _api.register(
          email: email.trim(),
          password: password,
          displayName: displayName.trim(),
        ),
      );

  Future<bool> login(String email, String password) =>
      _enter(() => _api.login(email: email.trim(), password: password));

  Future<bool> _enter(Future<AuthSession> Function() call) async {
    if (state.busy) return false;
    state = AuthState(status: state.status, user: state.user, busy: true);
    try {
      final session = await call();
      await _store.write(session);
      state = AuthState(status: AuthStatus.signedIn, user: session.user);
      onSignedIn?.call();
      return true;
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.signedOut, error: e.message);
      return false;
    }
  }

  Future<void> _runBeforeSignOut() async {
    final hook = beforeSignOut;
    if (hook == null) return;
    try {
      await hook().timeout(const Duration(seconds: 10));
    } on Object {
      // Sem rede ou demorou: o que nao saiu fica pendente para o proximo login.
    }
  }

  Future<void> logout() async {
    await _runBeforeSignOut();
    final session = await _store.read();
    if (session != null) {
      try {
        await _api.logout(session.token);
      } on AuthException {
        // Sem rede: o token so deixa de existir aqui; o servidor o expira.
      }
    }
    await _signOutLocally();
  }

  Future<bool> updateDisplayName(String displayName) async {
    final session = await _store.read();
    if (session == null) return false;
    try {
      final user = await _api.updateDisplayName(
        session.token,
        displayName.trim(),
      );
      await _store.write(AuthSession(token: session.token, user: user));
      state = AuthState(status: AuthStatus.signedIn, user: user);
      return true;
    } on AuthException catch (e) {
      if (e.isUnauthorized) {
        await _signOutLocally();
      } else {
        state = AuthState(
          status: state.status,
          user: state.user,
          error: e.message,
        );
      }
      return false;
    }
  }

  /// Troca a senha. Sucesso: continua logado (o servidor so revoga as outras
  /// sessoes). 403 (senha atual errada): mostra o erro e NAO desloga.
  Future<bool> changePassword(String currentPassword, String newPassword) =>
      _protected(
        (token) => _api.changePassword(token, currentPassword, newPassword),
      );

  /// Revoga todas as sessoes no servidor e sai deste aparelho tambem.
  /// Sem rede: mostra o erro e continua logado (os outros aparelhos nao
  /// foram desconectados, entao fingir sucesso seria enganoso).
  Future<bool> logoutAll() => _protected((token) async {
    await _runBeforeSignOut();
    await _api.logoutAll(token);
    await _signOutLocally();
  });

  /// Apaga a conta (e as atividades dela no SERVIDOR) e sai. As atividades
  /// gravadas no aparelho continuam. 403 (senha errada): erro, segue logado.
  Future<bool> deleteAccount(String password) => _protected((token) async {
    await _runBeforeSignOut();
    await _api.deleteAccount(token, password);
    await _signOutLocally();
  });

  /// Pede o codigo de recuperacao por e-mail. Nao mexe na sessao.
  Future<bool> forgotPassword(String email) async {
    if (state.busy) return false;
    state = AuthState(status: state.status, user: state.user, busy: true);
    try {
      await _api.forgotPassword(email.trim());
      if (mounted) state = AuthState(status: state.status, user: state.user);
      return true;
    } on AuthException catch (e) {
      if (mounted) {
        state = AuthState(
          status: state.status,
          user: state.user,
          error: e.message,
        );
      }
      return false;
    }
  }

  /// Troca a senha com o codigo e ja entra com a sessao nova.
  Future<bool> resetPassword(String email, String code, String newPassword) =>
      _enter(
        () => _api.resetPassword(
          email: email.trim(),
          code: code.trim(),
          newPassword: newPassword,
        ),
      );

  /// Limpa a mensagem de erro (ex.: ao abrir outra tela de conta).
  void clearError() {
    if (state.error != null) {
      state = AuthState(
        status: state.status,
        user: state.user,
        busy: state.busy,
      );
    }
  }

  /// Executa uma chamada que exige o token da sessao atual. 401 desloga;
  /// qualquer outro erro (403, rede, 429) fica em `state.error` e segue logado.
  Future<bool> _protected(Future<void> Function(String token) call) async {
    if (state.busy) return false;
    final session = await _store.read();
    if (session == null) {
      await _signOutLocally();
      return false;
    }
    state = AuthState(status: state.status, user: state.user, busy: true);
    try {
      await call(session.token);
      if (mounted && state.busy) {
        state = AuthState(status: state.status, user: state.user);
      }
      return true;
    } on AuthException catch (e) {
      if (e.isUnauthorized) {
        await _signOutLocally();
      } else if (mounted) {
        state = AuthState(
          status: state.status,
          user: state.user,
          error: e.message,
        );
      }
      return false;
    }
  }

  Future<void> _signOutLocally() async {
    await _store.clear();
    if (mounted) state = const AuthState(status: AuthStatus.signedOut);
  }
}
