// VOC-01 e GRA-07 (teste no iPhone, 30/10/2026): tocar fora do campo ou rolar
// a tela fecha o teclado.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/ui/auth_screen.dart';
import 'package:strava_estudo_app/ui/components/keyboard_dismiss.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

Future<void> pumpAuth(WidgetTester tester) async {
  final db = RecordingDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recordingDatabaseProvider.overrideWithValue(db),
        sessionStoreProvider.overrideWithValue(InMemorySessionStore()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => KeyboardDismissOnTap(child: child!),
        home: const AuthScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool emailFocused(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('auth_email')),
        matching: find.byType(EditableText),
      ),
    )
    .focusNode
    .hasFocus;

void main() {
  testWidgets('tocar fora do campo fecha o teclado', (tester) async {
    await pumpAuth(tester);
    await tester.tap(find.byKey(const Key('auth_email')));
    await tester.pump();
    expect(emailFocused(tester), isTrue);

    await tester.tapAt(const Offset(400, 20)); // topo, longe dos campos
    await tester.pump();
    expect(emailFocused(tester), isFalse);
  });

  testWidgets('tocar em outro campo passa o foco para ele', (tester) async {
    await pumpAuth(tester);
    await tester.tap(find.byKey(const Key('auth_email')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('auth_password')));
    await tester.pump();
    expect(emailFocused(tester), isFalse);
    final pass = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('auth_password')),
        matching: find.byType(EditableText),
      ),
    );
    expect(pass.focusNode.hasFocus, isTrue);
  });

  testWidgets('arrastar a tela fecha o teclado', (tester) async {
    await pumpAuth(tester);
    await tester.tap(find.byKey(const Key('auth_email')));
    await tester.pump();
    final scroll = find.byType(SingleChildScrollView).first;
    expect(
      tester.widget<SingleChildScrollView>(scroll).keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );
  });
}
