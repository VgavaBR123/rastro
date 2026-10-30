// Teste de ponta a ponta NO APARELHO dos Capitulos mensais com marcos (F05).
//
// O relogio e o do aparelho: o historico e semeado no mes anterior ao atual,
// que e o mes fechado do capitulo. Nao precisa de backend (a F05 e so local).
//
// 1) Cartao do Inicio -> capitulo do mes passado, pagina a pagina, ate a
//    previa da imagem; nada de titulo, descricao ou horario; o cartao some
//    depois de aberto e o mes aparece na lista das Estatisticas.
// 2) Modo Gentil: o mesmo capitulo, aberto pela lista, sem pace em pagina
//    nenhuma.
//
// Execucao:
//   flutter test integration_test/capitulos_test.dart -d <device>
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/app/router.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';
import 'package:strava_estudo_app/recording/service/recording_service.dart';

const String _titulo = 'Treino perto de casa';
const String _descricao = 'Saindo da Rua das Flores';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final hoje = DateTime.now();
  final mesPassado = DateTime(hoje.year, hoje.month - 1);
  final chaveMes = '${mesPassado.year}${mesPassado.month.toString().padLeft(2, '0')}';

  Future<RecordingDatabase> abrir(WidgetTester tester, {bool gentil = false}) async {
    final db = RecordingDatabase();
    addTearDown(db.close);
    await db.delete(db.waypoints).go();
    await db.delete(db.activities).go();
    // "Ultimo capitulo visto" so avanca: zera a linha de configuracoes.
    await db.delete(db.settingsRows).go();
    await db.saveSettings(reliabilityChecklistSeen: true, gentleMode: gentil);

    var n = 0;
    Future<void> semear(ActivityType tipo, int dia, double km, int min, {int hora = 7}) =>
        db.upsertActivity(
          ActivitiesCompanion.insert(
            guid: 'cap-${n++}',
            activityType: tipo,
            startTimestampMs:
                DateTime(mesPassado.year, mesPassado.month, dia, hora).millisecondsSinceEpoch,
            timerTimeMs: Value(min * 60000),
            distanceMeters: Value(km * 1000),
            isFinished: const Value(true),
            syncState: SyncState.pending,
            title: const Value(_titulo),
            description: const Value(_descricao),
          ),
        );
    // Mes passado: primeira corrida de 5 km, primeiros 10 km e um pedal de 25 km.
    await semear(ActivityType.run, 4, 5.1, 31, hora: 6);
    await semear(ActivityType.run, 12, 10.2, 58);
    await semear(ActivityType.ride, 20, 25, 70, hora: 17);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingDatabaseProvider.overrideWithValue(db),
          sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
          recordingServiceProvider.overrideWithValue(const NoopRecordingService()),
        ],
        child: MaterialApp.router(routerConfig: buildAppRouter()),
      ),
    );
    await tester.pumpAndSettle();
    return db;
  }

  Future<void> esperar(WidgetTester tester, Finder f) async {
    for (var i = 0; i < 40 && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();
  }

  /// Rola a lista vertical ate o item existir (ela e preguicosa) e o
  /// centraliza: a aba Estatisticas tem mais de um rolavel (o grafico), e a
  /// barra de abas cobre o rodape.
  Future<void> centralizar(WidgetTester tester, Finder item) async {
    await tester.scrollUntilVisible(
      item,
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.runAsync(
      () => Scrollable.ensureVisible(tester.element(item), alignment: 0.5),
    );
    await tester.pumpAndSettle();
  }

  List<String> textosNaTela() => find.byType(Text).evaluate().map((e) {
        final t = e.widget as Text;
        return t.data ?? t.textSpan?.toPlainText() ?? '';
      }).toList();

  /// Percorre todas as paginas ate a ultima e devolve os textos vistos.
  Future<List<String>> percorrer(WidgetTester tester) async {
    final vistos = <String>[];
    for (var i = 0; i < 10; i++) {
      vistos.addAll(textosNaTela());
      if (find.byKey(const Key('chapter_share')).evaluate().isNotEmpty) break;
      await tester.tap(find.byKey(const Key('chapter_next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('chapter_share')), findsOneWidget,
        reason: 'a ultima pagina tem o Compartilhar');
    return vistos;
  }

  void semDadosPessoais(List<String> textos, String onde) {
    for (final t in textos) {
      expect(t, isNot(contains(_titulo)), reason: '$onde mostra o titulo');
      expect(t, isNot(contains(_descricao)), reason: '$onde mostra a descricao');
      expect(t, isNot(matches(RegExp(r'\b\d{1,2}:\d{2}\s*(h|am|pm)\b'))),
          reason: '$onde mostra horario: "$t"');
    }
  }

  testWidgets('cartao do Inicio abre o capitulo do mes passado e a previa da imagem', (
    tester,
  ) async {
    await abrir(tester);

    final cartao = find.byKey(const Key('home_chapter_card'));
    await esperar(tester, cartao);
    expect(cartao, findsOneWidget, reason: 'mes $chaveMes fechado com treinos');
    await tester.ensureVisible(find.byKey(const Key('home_chapter_open')));
    await tester.tap(find.byKey(const Key('home_chapter_open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chapter_screen')), findsOneWidget);
    expect(find.byKey(const Key('chapter_page_opening')), findsOneWidget);
    expect(find.byKey(const Key('chapter_prev')), findsNothing);

    final textos = await percorrer(tester);
    debugPrint('[e2e-f05] paginas: ${textos.where((t) => t.trim().isNotEmpty).join(' | ')}');
    semDadosPessoais(textos, 'capitulo');
    // 3 treinos, mais de um esporte e marcos de primeira vez no mes.
    expect(textos.any((t) => t.contains('3')), isTrue);
    expect(textos.any((t) => t.toLowerCase().contains('primeir')), isTrue,
        reason: 'marcos de primeira vez');

    // Voltar recua uma pagina.
    await tester.tap(find.byKey(const Key('chapter_prev')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chapter_share')), findsNothing);
    await tester.tap(find.byKey(const Key('chapter_next')));
    await tester.pumpAndSettle();

    // Previa da imagem (o botao de enviar abriria a folha do sistema: fica de fora).
    await tester.tap(find.byKey(const Key('chapter_share')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chapter_share_screen')), findsOneWidget);
    expect(find.byKey(const Key('chapter_share_card')), findsOneWidget);
    expect(find.byKey(const Key('chapter_share_brand')), findsOneWidget);
    expect(find.byKey(const Key('chapter_share_milestone')), findsWidgets);
    final imagem = textosNaTela();
    debugPrint('[e2e-f05] imagem: ${imagem.where((t) => t.trim().isNotEmpty).join(' | ')}');
    semDadosPessoais(imagem, 'imagem');
    for (final t in imagem) {
      expect(t, isNot(contains('/km')), reason: 'a imagem nunca mostra pace');
    }

    await tester.tap(find.byKey(const Key('chapter_share_back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chapter_close')));
    await tester.pumpAndSettle();

    // Visto: o cartao some; o mes fica na lista das Estatisticas.
    expect(find.byKey(const Key('home_chapter_card')), findsNothing);
    await tester.tap(find.byKey(const Key('nav_stats')));
    await tester.pumpAndSettle();
    final item = find.byKey(Key('chapter_item_month_$chaveMes'));
    await centralizar(tester, item);
    expect(item, findsOneWidget);
    expect(find.byKey(const Key('stats_streak')), findsOneWidget);
  });

  testWidgets('Modo Gentil: capitulo aberto pela lista sem pace', (tester) async {
    await abrir(tester, gentil: true);
    await tester.tap(find.byKey(const Key('nav_stats')));
    await tester.pumpAndSettle();
    final item = find.byKey(Key('chapter_item_month_$chaveMes'));
    await centralizar(tester, item);
    await tester.tap(item);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chapter_screen')), findsOneWidget);

    final textos = await percorrer(tester);
    semDadosPessoais(textos, 'capitulo gentil');
    for (final t in textos) {
      final l = t.toLowerCase();
      for (final w in ['/km', '/mi', 'pace', 'km/h', 'rápid', 'rapid']) {
        expect(l, isNot(contains(w)), reason: 'Modo Gentil mostra "$t"');
      }
    }
  });
}
