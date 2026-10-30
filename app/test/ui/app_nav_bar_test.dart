// AppNavBar: fora de um iPhone com iOS 26+ fica a barra Flutter (com as Keys
// que os testes e o integration_test usam). No iOS ela passa pelo
// NativeGlassNavBar, que no host de teste cai no fallback.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';
import 'package:strava_estudo_app/ui/components/app_nav_bar.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

Future<List<int>> _pump(WidgetTester tester, {int? currentIndex = 0}) async {
  final taps = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: AppNavBar(
            currentIndex: currentIndex,
            onTabSelected: taps.add,
            onRecord: () => taps.add(-1),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return taps;
}

void _expectFlutterBar() {
  for (final k in [
    'nav_home',
    'nav_history',
    'nav_stats',
    'nav_profile',
    'nav_record',
  ]) {
    expect(find.byKey(Key(k)), findsOneWidget, reason: k);
  }
}

void main() {
  testWidgets('no Android mostra a barra Flutter, sem o widget nativo', (
    tester,
  ) async {
    final taps = await _pump(tester);
    expect(find.byType(NativeGlassNavBar), findsNothing);
    _expectFlutterBar();

    await tester.tap(find.byKey(const Key('nav_stats')));
    await tester.tap(find.byKey(const Key('nav_record')));
    expect(taps, [2, -1]);
    expect(AppNavBar.nativeActive.value, isFalse);
  });

  testWidgets('no iOS sem suporte ao Liquid Glass cai na barra Flutter', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final taps = await _pump(tester, currentIndex: null);
      expect(find.byType(NativeGlassNavBar), findsOneWidget);
      _expectFlutterBar();
      await tester.tap(find.byKey(const Key('nav_home')));
      expect(taps, [0]);
      expect(AppNavBar.nativeActive.value, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('reservedHeight segue o modo da barra', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
        child: NavBarModeScope(
          child: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(
      AppNavBar.reservedHeight(ctx),
      AppNavBar.height + AppNavBar.bottomGap + 34 + 12,
    );

    AppNavBar.nativeActive.value = true;
    addTearDown(() => AppNavBar.nativeActive.value = false);
    await tester.pump();
    expect(AppNavBar.reservedHeight(ctx), AppNavBar.nativeHeight + 34 + 12);
  });
}
