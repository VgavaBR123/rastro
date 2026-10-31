// Verifica o FORMATO da requisicao HTTP do DioActivityUploader, que precisa
// casar com o contrato do nosso backend (POST /uploads, corpo
// application/octet-stream, guid no header x-activity-guid).
//
// Usa um HttpClientAdapter falso: nenhuma rede e tocada.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/sync/upload/activity_uploader.dart';
import 'package:strava_estudo_app/sync/upload/dio_activity_uploader.dart';

/// Captura a requisicao e devolve uma resposta canned.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Object body;

  RequestOptions? capturedOptions;
  Uint8List capturedBody = Uint8List(0);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedOptions = options;
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      capturedBody =
          Uint8List.fromList([for (final c in chunks) ...c]);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_FakeAdapter adapter) => Dio()..httpClientAdapter = adapter;

void main() {
  final fit = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

  test('envia o FIT como octet-stream com o guid no header', () async {
    final adapter = _FakeAdapter(
      statusCode: 201,
      body: {'uploadId': 'up_abc', 'status': 'received'},
    );
    final uploader =
        DioActivityUploader(_dioWith(adapter), 'https://example.invalid');

    final id = await uploader.upload(fit, activityGuid: 'guid-1');

    expect(id, 'up_abc');
    final opts = adapter.capturedOptions!;
    expect(opts.method, 'POST');
    expect(opts.uri.toString(), 'https://example.invalid/uploads');
    expect(
      opts.headers[Headers.contentTypeHeader],
      'application/octet-stream',
    );
    expect(opts.headers['x-activity-guid'], 'guid-1');
    expect(adapter.capturedBody, fit);
  });

  test('aceita o campo id quando o backend não manda uploadId', () async {
    final adapter = _FakeAdapter(statusCode: 200, body: {'id': 'up_xyz'});
    final uploader =
        DioActivityUploader(_dioWith(adapter), 'https://example.invalid');

    expect(await uploader.upload(fit, activityGuid: 'g'), 'up_xyz');
  });

  test('status fora de 2xx vira UploadException', () async {
    final adapter = _FakeAdapter(statusCode: 500, body: {'error': 'boom'});
    final uploader =
        DioActivityUploader(_dioWith(adapter), 'https://example.invalid');

    expect(
      () => uploader.upload(fit, activityGuid: 'g'),
      throwsA(isA<UploadException>()),
    );
  });

  test('falha de transporte vira UploadException', () async {
    final dio = Dio()
      ..httpClientAdapter = _ThrowingAdapter();
    final uploader = DioActivityUploader(dio, 'https://example.invalid');

    expect(
      () => uploader.upload(fit, activityGuid: 'g'),
      throwsA(isA<UploadException>()),
    );
  });
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'sem rede',
    );
  }

  @override
  void close({bool force = false}) {}
}
