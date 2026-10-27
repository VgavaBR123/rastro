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

  UserRecord copyWith({String? displayName, String? passwordHash}) =>
      UserRecord(
        id: id,
        email: email,
        passwordHash: passwordHash ?? this.passwordHash,
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

/// Pedido de recuperacao de senha. Um por usuario: pedido novo substitui o
/// anterior. Guarda so o hash do codigo (PBKDF2 leve com salt, mesmo formato
/// das senhas), nunca o codigo em claro.
class PasswordResetRecord {
  final String userId;
  final String codeHash;
  final int createdAtMs;
  final int expiresAtMs;

  /// Tentativas ja consumidas (certas ou erradas).
  final int attempts;

  const PasswordResetRecord({
    required this.userId,
    required this.codeHash,
    required this.createdAtMs,
    required this.expiresAtMs,
    this.attempts = 0,
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

  /// Revoga todas as sessoes de [userId], menos a de [exceptTokenHash].
  Future<void> deleteSessionsForUser(String userId, {String? exceptTokenHash});

  /// Troca o hash da senha. Devolve o usuario atualizado ou null.
  Future<UserRecord?> updatePasswordHash(String id, String passwordHash);

  /// Apaga o usuario com sessoes e pedidos de recuperacao. (No Postgres as
  /// atividades vao junto pela FK em cascata.)
  Future<void> deleteUser(String id);

  /// Grava o pedido de recuperacao, substituindo o anterior do usuario.
  Future<void> savePasswordReset(PasswordResetRecord reset);

  /// Consome uma tentativa do pedido de [userId] de forma atomica: so devolve
  /// o pedido (com attempts ja incrementado) se ele existe, nao expirou em
  /// [nowMs] e ainda tinha tentativas (< [maxAttempts]). Consumir antes de
  /// conferir impede que tentativas simultaneas passem do limite.
  Future<PasswordResetRecord?> consumePasswordResetAttempt(String userId,
      {required int nowMs, required int maxAttempts});

  Future<void> deletePasswordReset(String userId);
}

class InMemoryUserStore implements UserStore {
  final Map<String, UserRecord> _users = {};
  final Map<String, SessionRecord> _sessions = {};
  final Map<String, PasswordResetRecord> _resets = {};

  /// Pedido de recuperacao guardado (para os testes conferirem o hash).
  PasswordResetRecord? resetDe(String userId) => _resets[userId];

  /// Quantas sessoes [userId] tem (para os testes).
  int sessoesDe(String userId) =>
      _sessions.values.where((s) => s.userId == userId).length;

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

  @override
  Future<void> deleteSessionsForUser(String userId,
      {String? exceptTokenHash}) async {
    _sessions.removeWhere((h, s) => s.userId == userId && h != exceptTokenHash);
  }

  @override
  Future<UserRecord?> updatePasswordHash(String id, String passwordHash) async {
    final UserRecord? u = _users[id];
    if (u == null) return null;
    return _users[id] = u.copyWith(passwordHash: passwordHash);
  }

  @override
  Future<void> deleteUser(String id) async {
    _users.remove(id);
    _sessions.removeWhere((_, s) => s.userId == id);
    _resets.remove(id);
  }

  @override
  Future<void> savePasswordReset(PasswordResetRecord reset) async {
    _resets[reset.userId] = reset;
  }

  @override
  Future<PasswordResetRecord?> consumePasswordResetAttempt(String userId,
      {required int nowMs, required int maxAttempts}) async {
    final PasswordResetRecord? r = _resets[userId];
    if (r == null || r.expiresAtMs <= nowMs || r.attempts >= maxAttempts) {
      return null;
    }
    return _resets[userId] = PasswordResetRecord(
      userId: r.userId,
      codeHash: r.codeHash,
      createdAtMs: r.createdAtMs,
      expiresAtMs: r.expiresAtMs,
      attempts: r.attempts + 1,
    );
  }

  @override
  Future<void> deletePasswordReset(String userId) async {
    _resets.remove(userId);
  }
}
