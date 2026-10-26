// Onde a sessao (token + usuario) fica guardada no aparelho.
//
// Em producao: Keychain (iOS) / Keystore (Android) via flutter_secure_storage.
// O token da acesso a conta, entao nao vai para o SQLite nem para prefs.
library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_models.dart';

abstract class SessionStore {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

const String _kSessionKey = 'auth_session';

class SecureSessionStore implements SessionStore {
  // first_unlock: o sync de fundo roda com a tela bloqueada; com o padrao
  // (`unlocked`) o Keychain negaria a leitura e o upload nunca aconteceria.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<AuthSession?> read() async {
    final raw = await _storage.read(key: _kSessionKey);
    if (raw == null) return null;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Formato antigo/corrompido: trata como deslogado.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) =>
      _storage.write(key: _kSessionKey, value: jsonEncode(session.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _kSessionKey);
}

/// Para testes e para plataformas sem armazenamento seguro.
class InMemorySessionStore implements SessionStore {
  AuthSession? _session;
  InMemorySessionStore([this._session]);

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> write(AuthSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
