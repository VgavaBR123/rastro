// Implementacao de ActivityUploader com Dio (clean room,
// relatorios/06-sincronizacao.md).
//
// IMPORTANTE (limites do estudo, CLAUDE.md): este cliente NAO fala com a API
// privada do Strava. O baseUrl e um placeholder configuravel (ex.:
// 'https://example.invalid'); o endpoint '/uploads' e conceitual e descreve o
// padrao de upload assincrono descrito no relatorio 06, nao um endpoint real.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';

/// Envia o FIT via multipart POST para `$baseUrl/uploads` e extrai o uploadId
/// do corpo da resposta. Simples e defensivo: qualquer desvio vira
/// UploadException.
class DioActivityUploader implements ActivityUploader {
  final Dio _dio;
  final String _baseUrl;

  DioActivityUploader(Dio dio, String baseUrl)
      : _dio = dio,
        _baseUrl = baseUrl;

  @override
  Future<String> upload(Uint8List fitBytes, {required String activityGuid}) async {
    try {
      final FormData form = FormData.fromMap(<String, dynamic>{
        'activityGuid': activityGuid,
        'file': MultipartFile.fromBytes(
          fitBytes,
          filename: '$activityGuid.fit',
        ),
      });

      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/uploads',
        data: form,
      );

      final int? status = response.statusCode;
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
}
