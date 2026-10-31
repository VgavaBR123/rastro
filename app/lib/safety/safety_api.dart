// Cliente HTTP do Rastro Seguro (F08) no NOSSO backend (nunca o Strava).
// Contrato em backend/docs/CONTRATO-RASTRO-SEGURO.md: /safety/contacts,
// /safety/sessions, /notifications e /push/tokens, todos com Bearer.
library;

import 'package:dio/dio.dart';

import 'safety_models.dart';

enum SafetyErrorKind {
  /// Sem rede ou servidor fora.
  network,

  /// Sem login, ou token revogado (401).
  unauthorized,
  notFound,
  conflict,
  badRequest,
  server,
}

/// Erro com mensagem pronta para a tela.
class SafetyException implements Exception {
  final SafetyErrorKind kind;
  final String message;
  final int? statusCode;
  const SafetyException(this.kind, this.message, {this.statusCode});

  @override
  String toString() => 'SafetyException($kind, $statusCode): $message';
}

/// Corpo de `POST /safety/sessions/<id>/positions`. Sem posicao nova, vai
/// como batimento (`lat`/`lon` null): o backend conta como sinal de vida.
class PositionReport {
  final double? lat;
  final double? lon;
  final double? accuracyM;
  final int recordedAtMs;
  final bool moving;
  final bool paused;

  const PositionReport({
    required double this.lat,
    required double this.lon,
    this.accuracyM,
    required this.recordedAtMs,
    required this.moving,
    required this.paused,
  });

  const PositionReport.heartbeat({
    required this.recordedAtMs,
    required this.moving,
    required this.paused,
  }) : lat = null,
       lon = null,
       accuracyM = null;

  bool get hasPosition => lat != null && lon != null;

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lon': lon,
    'accuracyM': accuracyM,
    'recordedAtMs': recordedAtMs,
    'moving': moving,
    'paused': paused,
  };
}

class SafetyApi {
  final Dio _dio;
  final String _baseUrl;
  final Future<String?> Function() _token;

  SafetyApi(this._dio, this._baseUrl, {required Future<String?> Function() token}) : _token = token;

  // --- Contatos de confianca ---

  Future<TrustedContact> invite(String email) async {
    final body = await _send(
      'POST',
      '/safety/contacts',
      data: {'email': email.trim().toLowerCase()},
      messages: const {
        404: 'Essa pessoa nao tem conta no Rastro. Peca para ela criar uma e tente de novo.',
        400: 'Nao da para convidar o proprio email.',
      },
      conflictMessage: _inviteConflict,
    );
    return TrustedContact.fromJson(body);
  }

  /// 409 do convite: o contrato usa o mesmo codigo para "ja existe o convite"
  /// e "ja tem 3 aceitos". O texto do erro decide; sem pista, a mensagem
  /// cobre os dois casos.
  static String _inviteConflict(Object? body) {
    final err = body is Map && body['error'] is String ? (body['error'] as String).toLowerCase() : '';
    if (err.contains('limite') || err.contains('3') || err.contains('max')) {
      return 'Voce ja tem 3 contatos aceitos, o maximo. Remova um para convidar outro.';
    }
    if (err.contains('convite') || err.contains('exist') || err.contains('ja ')) {
      return 'Essa pessoa ja foi convidada (ou ja e seu contato).';
    }
    return 'Essa pessoa ja foi convidada, ou voce ja tem 3 contatos aceitos.';
  }

  Future<ContactLists> contacts() async => ContactLists.fromJson(await _send('GET', '/safety/contacts'));

  Future<TrustedContact> accept(String contactId) async => TrustedContact.fromJson(
    await _send(
      'POST',
      '/safety/contacts/${Uri.encodeComponent(contactId)}/accept',
      messages: const {404: 'Convite nao encontrado. Ele pode ter sido cancelado.'},
    ),
  );

  Future<void> remove(String contactId) =>
      _send('DELETE', '/safety/contacts/${Uri.encodeComponent(contactId)}');

  // --- Sessao ---

