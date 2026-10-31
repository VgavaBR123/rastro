// Abridor do link da localizacao: so https no host do backend; http e
// localhost so em build de debug; erro claro quando nao bate.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/safety/url_opener.dart';

void main() {
  late List<Uri> launched;
  LauncherUrlOpener opener({required String base, bool debug = false}) => LauncherUrlOpener(
    backendBaseUrl: base,
    debug: debug,
    launch: (u) async {
      launched.add(u);
      return true;
    },
  );

  setUp(() => launched = []);

  test('release: https no host do backend abre', () async {
    final r = await opener(base: 'https://api.rastro.app').open('https://api.rastro.app/s/abc');
    expect(r.opened, isTrue);
    expect(launched.single.toString(), 'https://api.rastro.app/s/abc');
  });

  test('release: outro host, http ou esquema estranho nao abre e explica', () async {
    final o = opener(base: 'https://api.rastro.app');
    for (final url in ['https://mal.example/s/abc', 'http://api.rastro.app/s/abc', 'javascript:alert(1)', 'http://localhost:8081/s/1']) {
      final r = await o.open(url);
      expect(r.opened, isFalse, reason: url);
      expect(r.error, contains('nao e do Rastro'), reason: url);
    }
    expect(launched, isEmpty);
  });

  test('debug: http e localhost tambem valem', () async {
    final o = opener(base: 'http://localhost:8081', debug: true);
    expect((await o.open('http://localhost:8081/s/1')).opened, isTrue);
    expect((await o.open('http://10.0.2.2:8081/s/1')).opened, isTrue);
    expect((await o.open('https://mal.example/s/1')).opened, isFalse);
  });

  test('navegador nao abriu: erro claro', () async {
    final o = LauncherUrlOpener(backendBaseUrl: 'https://api.rastro.app', debug: false, launch: (_) async => false);
    final r = await o.open('https://api.rastro.app/s/abc');
    expect(r.opened, isFalse);
    expect(r.error, contains('Nao deu para abrir'));
  });
}
