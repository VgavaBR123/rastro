// Implementacao do UserStore sobre PostgreSQL. As tabelas users e sessions
// sao criadas pelo PostgresActivityStore ao conectar (_ensureSchema), que
// tambem fornece a conexao compartilhada.
library;

import 'package:postgres/postgres.dart';

import 'user_store.dart';

class PostgresUserStore implements UserStore {
  final Connection _conn;
  PostgresUserStore(this._conn);

  static const String _selectUsers =
      'SELECT id, email, password_hash, display_name, created_at FROM users ';

  @override
  Future<UserRecord?> createUser(UserRecord user) async {
    // ON CONFLICT cobre o cadastro simultaneo do mesmo email: um so insere e
    // o outro recebe null (409), sem estourar excecao de unicidade.
    final result = await _conn.execute(
      Sql.named(
        'INSERT INTO users (id, email, password_hash, display_name, created_at) '
        'VALUES (@id, @email, @hash, @name, @created) '
        'ON CONFLICT (email) DO NOTHING RETURNING id',
      ),
      parameters: {
        'id': user.id,
        'email': user.email,
        'hash': user.passwordHash,
        'name': user.displayName,
        'created': user.createdAtMs,
      },
    );
    return result.isEmpty ? null : user;
  }

  @override
  Future<UserRecord?> findByEmail(String email) async {
    final result = await _conn.execute(
      Sql.named('${_selectUsers}WHERE email = @email'),
      parameters: {'email': email},
    );
    return result.isEmpty ? null : _fromRow(result.first.toColumnMap());
  }

  @override
  Future<UserRecord?> findById(String id) async {
    final result = await _conn.execute(
      Sql.named('${_selectUsers}WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.isEmpty ? null : _fromRow(result.first.toColumnMap());
  }

  @override
  Future<UserRecord?> updateDisplayName(String id, String displayName) async {
    final result = await _conn.execute(
      Sql.named(
        'UPDATE users SET display_name = @name WHERE id = @id '
        'RETURNING id, email, password_hash, display_name, created_at',
      ),
      parameters: {'id': id, 'name': displayName},
    );
    return result.isEmpty ? null : _fromRow(result.first.toColumnMap());
  }

  @override
  Future<void> createSession(SessionRecord session) async {
    await _conn.execute(
      Sql.named(
        'INSERT INTO sessions (token_hash, user_id, created_at, expires_at) '
        'VALUES (@hash, @user_id, @created, @expires)',
      ),
      parameters: {
        'hash': session.tokenHash,
        'user_id': session.userId,
        'created': session.createdAtMs,
        'expires': session.expiresAtMs,
      },
    );
  }

  @override
  Future<SessionRecord?> findSession(String tokenHash) async {
    final result = await _conn.execute(
      Sql.named(
        'SELECT token_hash, user_id, created_at, expires_at '
        'FROM sessions WHERE token_hash = @hash',
      ),
      parameters: {'hash': tokenHash},
    );
    if (result.isEmpty) return null;
    final m = result.first.toColumnMap();
    return SessionRecord(
      tokenHash: m['token_hash'] as String,
      userId: m['user_id'] as String,
      createdAtMs: m['created_at'] as int,
      expiresAtMs: m['expires_at'] as int,
    );
  }

  @override
  Future<void> deleteSession(String tokenHash) async {
    await _conn.execute(
      Sql.named('DELETE FROM sessions WHERE token_hash = @hash'),
      parameters: {'hash': tokenHash},
    );
  }

  UserRecord _fromRow(Map<String, dynamic> m) => UserRecord(
        id: m['id'] as String,
        email: m['email'] as String,
        passwordHash: m['password_hash'] as String,
        displayName: m['display_name'] as String,
        createdAtMs: m['created_at'] as int,
      );
}