  Future<SafetySession> createSession({
    required String activityGuid,
    required int etaMs,
    required List<String> contactIds,
  }) async => SafetySession.fromJson(
    await _send(
      'POST',
      '/safety/sessions',
      data: {'activityGuid': activityGuid, 'etaMs': etaMs, 'contactIds': contactIds},
      messages: const {
        400: 'Horario de chegada ou contatos invalidos.',
        409: 'Ja ha um Rastro Seguro ativo.',
      },
    ),
  );

  /// Sessao nao encerrada da conta, ou null (404).
  Future<SafetySession?> activeSession() async {
    try {
      return SafetySession.fromJson(await _send('GET', '/safety/sessions/active'));
    } on SafetyException catch (e) {
      if (e.kind == SafetyErrorKind.notFound) return null;
      rethrow;
    }
  }

  Future<SafetySession> session(String id) async => SafetySession.fromJson(await _send('GET', _s(id)));

  Future<SafetySession> postPosition(String id, PositionReport r) async =>
      SafetySession.fromJson(await _send('POST', '${_s(id)}/positions', data: r.toJson()));

  Future<SafetySession> ok(String id) async => SafetySession.fromJson(await _send('POST', '${_s(id)}/ok'));

  Future<SafetySession> extend(String id, int minutes) async =>
      SafetySession.fromJson(await _send('POST', '${_s(id)}/extend', data: {'minutes': minutes}));

  Future<SafetySession> arrived(String id) async =>
      SafetySession.fromJson(await _send('POST', '${_s(id)}/arrived'));

  Future<SafetySession> sos(String id) async => SafetySession.fromJson(await _send('POST', '${_s(id)}/sos'));

  static String _s(String id) => '/safety/sessions/${Uri.encodeComponent(id)}';

  // --- Notificacoes e push ---

  Future<List<AppNotification>> notifications({required int since}) async {
    final body = await _send('GET', '/notifications', query: {'since': '$since'});
    final list = body['notifications'];
    return list is List
        ? [for (final e in list) AppNotification.fromJson(e as Map<String, dynamic>)]
        : const [];
  }

  Future<void> markRead(String id) => _send('POST', '/notifications/${Uri.encodeComponent(id)}/read');

  Future<void> registerPushToken(String pushToken, String platform) =>
      _send('POST', '/push/tokens', data: {'token': pushToken, 'platform': platform});

  Future<void> deletePushToken(String pushToken) =>
      _send('DELETE', '/push/tokens/${Uri.encodeComponent(pushToken)}');

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? data,
    Map<String, String>? query,
    Map<int, String> messages = const {},
    String Function(Object? body)? conflictMessage,
  }) async {
    final token = await _token();
    if (token == null) {
      throw const SafetyException(SafetyErrorKind.unauthorized, 'Entre na sua conta para usar o Rastro Seguro.');
    }
    final Response<dynamic> r;
    try {
      r = await _dio.request<dynamic>(
        '$_baseUrl$path',
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          contentType: Headers.jsonContentType,
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (s) => s != null,
        ),
      );
    } on DioException {
      throw const SafetyException(SafetyErrorKind.network, 'Sem conexao com o servidor.');
    }
    final status = r.statusCode!;
    final body = r.data;
    if (status >= 200 && status < 300) {
      return body is Map<String, dynamic> ? body : const {};
    }
    final kind = switch (status) {
      401 => SafetyErrorKind.unauthorized,
      404 => SafetyErrorKind.notFound,
      409 => SafetyErrorKind.conflict,
      400 => SafetyErrorKind.badRequest,
      _ => SafetyErrorKind.server,
    };
    final message = status == 409 && conflictMessage != null
        ? conflictMessage(body)
        : messages[status] ??
              switch (kind) {
                SafetyErrorKind.unauthorized => 'Sessao expirada. Entre de novo.',
                SafetyErrorKind.notFound => 'Nao encontrado.',
                SafetyErrorKind.conflict => 'Conflito com o que ja existe.',
                SafetyErrorKind.badRequest => 'Dados invalidos.',
                _ => 'Erro no servidor ($status).',
              };
    throw SafetyException(kind, message, statusCode: status);
  }
}
