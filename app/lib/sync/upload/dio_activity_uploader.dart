// Implementacao de ActivityUploader com Dio (clean room,
// relatorios/06-sincronizacao.md).
//
// IMPORTANTE (limites do estudo, CLAUDE.md): este cliente NAO fala com a API
// privada do Strava. O baseUrl e um placeholder configuravel (ex.:
// 'https://example.invalid'); o endpoint '/uploads' e conceitual e descreve o
// padrao de upload assincrono descrito no relatorio 06, nao um endpoint real.
library;

// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';

/// Envia o FIT como corpo binario (application/octet-stream) em POST para
/// `$baseUrl/uploads`, com o guid da atividade no header `x-activity-guid`, e
/// extrai o uploadId do corpo da resposta. Esse e o contrato do nosso backend
/// (`backend/lib/src/api.dart`). Simples e defensivo: qualquer desvio vira
/// UploadException.
class DioActivityUploader implements ActivityUploader, RemoteActivityDeleter {
  final Dio _dio;
  final String _baseUrl;

  /// Token da sessao, lido a cada envio (o usuario pode ter saido/entrado
  /// entre um upload e outro). Null = envia sem Authorization.
  final Future<String?> Function()? _token;

  DioActivityUploader(Dio dio, String baseUrl, {Future<String?> Function()? token})
      : _dio = dio,
        _baseUrl = baseUrl,
        _token = token;

  @override
  Future<String> upload(
    Uint8List fitBytes, {
    required String activityGuid,
    UploadMetadata? metadata,
  }) async {
    final String? token = await _token?.call();
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/uploads',
        data: Stream<List<int>>.value(fitBytes),
        options: Options(
          headers: <String, dynamic>{
            Headers.contentTypeHeader: 'application/octet-stream',
            Headers.contentLengthHeader: fitBytes.length,
            'x-activity-guid': activityGuid,
            if (token != null) 'Authorization': 'Bearer $token',
            ...metadataHeaders(metadata),
          },
          // O backend responde 201 no sucesso; qualquer outro status cai no
          // tratamento abaixo em vez de virar DioException generica.
          validateStatus: (int? s) => s != null,
        ),
      );

      final int? status = response.statusCode;
      if (status == 401) {
        throw UnauthorizedUploadException();
      }
      if (status == null || status < 200 || status >= 300) {
        throw UploadException('status HTTP inesperado: $status');
      }

      return _extractUploadId(response.data, activityGuid);
    } on UploadException {
      rethrow;
    } on DioException catch (e) {
      throw UploadException('falha de transporte: ${e.message}');
    } catch (e) {
      throw UploadException('falha inesperada no upload: $e');
    }
  }

  /// Le o identificador de upload do corpo (campo 'id' ou 'uploadId'). Se o
  /// servidor nao devolver nenhum, deriva um determinístico do guid para o
  /// fluxo de polling nao ficar sem referencia.
  String _extractUploadId(dynamic body, String activityGuid) {
    if (body is Map) {
      final dynamic id = body['id'] ?? body['uploadId'];
      if (id != null) {
        final String s = id.toString();
        if (s.isNotEmpty) return s;
      }
    }
    return 'upload-$activityGuid';
  }

  @override
  Future<void> deleteRemote(String remoteId) async {
    final String? token = await _token?.call();
    final Response<dynamic> response;
    try {
      response = await _dio.delete<dynamic>(
        '$_baseUrl/activities/${Uri.encodeComponent(remoteId)}',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
          validateStatus: (int? s) => s != null,
        ),
      );
    } on DioException catch (e) {
      throw UploadException('falha de transporte: ${e.message}');
    }
    final int status = response.statusCode!;
    if (status == 204 || status == 200 || status == 404) return;
    if (status == 401) throw UnauthorizedUploadException();
    throw UploadException('status HTTP inesperado ao apagar: $status');
  }
}

/// Headers de metadados do upload (so os presentes).
Map<String, String> metadataHeaders(UploadMetadata? m) => {
      if (m?.activityType != null) 'x-activity-type': m!.activityType!,
      if (m?.startTimeMs != null) 'x-start-time': '${m!.startTimeMs}',
      if (m?.timerTimeMs != null) 'x-timer-time-ms': '${m!.timerTimeMs}',
      if (m?.distanceMeters != null) 'x-distance-meters': '${m!.distanceMeters}',
      if (m?.rpe != null) 'x-rpe': '${m!.rpe}',
      if (m?.mood != null) 'x-mood': m!.mood!,
    };
