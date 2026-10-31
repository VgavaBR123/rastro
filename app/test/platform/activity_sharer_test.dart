import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/platform/activity_sharer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('stravaestudo/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('envia o texto pelo canal stravaestudo/share', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    await const MethodChannelActivitySharer().shareText('oi');
    expect(calls.single.method, 'shareText');
    expect(calls.single.arguments, {'text': 'oi'});
  });

  test('compartilha arquivo generico com o tipo MIME (F07)', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    await const MethodChannelActivitySharer().shareFile('/c/share/export/a.zip', mimeType: 'application/zip');
    expect(calls.single.method, 'shareFile');
    expect(calls.single.arguments, {'path': '/c/share/export/a.zip', 'mimeType': 'application/zip'});
  });

  test('erro da plataforma sobe como PlatformException', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'share_failed');
    });

    await expectLater(
      const MethodChannelActivitySharer().shareText('oi'),
      throwsA(isA<PlatformException>()),
    );
  });
}
