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

class FcmPushSender implements PushSender {
  FcmPushSender({
    required this.projectId,
    required Future<String> Function() accessToken,
    required http.Client client,
  })  : _obterToken = accessToken,
        _client = client;

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
    auth.AccessCredentials? atual;
    return FcmPushSender(
      projectId: projeto,
      client: c,
      accessToken: () async {
        final DateTime limite =
            DateTime.now().toUtc().add(const Duration(minutes: 1));
        if (atual == null || atual!.accessToken.expiry.isBefore(limite)) {
          atual = await auth.obtainAccessCredentialsViaServiceAccount(
              cred, const [escopoFcm], c);
        }
        return atual!.accessToken.data;
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
  final Future<String> Function() _obterToken;
  final http.Client _client;
  String? _tokenCache;

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

  @override
  Future<PushResult> send(PushMessage m) async {
    try {
      final String acesso = _tokenCache ??= await _obterToken();
      final http.Response r = await _client.post(
        _url,
        headers: {
          'authorization': 'Bearer $acesso',
          'content-type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(corpo(m)),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) return PushResult.sent;
      if (r.statusCode == 401) _tokenCache = null; // renova no proximo
      if (r.statusCode == 404 || _naoRegistrado(r.body)) {
        return PushResult.invalidToken;
      }
      stderr.writeln('fcm: ${m.notificationId} falhou com ${r.statusCode}');
      return PushResult.failed;
    } catch (e) {
      stderr.writeln('fcm: ${m.notificationId} falhou: ${e.runtimeType}');
      return PushResult.failed;
    }
  }

  /// `errorCode: UNREGISTERED` nos detalhes do erro do FCM.
  static bool _naoRegistrado(String corpo) {
    try {
      final Object? j = jsonDecode(corpo);
      if (j is! Map) return false;
      final Object? erro = j['error'];
      if (erro is! Map) return false;
      final Object? detalhes = erro['details'];
      if (detalhes is! List) return false;
      return detalhes
          .any((d) => d is Map && d['errorCode'] == 'UNREGISTERED');
    } on FormatException {
      return false;
    }
  }
}
