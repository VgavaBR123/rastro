// Rastro Seguro (F08) na tela de gravacao, contra o servidor falso do
// contrato: Iniciar cria a sessao com o guid; faixa com a chegada prevista;
// tick manda posicao; checagem abre o aviso grande (contagem, voz critica com
// o Narrador desligado, vibracao, leitor de tela) e Estou bem fecha; Estender;
// alerta na faixa; SOS segurando; Salvar e Descartar chamam arrived; sem rede
// no Iniciar avisa e grava sem Rastro Seguro; tema claro.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/closing/closing_service.dart';
import 'package:strava_estudo_app/narrator/narrator_providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/safety/safety_models.dart';
import 'package:strava_estudo_app/safety/safety_providers.dart';
import 'package:strava_estudo_app/safety/safety_session_controller.dart';
import 'package:strava_estudo_app/settings/app_settings.dart';
import 'package:strava_estudo_app/settings/settings_controller.dart';
import 'package:strava_estudo_app/ui/recording_screen.dart';
import 'package:strava_estudo_app/ui/safety/safety_setup.dart' show formatClock;
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

import '../fixtures/sample_route.dart';
import '../narrator/fake_voice_announcer.dart';
import '../recording/fakes.dart';
import '../safety/safety_harness.dart';

class _FixedSettings extends SettingsController {
  _FixedSettings(super.db, AppSettings s) {
    state = s;
  }
  @override
  Future<void> load() async {}
}

class _FakeClosing extends ClosingService {
  _FakeClosing(super.repo);
  @override
  Future<List<String>> phrasesFor(String guid, {required bool gentle, required bool metric}) async => const [];
}

