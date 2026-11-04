import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/ui/splash/animated_splash.dart';
import 'package:strava_estudo_app/ui/theme/app_theme.dart';

Widget _app({bool reduceMotion = false, VoidCallback? onTapChild}) {
  return MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: AnimatedSplash(child: child!),
    ),
    home: Scaffold(
      body: Center(
        child: TextButton(onPressed: onTapChild, child: const Text('conteudo')),
      ),
    ),
  );
}

void main() {
  group('splashFrameAt', () {
    test('comeca com o ponto acima da logo e nada desenhado', () {
      final f = splashFrameAt(0);
      expect(f.drawProgress, 0);
      expect(f.dot.dy, lessThan(SplashLogo.pathStart.dy));
      expect(f.dot.dx, SplashLogo.pathStart.dx);
    });

    test('termina na logo exata, sem deformacao nem fagulhas', () {
      final f = splashFrameAt(1);
      expect(f.drawProgress, 1);
      expect(f.dot, SplashLogo.dotCenter);
      expect(f.dotStretch, 1);
      expect(f.logoScale, 1);
      expect(f.sparks, isNull);
      expect(f.wordmark, 1);
    });

    test('o traco nunca recua', () {
      var last = 0.0;
      for (var i = 0; i <= 200; i++) {
        final p = splashFrameAt(i / 200).drawProgress;
        expect(p, greaterThanOrEqualTo(last));
        last = p;
      }
    });

    test('o ponto nao teleporta entre frames de 60 fps', () {
      const step = 1 / 120; // 2 s a 60 fps
      var last = splashFrameAt(0).dot;
      for (var t = step; t <= 1; t += step) {
        final dot = splashFrameAt(t).dot;
        // A queda livre e rapida de proposito; o resto, inclusive as emendas
        // entre as fases, tem que ser bem mais suave.
        final limit = t <= SplashTimeline.dropEnd ? 180 : 110;
        expect((dot - last).distance, lessThan(limit), reason: 't=$t');
        last = dot;
      }
    });

    test('o salto sai do fim da perna e sobe antes de aterrissar', () {
      const mid = (SplashTimeline.drawEnd + SplashTimeline.jumpEnd) / 2;
      final f = splashFrameAt(mid);
      expect(f.drawProgress, 1);
      expect(f.dot.dx, greaterThan(SplashLogo.pathEnd.dx));
      expect(f.dot.dx, lessThan(SplashLogo.dotCenter.dx));
      expect(f.dot.dy, lessThan(SplashLogo.dotCenter.dy));
    });

    test('as fagulhas so existem logo apos a aterrissagem', () {
      expect(splashFrameAt(SplashTimeline.jumpEnd - 0.01).sparks, isNull);
      expect(splashFrameAt(SplashTimeline.jumpEnd + 0.05).sparks, isNotNull);
    });

    test('valores fora do intervalo sao limitados', () {
      expect(splashFrameAt(-1).drawProgress, 0);
      expect(splashFrameAt(2).dot, SplashLogo.dotCenter);
    });
  });

  group('AnimatedSplash', () {
    testWidgets('cobre o app e some sozinha ao terminar', (tester) async {
      await tester.pumpWidget(_app());
      expect(find.byKey(AnimatedSplash.overlayKey), findsOneWidget);

      await tester.pump(SplashTimeline.total);
      expect(find.byKey(AnimatedSplash.overlayKey), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(SplashTimeline.exit);
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(AnimatedSplash.overlayKey), findsNothing);
      expect(find.text('conteudo'), findsOneWidget);
    });

    testWidgets('um toque pula direto para o app', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_app(onTapChild: () => tapped++));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(AnimatedSplash.overlayKey));
      await tester.pump();
      await tester.pump(SplashTimeline.exit);
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(AnimatedSplash.overlayKey), findsNothing);

      await tester.tap(find.text('conteudo'));
      expect(tapped, 1);
    });

    testWidgets('com reduzir movimento mostra a logo pronta, sem animar', (
      tester,
    ) async {
      await tester.pumpWidget(_app(reduceMotion: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byKey(AnimatedSplash.overlayKey), findsOneWidget);

      await tester.pump(AnimatedSplash.reducedMotionHold);
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(AnimatedSplash.overlayKey), findsNothing);
    });

    testWidgets('anuncia o nome do app para leitores de tela', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.bySemanticsLabel('Rastro'), findsOneWidget);
      handle.dispose();
      await tester.pumpAndSettle();
    });

    test('a logo usa as coordenadas do SVG aprovado', () {
      expect(SplashLogo.pathStart, const Offset(286, 738));
      expect(SplashLogo.pathEnd, const Offset(606, 736));
      expect(SplashLogo.dotCenter, const Offset(744, 736));
      expect(SplashLogo.strokeWidth, 100);
      expect(SplashLogo.dotRadius, 50);
    });
  });
}
