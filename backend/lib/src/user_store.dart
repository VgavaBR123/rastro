// Armazenamento de usuarios e sessoes. Mesmo padrao do ActivityStore:
// abstracao + implementacao em memoria para os testes da API; a versao
// Postgres fica em postgres_user_store.dart.
library;

class UserRecord {
  final String id;
  final String email; // ja normalizado (trim + lowercase)
  final String passwordHash; // pbkdf2_sha256$... (nunca sai na API)
  final String displayName;
  final int createdAtMs;

  const UserRecord({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.displayName,
    required this.createdAtMs,
  });

  UserRecord copyWith({String? displayName}) => UserRecord(
        id: id,
        email: email,
        passwordHash: passwordHash,
        displayName: displayName ?? this.displayName,
        createdAtMs: createdAtMs,
      );

  /// Forma publica do usuario (sem o hash da senha).
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'createdAt': createdAtMs,
      };
}

class SessionRecord {
  final String tokenHash;
  final String userId;
  final int createdAtMs;
  final int expiresAtMs;

  const SessionRecord({
    required this.tokenHash,
    required this.userId,
    required this.createdAtMs,
    required this.expiresAtMs,
  });
}

abstract class UserStore {
  /// Cria o usuario. Devolve null se o email ja existe (o chamador responde
  /// 409). O email chega normalizado.
  Future<UserRecord?> createUser(UserRecord user);
  Future<UserRecord?> findByEmail(String email);
  Future<UserRecord?> findById(String id);

  /// Devolve o usuario atualizado, ou null se nao existe.
  Future<UserRecord?> updateDisplayName(String id, String displayName);

  Future<void> createSession(SessionRecord session);
  Future<SessionRecord?> findSession(String tokenHash);
  Future<void> deleteSession(String tokenHash);
}

class InMemoryUserStore implements UserStore {
  final Map<String, UserRecord> _users = {};
  final Map<String, SessionRecord> _sessions = {};

  @override
  Future<UserRecord?> createUser(UserRecord user) async {
    if (_users.values.any((u) => u.email == user.email)) return null;
    _users[user.id] = user;
    return user;
  }

  @override
  Future<UserRecord?> findByEmail(String email) async {
    for (final u in _users.values) {
      if (u.email == email) return u;
    }
    return null;
  }

  @override
  Future<UserRecord?> findById(String id) async => _users[id];

  @override
  Future<UserRecord?> updateDisplayName(String id, String displayName) async {
    final UserRecord? u = _users[id];
    if (u == null) return null;
    return _users[id] = u.copyWith(displayName: displayName);
  }

  @override
  Future<void> createSession(SessionRecord session) async {
    _sessions[session.tokenHash] = session;
  }

  @override
  Future<SessionRecord?> findSession(String tokenHash) async =>
      _sessions[tokenHash];

  @override
  Future<void> deleteSession(String tokenHash) async {
    _sessions.remove(tokenHash);
  }
}