void main() {
  late SafetyHarness h;
  late RecordingDatabase db;
  late FakeLocationSource source;
  late FakeVoiceAnnouncer voice;
  late String contactId;
  late ProviderContainer container;

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> hold(WidgetTester tester, Finder f) async {
    final g = await tester.startGesture(tester.getCenter(f));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump();
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pump();
    await tester.tap(find.byKey(key));
    await tester.pump();
  }

  Map<String, dynamic> session() => h.server.sessions.single;

  Future<void> pump(WidgetTester tester, {ThemeData? theme, bool withPlan = true, bool offline = false}) async {
    h = SafetyHarness();
    contactId = h.server.linkAccepted(h.ana, h.bia);
    db = RecordingDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    source = FakeLocationSource();
    voice = FakeVoiceAnnouncer();
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final contact = TrustedContact(
      id: contactId,
      otherUserId: h.bia.id,
      displayName: 'Bia',
      email: h.bia.email,
      status: ContactStatus.accepted,
      createdAt: 0,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...h.overrides(signedInAs: h.ana),
          locationSourceProvider.overrideWithValue(source),
          recordingDatabaseProvider.overrideWithValue(db),
          settingsProvider.overrideWith((ref) => _FixedSettings(db, const AppSettings())),
          closingServiceProvider.overrideWith((ref) => _FakeClosing(ref.watch(recordingRepositoryProvider))),
          voiceAnnouncerProvider.overrideWithValue(voice),
          if (withPlan)
            safetyPlanProvider.overrideWith((ref) => SafetyPlan(contacts: [contact], minutes: 30)),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.dark,
          home: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecordingScreen(activityType: ActivityType.run)),
                  ),
                  child: const Text('abrir'),
                ),
              );
            },
          ),
        ),
      ),
    );
    h.server.offline = offline;
    await tester.tap(find.text('abrir'));
    await drain(tester);
  }

  Future<void> positionTick(WidgetTester tester) async {
    h.positionTicker.tick();
    await drain(tester);
  }

  testWidgets('Iniciar cria a sessao; faixa com a chegada; tick manda a posicao', (tester) async {
    await pump(tester);
    final guid = container.read(recordingControllerProvider.notifier).activityGuid;
    expect(session()['activityGuid'], guid);
    expect(session()['contactIds'], [contactId]);
    expect(container.read(safetyPlanProvider), isNull, reason: 'escolha usada uma vez');
    final eta = session()['etaMs'] as int;
    expect(
      tester.widget<Text>(find.byKey(const Key('safety_banner_text'))).data,
      'Rastro Seguro ativo - chegada prevista ${formatClock(eta)}',
    );

    for (final p in sampleRoute().take(2)) {
      source.add(p);
    }
    await drain(tester);
    await positionTick(tester);
    final last = (session()['positions'] as List).last as Map;
    expect(last['lat'], isNotNull);
    expect(last['moving'], isTrue);
  });

  testWidgets('checagem: aviso grande com contagem, voz e vibracao; Estou bem fecha', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    h.server.startCheck(session()['id'] as String, reason: 'stopped', deadlineMs: h.nowMs + 90000);
    await positionTick(tester);
    expect(find.byKey(const Key('safety_check')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('safety_check_countdown'))).data, '1:30');
    h.nowMs += 31000;
    h.countdownTicker.tick();
    await drain(tester);
    expect(tester.widget<Text>(find.byKey(const Key('safety_check_countdown'))).data, '0:59');
    // Narrador desligado nas configuracoes e mesmo assim falou.
    expect(voice.spoken, contains(kSafetyCheckPhrase));
    expect(h.haptics.alerts, 1);
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^Esta tudo bem'))),
      containsSemantics(isLiveRegion: true),
    );
    final okSize = tester.getSize(find.byKey(const Key('safety_check_ok')));
    expect(okSize.height, greaterThanOrEqualTo(44));

    await tester.tap(find.byKey(const Key('safety_check_ok')));
    await drain(tester);
    expect(find.byKey(const Key('safety_check')), findsNothing);
    expect(h.server.requestsTo('POST', '/ok'), hasLength(1));
    semantics.dispose();
  });

  testWidgets('Estender 15 min no aviso e +30 na faixa mudam o horario', (tester) async {
    await pump(tester);
    final eta = session()['etaMs'] as int;
    h.server.startCheck(session()['id'] as String);
    await positionTick(tester);
    await tester.tap(find.byKey(const Key('safety_check_extend')));
    await drain(tester);
    expect(find.byKey(const Key('safety_check')), findsNothing);
    expect(session()['etaMs'], eta + 15 * 60000);
    await tapVisible(tester, const Key('safety_extend_30'));
    await drain(tester);
    expect(session()['etaMs'], eta + 45 * 60000);
    expect(
      tester.widget<Text>(find.byKey(const Key('safety_banner_text'))).data,
      contains(formatClock(eta + 45 * 60000)),
    );
  });

  testWidgets('alertado: faixa diz que os contatos foram avisados e Estou bem avisa', (tester) async {
    await pump(tester, theme: AppTheme.light);
    final id = session()['id'] as String;
    h.server.startCheck(id);
    h.server.alert(id);
    await positionTick(tester);
    expect(tester.widget<Text>(find.byKey(const Key('safety_banner_text'))).data, 'Seus contatos foram avisados');
    await tapVisible(tester, const Key('safety_banner_ok'));
    await drain(tester);
    expect(h.server.notifications.where((n) => n['type'] == 'safety_all_clear'), hasLength(1));
  });

  testWidgets('SOS so vai segurando; toque rapido nao manda', (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.byKey(const Key('safety_sos')));
    await tester.tap(find.byKey(const Key('safety_sos')));
    await drain(tester);
    expect(h.server.requestsTo('POST', '/sos'), isEmpty);
    await hold(tester, find.byKey(const Key('safety_sos')));
    await drain(tester);
    expect(h.server.requestsTo('POST', '/sos'), hasLength(1));
    expect(h.server.notifications.where((n) => n['type'] == 'safety_sos'), hasLength(1));
    expect(find.byKey(const Key('safety_banner_message')), findsOneWidget);
  });

  testWidgets('Cheguei pede confirmacao e encerra so o Rastro Seguro', (tester) async {
    await pump(tester);
    await tapVisible(tester, const Key('safety_arrived'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('safety_arrived_confirm')));
    await drain(tester);
    expect(session()['status'], 'ended');
    expect(find.byKey(const Key('safety_banner')), findsNothing);
    expect(container.read(recordingControllerProvider).isActive, isTrue);
  });

  testWidgets('Salvar a gravacao chama arrived', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('pause')));
    await drain(tester);
    await hold(tester, find.byKey(const Key('stop')));
    await tapVisible(tester, const Key('save_activity'));
    await drain(tester);
    expect(session()['status'], 'ended');
  });

  testWidgets('Descartar a gravacao chama arrived', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('pause')));
    await drain(tester);
    await hold(tester, find.byKey(const Key('stop')));
    await tapVisible(tester, const Key('discard_activity'));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const Key('discard_confirm'));
    if (confirm.evaluate().isNotEmpty) await tester.tap(confirm);
    await drain(tester);
    expect(session()['status'], 'ended');
  });

  testWidgets('sem rede no Iniciar: avisa e grava sem Rastro Seguro', (tester) async {
    await pump(tester, offline: true);
    expect(find.byKey(const Key('safety_begin_notice')), findsWidgets);
    expect(find.textContaining('Sem rede: gravando sem Rastro Seguro'), findsWidgets);
    expect(find.byKey(const Key('safety_banner')), findsNothing);
    expect(container.read(recordingControllerProvider).isActive, isTrue);
    expect(find.byKey(const Key('pause')), findsOneWidget);
  });

  testWidgets('sem escolha no Gravar: nenhuma chamada e sem faixa', (tester) async {
    await pump(tester, withPlan: false);
    expect(h.server.requests.where((r) => !r.path.startsWith('/me')), isEmpty);
    expect(find.byKey(const Key('safety_banner')), findsNothing);
  });
}
