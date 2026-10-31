// Widget test da tela de configuracoes: unidades e dialogo de peso.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/ui/settings_screen.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

Future<RecordingDatabase> abrir(
  WidgetTester tester, {
  bool metric = true,
  double? weightKg,
}) async {
  final db = RecordingDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  if (!metric) await db.saveSettings(useMetric: false);
  if (weightKg != null) await db.saveSettings(weightKg: Value(weightKg));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [recordingDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(theme: AppTheme.dark, home: const SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

String peso(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('weightValue'))).data!;

Future<void> editarPeso(WidgetTester tester, String texto) async {
  await tester.tap(find.byKey(const Key('weight')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('weightField')), texto);
  await tester.tap(find.byKey(const Key('weightSave')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('alternar unidades reflete na tela', (tester) async {
    await abrir(tester);

    expect(find.text('km, m, min/km'), findsOneWidget);

    expect(find.byKey(const Key('metric')), findsOneWidget);
    await tester.tap(find.byKey(const Key('metric_off')));
    await tester.pumpAndSettle();

    expect(find.text('mi, ft, min/mi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('metric_on')));
    await tester.pumpAndSettle();
    expect(find.text('km, m, min/km'), findsOneWidget);
  });

  testWidgets('peso nao informado por padrao', (tester) async {
    await abrir(tester);
    expect(find.text('Peso (para calorias)'), findsOneWidget);
    expect(peso(tester), 'Nao informado');
  });

  testWidgets('salva peso com virgula decimal', (tester) async {
    final db = await abrir(tester);

    await editarPeso(tester, '72,5');

    expect(find.byType(AlertDialog), findsNothing);
    expect(peso(tester), '72.5 kg');
    expect((await db.loadSettings()).weightKg, 72.5);
  });

  testWidgets('aceita ponto decimal e mostra o valor atual no campo', (
    tester,
  ) async {
    await abrir(tester, weightKg: 80);
    expect(peso(tester), '80 kg');

    await tester.tap(find.byKey(const Key('weight')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '80'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('weightField')), '81.2');
    await tester.tap(find.byKey(const Key('weightSave')));
    await tester.pumpAndSettle();

    expect(peso(tester), '81.2 kg');
  });

  testWidgets('campo vazio apaga o peso', (tester) async {
    final db = await abrir(tester, weightKg: 70);

    await editarPeso(tester, '');

    expect(peso(tester), 'Nao informado');
    expect((await db.loadSettings()).weightKg, isNull);
  });

  testWidgets('cancelar nao altera', (tester) async {
    final db = await abrir(tester, weightKg: 70);

    await tester.tap(find.byKey(const Key('weight')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('weightField')), '99');
    await tester.tap(find.byKey(const Key('weightCancel')));
    await tester.pumpAndSettle();

    expect(peso(tester), '70 kg');
    expect((await db.loadSettings()).weightKg, 70);
  });

  testWidgets('texto invalido mostra erro e mantem o dialogo', (tester) async {
    final db = await abrir(tester);

    await editarPeso(tester, 'abc');

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Informe um numero'), findsOneWidget);
    expect((await db.loadSettings()).weightKg, isNull);
  });

  testWidgets('fora da faixa mostra erro', (tester) async {
    final db = await abrir(tester);

    await editarPeso(tester, '10');

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Use um valor entre 20 e 400 kg'), findsOneWidget);
    expect((await db.loadSettings()).weightKg, isNull);
  });

  testWidgets('imperial: exibe em lb e converte para kg ao salvar', (
    tester,
  ) async {
    final db = await abrir(tester, metric: false, weightKg: 70);
    expect(peso(tester), '154.3 lb');

    await editarPeso(tester, '154');

    expect(peso(tester), '154 lb');
    expect((await db.loadSettings()).weightKg, closeTo(69.853, 0.001));
  });

  testWidgets('imperial: faixa de erro em lb', (tester) async {
    await abrir(tester, metric: false);

    await editarPeso(tester, '30');

    expect(find.text('Use um valor entre 45 e 881 lb'), findsOneWidget);
  });

  // INI-07 / VOC-10 (teste no iPhone, 30/10/2026): a secao Gravacao inteira
  // (titulo + Peso + valor) virava um unico botao de 200 pt.
  testWidgets('secao: cabecalho proprio e cada linha um elemento', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await abrir(tester);

    for (final titulo in ['Unidades', 'Gravacao']) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(titulo)),
        matchesSemantics(label: titulo, isHeader: true),
      );
    }

    final pesoNo = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^Peso \(para calorias\)')),
    );
    expect(pesoNo.label, 'Peso (para calorias)\nNao informado');
    expect(pesoNo.flagsCollection.isButton, isTrue);
    expect(pesoNo.rect.height, lessThan(100));

    final pausa = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^Pausa automatica')),
    );
    expect(pausa.label, isNot(contains('Gravacao')));
    expect(pausa.label, isNot(contains('Peso')));
    handle.dispose();
  });

  testWidgets('campo do dialogo de peso tem rotulo Peso', (tester) async {
    final handle = tester.ensureSemantics();
    await abrir(tester);
    await tester.tap(find.byKey(const Key('weight')));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(
        find.descendant(
          of: find.byKey(const Key('weightField')),
          matching: find.byType(EditableText),
        ),
      ),
      isSemantics(label: 'Peso', isTextField: true),
    );
    handle.dispose();
  });
}
