// Configuracao do Rastro Seguro por variaveis de ambiente e o filtro de
// segredos do log de requisicoes.
import 'package:strava_estudo_backend/src/safety/safety_api.dart';
import 'package:strava_estudo_backend/src/safety/safety_service.dart';
import 'package:test/test.dart';

void main() {
  test('padroes do contrato sem variaveis', () {
    final c = SafetyConfig.fromEnv(const {});
    expect(c.tickMs, 15000);
    expect(c.silenceMs, 5 * 60 * 1000);
    expect(c.stopMs, 10 * 60 * 1000);
    expect(c.checkMs, 2 * 60 * 1000);
    expect(c.etaMinMs, 5 * 60 * 1000);
    expect(c.publicBaseUrl, 'http://localhost:8081');
  });

  test('le as variaveis; invalidas ficam no padrao', () {
    final c = SafetyConfig.fromEnv(const {
      'SAFETY_TICK_MS': '1000',
      'SAFETY_SILENCE_MS': '20000',
      'SAFETY_STOP_MS': ' 30000 ',
      'SAFETY_CHECK_MS': '15000',
      'SAFETY_ETA_MIN_MS': '60000',
      'PUBLIC_BASE_URL': 'https://rastro.exemplo',
    });
    expect(c.tickMs, 1000);
    expect(c.silenceMs, 20000);
    expect(c.stopMs, 30000);
    expect(c.checkMs, 15000);
    expect(c.etaMinMs, 60000);
    expect(c.publicBaseUrl, 'https://rastro.exemplo');
    final ruim = SafetyConfig.fromEnv(
        const {'SAFETY_TICK_MS': 'abc', 'SAFETY_CHECK_MS': '0'});
    expect(ruim.tickMs, 15000);
    expect(ruim.checkMs, 120000);
  });

  test('log de requisicoes nao mostra token do link nem de push', () {
    expect(
        ocultarSegredosDoCaminho(
            '2026-10-30 GET [200] /s/AbC_-123xyz.json 1ms'),
        '2026-10-30 GET [200] /s/<token> 1ms');
    expect(ocultarSegredosDoCaminho('DELETE [204] /push/tokens/tok%3Aabc'),
        'DELETE [204] /push/tokens/<token>');
    expect(ocultarSegredosDoCaminho('GET [200] /safety/sessions/ss_1'),
        'GET [200] /safety/sessions/ss_1');
  });
}
