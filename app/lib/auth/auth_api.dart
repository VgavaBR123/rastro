// Cliente HTTP das rotas de conta do NOSSO backend (nunca o Strava).
// Contrato em backend/README.md: /auth/register, /auth/login, /auth/logout, /me.
library;

import 'package:dio/dio.dart';

import 'auth_models.dart';

class AuthApi {
  final Dio _dio;
  final String _baseUrl;

  AuthApi(this._dio, this._baseUrl);

  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final body = await _send('POST', '/auth/register', data: {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    return AuthSession.fromJson(body);
  }

  Future<AuthSession> login({required String email, required String password}) async {
    final body = await _send('POST', '/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthSession.fromJson(body);
  }

  Future<void> logout(String token) => _send('POST', '/auth/logout', token: token);

  Future<Profile> me(String token) async {
    final body = await _send('GET', '/me', token: token);
    return Profile(
      AppUser.fromJson(body['user'] as Map<String, dynamic>),
      ProfileStats.fromJson(body['stats'] as Map<String, dynamic>),
    );
  }

  Future<AppUser> updateDisplayName(String token, String displayName) async {
    final body = await _send('PATCH', '/me',
        token: token, data: {'displayName': displayName});
    return AppUser.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? data,
  }) async {
    final Response<dynamic> r;
    try {
      r = await _dio.request<dynamic>(
        '$_baseUrl$path',
        data: data,
        options: Options(
          method: method,
          contentType: Headers.jsonContentType,
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
          validateStatus: (s) => s != null,
        ),
      );
    } on DioException {
      throw const AuthException('Sem conexao com o servidor');
    }
    final status = r.statusCode!;
    final body = r.data;
    if (status >= 200 && status < 300) {
      return body is Map<String, dynamic> ? body : const {};
    }
    throw AuthException(
      _messageFor(status, body, r.headers.value('retry-after')),
      statusCode: status,
    );
  }

  static String _messageFor(int status, Object? body, String? retryAfter) {
    switch (status) {
      case 429:
        return 'Muitas tentativas. ${waitHint(retryAfter)}';
      case 401:
        return 'E-mail ou senha incorretos';
      case 409:
        return 'Ja existe uma conta com este e-mail';
      case 400:
        if (body is Map && body['error'] is String) return body['error'] as String;
        return 'Dados invalidos';
      default:
        return 'Erro no servidor ($status)';
    }
  }

  /// Texto de espera a partir do header Retry-After (segundos).
  static String waitHint(String? retryAfterSeconds) {
    final secs = int.tryParse(retryAfterSeconds?.trim() ?? '');
    if (secs == null || secs <= 0) return 'Tente de novo mais tarde.';
    if (secs < 60) return 'Tente de novo em $secs s.';
    final mins = (secs / 60).ceil();
    return 'Tente de novo em $mins min.';
  }
}
