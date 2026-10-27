// Cliente HTTP das rotas de conta do NOSSO backend (nunca o Strava).
// Contrato em backend/docs/CONTRATO.md (secao Conta): /auth/*, /me.
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
    final body = await _send(
      'POST',
      '/auth/register',
      data: {'email': email, 'password': password, 'displayName': displayName},
    );
    return AuthSession.fromJson(body);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final body = await _send(
      'POST',
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(body);
  }

  Future<void> logout(String token) =>
      _send('POST', '/auth/logout', token: token);

  Future<Profile> me(String token) async {
    final body = await _send('GET', '/me', token: token);
    return Profile(
      AppUser.fromJson(body['user'] as Map<String, dynamic>),
      ProfileStats.fromJson(body['stats'] as Map<String, dynamic>),
    );
  }

  Future<AppUser> updateDisplayName(String token, String displayName) async {
    final body = await _send(
      'PATCH',
      '/me',
      token: token,
      data: {'displayName': displayName},
    );
    return AppUser.fromJson(body['user'] as Map<String, dynamic>);
  }

  /// Revoga TODAS as sessoes do usuario, inclusive a atual.
  Future<void> logoutAll(String token) =>
      _send('POST', '/auth/logout-all', token: token);

  /// Troca a senha. O servidor revoga as outras sessoes; a atual segue valida.
  /// 403 = senha atual errada.
  Future<void> changePassword(
    String token,
    String currentPassword,
    String newPassword,
  ) => _send(
    'POST',
    '/auth/password/change',
    token: token,
    data: {'currentPassword': currentPassword, 'newPassword': newPassword},
  );

  /// Pede o codigo de recuperacao. O servidor responde 202 sempre (nao revela
  /// se o e-mail tem conta).
  Future<void> forgotPassword(String email) =>
      _send('POST', '/auth/password/forgot', data: {'email': email});

  /// Troca a senha com o codigo recebido por e-mail e ja devolve a sessao nova.
  Future<AuthSession> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final body = await _send(
      'POST',
      '/auth/password/reset',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
      badRequestFallback: 'Codigo invalido ou expirado',
    );
    return AuthSession.fromJson(body);
  }

  /// Apaga a conta e todas as atividades dela no servidor. 403 = senha errada.
  Future<void> deleteAccount(String token, String password) => _send(
    'DELETE',
    '/me',
    token: token,
    data: {'password': password},
    forbiddenMessage: 'Senha incorreta',
  );

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? data,
    String badRequestFallback = 'Dados invalidos',
    String forbiddenMessage = 'Senha atual incorreta',
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
    final String message;
    if (status == 401 && token != null) {
      // Rota protegida: o token foi revogado/expirou (o controller desloga).
      message = 'Sessao expirada. Entre de novo.';
    } else if (status == 403) {
      message = forbiddenMessage;
    } else {
      message = _messageFor(
        status,
        body,
        r.headers.value('retry-after'),
        badRequestFallback,
      );
    }
    throw AuthException(message, statusCode: status);
  }

  static String _messageFor(
    int status,
    Object? body,
    String? retryAfter,
    String badRequestFallback,
  ) {
    switch (status) {
      case 429:
        return 'Muitas tentativas. ${waitHint(retryAfter)}';
      case 401:
        return 'E-mail ou senha incorretos';
      case 409:
        return 'Ja existe uma conta com este e-mail';
      case 400:
        if (body is Map && body['error'] is String) {
          return _capitalize(body['error'] as String);
        }
        return badRequestFallback;
      default:
        return 'Erro no servidor ($status)';
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Texto de espera a partir do header Retry-After (segundos).
  static String waitHint(String? retryAfterSeconds) {
    final secs = int.tryParse(retryAfterSeconds?.trim() ?? '');
    if (secs == null || secs <= 0) return 'Tente de novo mais tarde.';
    if (secs < 60) return 'Tente de novo em $secs s.';
    final mins = (secs / 60).ceil();
    return 'Tente de novo em $mins min.';
  }
}
