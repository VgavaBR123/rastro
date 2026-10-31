// Push pelo Firebase Cloud Messaging, API HTTP v1. Ativado no bin/server.dart
// so quando FIREBASE_SERVICE_ACCOUNT aponta para o JSON da conta de servico.
// O token de acesso OAuth2 sai do JWT assinado com a chave da conta de
// servico (pacote googleapis_auth) e fica em cache ate perto de expirar.
//
// Nunca registra o token de acesso, a chave nem o corpo da notificacao.
library;

import 'dart:convert';
import 'dart:io' show File, stderr;

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import 'push_sender.dart';

/// Escopo do OAuth2 para enviar mensagens pelo FCM.
const String escopoFcm = 'https://www.googleapis.com/auth/firebase.messaging';

/// Token de acesso OAuth2 e quando ele expira (UTC).
class FcmAccessToken {
  const FcmAccessToken(this.token, this.expiry);
  final String token;
  final DateTime expiry;
}

class FcmPushSender implements PushSender {
  FcmPushSender({
    required this.projectId,
    required Future<FcmAccessToken> Function() accessToken,
    required http.Client client,
    DateTime Function()? agora,
  })  : _obterToken = accessToken,
        _client = client,
        _agora = agora ?? (() => DateTime.now().toUtc());

  /// A partir do JSON da conta de servico (o conteudo do arquivo).
  factory FcmPushSender.fromServiceAccountJson(Map<String, dynamic> json,
      {http.Client? client}) {
    final Object? projeto = json['project_id'];
    if (projeto is! String || projeto.isEmpty) {
      throw const FormatException('conta de servico sem project_id');
    }
    final http.Client c = client ?? http.Client();
    final auth.ServiceAccountCredentials cred =
        auth.ServiceAccountCredentials.fromJson(json);
    return FcmPushSender(
      projectId: projeto,
      client: c,
      accessToken: () async {
        final auth.AccessCredentials cr =
            await auth.obtainAccessCredentialsViaServiceAccount(
                cred, const [escopoFcm], c);
        return FcmAccessToken(cr.accessToken.data, cr.accessToken.expiry);
      },
    );
  }

  /// Le o arquivo apontado por FIREBASE_SERVICE_ACCOUNT.
  static Future<FcmPushSender> fromServiceAccountFile(String caminho) async {
    final Object? json = jsonDecode(await File(caminho).readAsString());
    if (json is! Map<String, dynamic>) {
      throw const FormatException('conta de servico nao e um objeto JSON');
    }
    return FcmPushSender.fromServiceAccountJson(json);
  }

  final String projectId;
  final Future<FcmAccessToken> Function() _obterToken;
  final http.Client _client;
  final DateTime Function() _agora;
  FcmAccessToken? _cache;

  /// Margem antes da expiracao em que o token ja e trocado.
  static const Duration margemRenovacao = Duration(minutes: 1);

  Uri get _url => Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

  /// Corpo da requisicao. No FCM os valores de `data` precisam ser texto:
  /// numeros viram texto e objetos viram JSON.
  static Map<String, dynamic> corpo(PushMessage m) => {
        'message': {
          'token': m.token,
          'notification': {'title': m.title, 'body': m.body},
          'data': {
            'type': m.type,
            'notificationId': m.notificationId,
            for (final e in m.data.entries)
              if (e.value != null)
                e.key: e.value is String ? e.value as String : jsonEncode(e.value),
          },
          'android': {'priority': 'high'},
        },
      };

  /// Token de acesso em cache enquanto falta mais que [margemRenovacao]
  /// para expirar; senao (ou com [renovar]) busca um novo.
  Future<String> _tokenDeAcesso({bool renovar = false}) async {
    final FcmAccessToken? c = _cache;
    if (!renovar &&
        c != null &&
        _agora().add(margemRenovacao).isBefore(c.expiry)) {
      return c.token;
    }
    final FcmAccessToken novo = await _obterToken();
    _cache = novo;
    return novo.token;
  }

  Future<http.Response> _post(String acesso, PushMessage m) => _client.post(
        _url,
        headers: {
          'authorization': 'Bearer $acesso',
          'content-type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(corpo(m)),
      );

  @override
  Future<PushResult> send(PushMessage m) async {
    try {
      http.Response r = await _post(await _tokenDeAcesso(), m);
      if (r.statusCode == 401) {
        // Token revogado ou expirado antes da hora: renova e tenta uma vez.
        r = await _post(await _tokenDeAcesso(renovar: true), m);
      }
      if (r.statusCode >= 200 && r.statusCode < 300) return PushResult.sent;
      if (tokenInvalido(r.body)) return PushResult.invalidToken;
      stderr.writeln('fcm: ${m.notificationId} falhou com ${r.statusCode}');
      return PushResult.failed;
    } catch (e) {
      stderr.writeln('fcm: ${m.notificationId} falhou: ${e.runtimeType}');
      return PushResult.failed;
    }
  }

  /// O token do aparelho nao vale mais: `errorCode: UNREGISTERED` nos
  /// detalhes, ou INVALID_ARGUMENT apontando o campo `message.token`. Um 404
  /// ou 400 sem isso (payload, projeto) nao apaga o token.
  static bool tokenInvalido(String corpo) {
    try {
      final Object? j = jsonDecode(corpo);
      if (j is! Map) return false;
      final Object? erro = j['error'];
      if (erro is! Map) return false;
      final Object? detalhes = erro['details'];
      if (detalhes is! List) return false;
      for (final Object? d in detalhes) {
        if (d is! Map) continue;
        if (d['errorCode'] == 'UNREGISTERED') return true;
        final Object? violacoes = d['fieldViolations'];
        if (erro['status'] == 'INVALID_ARGUMENT' &&
            violacoes is List &&
            violacoes.any((v) => v is Map && v['field'] == 'message.token')) {
          return true;
        }
      }
      return false;
    } on FormatException {
      return false;
    }
  }
}
