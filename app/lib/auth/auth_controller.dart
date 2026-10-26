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

  AuthController(this._api, this._store, {this.onSignedIn}) : super(const AuthState());

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
      if (mounted) state = AuthState(status: AuthStatus.signedIn, user: profile.user);
    } on AuthException catch (e) {
      // Token revogado/expirado: sai. Sem rede: continua logado com o cache.
      if (e.isUnauthorized) await _signOutLocally();
    }
  }

  Future<bool> register(String email, String password, String displayName) =>
      _enter(() => _api.register(
            email: email.trim(),
            password: password,
            displayName: displayName.trim(),
          ));

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

  Future<void> logout() async {
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
      final user = await _api.updateDisplayName(session.token, displayName.trim());
      await _store.write(AuthSession(token: session.token, user: user));
      state = AuthState(status: AuthStatus.signedIn, user: user);
      return true;
    } on AuthException catch (e) {
      if (e.isUnauthorized) {
        await _signOutLocally();
      } else {
        state = AuthState(status: state.status, user: state.user, error: e.message);
      }
      return false;
    }
  }

  Future<void> _signOutLocally() async {
    await _store.clear();
    if (mounted) state = const AuthState(status: AuthStatus.signedOut);
  }
}
