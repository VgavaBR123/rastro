// Splash animada: o ponto da logo cai, desenha o "R" como um trajeto, salta
// para o seu lugar e o "R" responde. Um toque pula; com "reduzir movimento"
// a logo aparece pronta. Desenho aprovado em design/logo/01-dobra.svg.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric, lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Geometria da logo, no espaco 1024x1024 do SVG.
abstract final class SplashLogo {
  static const double size = 1024;
  static const double strokeWidth = 100;
  static const double dotRadius = 50;
  static const Offset pathStart = Offset(286, 738);
  static const Offset pathEnd = Offset(606, 736);
  static const Offset dotCenter = Offset(744, 736);
  static const Offset center = Offset(size / 2, size / 2);

  static final Path path = Path()
    ..moveTo(pathStart.dx, pathStart.dy)
    ..lineTo(286, 426)
    ..cubicTo(286, 324, 352, 270, 450, 270)
    ..lineTo(608, 270)
    ..cubicTo(700, 270, 744, 322, 744, 390)
    ..cubicTo(744, 466, 692, 510, 608, 510)
    ..lineTo(486, 510)
    ..cubicTo(438, 510, 424, 554, 458, 588)
    ..lineTo(pathEnd.dx, pathEnd.dy);

  static final PathMetric metric = path.computeMetrics().first;
}

/// Linha do tempo, em fracoes de [total].
abstract final class SplashTimeline {
  static const Duration total = Duration(milliseconds: 2000);
  static const Duration exit = Duration(milliseconds: 360);

  static const double dropEnd = 0.20;
  static const double drawEnd = 0.58;
  static const double jumpEnd = 0.74;
  static const double sparksEnd = 0.94;
}

/// Estado de um instante da animacao; funcao pura de t, para poder testar.
@immutable
class SplashFrame {
  /// Fracao ja desenhada do "R".
  final double drawProgress;
  final Offset dot;

  /// Deformacao do ponto ao longo de [dotAngle]: >1 estica, <1 achata.
  final double dotStretch;
  final double dotAngle;
  final double logoScale;

  /// Progresso das fagulhas; nulo quando nao ha nenhuma.
  final double? sparks;
  final double wordmark;

  const SplashFrame({
    required this.drawProgress,
    required this.dot,
    required this.dotStretch,
    required this.dotAngle,
    required this.logoScale,
    required this.sparks,
    required this.wordmark,
  });
}

const double _dropHeight = 900;
const double _jumpHeight = 260;
const double _groundContact = 30;

double _unit(double t, double begin, double end) =>
    ((t - begin) / (end - begin)).clamp(0.0, 1.0);

Offset _dotAt(double t) {
  if (t < SplashTimeline.dropEnd) {
    final u = Curves.bounceOut.transform(_unit(t, 0, SplashTimeline.dropEnd));
    return Offset(
      SplashLogo.pathStart.dx,
      SplashLogo.pathStart.dy - _dropHeight * (1 - u),
    );
  }
  if (t < SplashTimeline.drawEnd) {
    final metric = SplashLogo.metric;
    return metric
        .getTangentForOffset(metric.length * _drawProgress(t))!
        .position;
  }
  if (t < SplashTimeline.jumpEnd) {
    final u = _unit(t, SplashTimeline.drawEnd, SplashTimeline.jumpEnd);
    final base = Offset.lerp(SplashLogo.pathEnd, SplashLogo.dotCenter, u)!;
    return base.translate(0, -_jumpHeight * 4 * u * (1 - u));
  }
  return SplashLogo.dotCenter;
}

double _drawProgress(double t) => Curves.easeInOutCubic.transform(
  _unit(t, SplashTimeline.dropEnd, SplashTimeline.drawEnd),
);

/// Amortece [wave] a partir de [amount] ate morrer em u = 1.
double _settle(double u, double amount, double wave) =>
    u >= 1 ? 0 : amount * math.exp(-5 * u) * wave;

SplashFrame splashFrameAt(double rawT) {
  final t = rawT.clamp(0.0, 1.0);
  final dot = _dotAt(t);

  var stretch = 1.0;
  var angle = math.pi / 2;
  if (t < SplashTimeline.jumpEnd) {
    // O ponto estica na direcao em que corre, proporcional a velocidade.
    final delta = _dotAt(math.min(t + 0.004, 1)) - dot;
    if (delta.distance > 0.5) angle = delta.direction;
    stretch = 1 + math.min(delta.distance / 70, 0.4);
    if (t < SplashTimeline.dropEnd) {
      // Achata ao tocar o chao em cada quique.
      final height = SplashLogo.pathStart.dy - dot.dy;
      if (height < _groundContact) {
        angle = math.pi / 2;
        stretch = 0.68 + 0.32 * height / _groundContact;
      }
    }
  } else if (t < 1) {
    final u = _unit(t, SplashTimeline.jumpEnd, 1);
    stretch = 1 - _settle(u, 0.42, math.cos(u * math.pi * 6));
  }

  var scale = 1.0;
  if (t >= SplashTimeline.jumpEnd && t < 1) {
    final u = _unit(t, SplashTimeline.jumpEnd, 1);
    scale = 1 + _settle(u, 0.16, math.sin(u * math.pi * 5));
  }

  final inSparks = t >= SplashTimeline.jumpEnd && t < SplashTimeline.sparksEnd;

  return SplashFrame(
    drawProgress: t < SplashTimeline.dropEnd ? 0 : _drawProgress(t),
    dot: dot,
    dotStretch: stretch,
    dotAngle: angle,
    logoScale: scale,
    sparks: inSparks
        ? _unit(t, SplashTimeline.jumpEnd, SplashTimeline.sparksEnd)
        : null,
    wordmark: Curves.easeOutBack.transform(
      _unit(t, SplashTimeline.jumpEnd + 0.02, SplashTimeline.sparksEnd),
    ),
  );
}

/// Cobre [child] com a splash ate a animacao acabar. O app ja inicia por baixo.
class AnimatedSplash extends StatefulWidget {
  static const Key overlayKey = Key('animated-splash');

  /// Quanto a logo pronta fica na tela com "reduzir movimento".
  static const Duration reducedMotionHold = Duration(milliseconds: 600);

  final Widget child;

  const AnimatedSplash({super.key, required this.child});

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: SplashTimeline.total,
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: SplashTimeline.exit,
  );
  Timer? _hold;
  bool _started = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      _hold = Timer(AnimatedSplash.reducedMotionHold, _finish);
    } else {
      _intro.addStatusListener(_onIntroStatus);
      _exit.addStatusListener(_onExitStatus);
      _intro.forward();
    }
  }

  void _onIntroStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _exit.forward();
  }

  void _onExitStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish();
  }

  void _skip() {
    if (_hold != null) {
      _finish();
    } else {
      _intro.value = 1; // o listener de status dispara a saida
    }
  }

  void _finish() {
    _hold?.cancel();
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _hold?.cancel();
    _intro.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_done)
          _SplashOverlay(
            key: AnimatedSplash.overlayKey,
            intro: _intro,
            exit: _exit,
            onTap: _skip,
          ),
      ],
    );
  }
}

class _SplashOverlay extends StatelessWidget {
  final Animation<double> intro;
  final Animation<double> exit;
  final VoidCallback onTap;

  const _SplashOverlay({
    super.key,
    required this.intro,
    required this.exit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([intro, exit]),
      builder: (context, _) {
        final leaving = Curves.easeInCubic.transform(exit.value);
        final frame = splashFrameAt(intro.value);
        return IgnorePointer(
          ignoring: exit.value > 0,
          child: Opacity(
            opacity: 1 - leaving,
            child: Semantics(
              container: true,
              label: 'Rastro',
              child: BlockSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: ColoredBox(
                    color: colors.bg,
                    child: ExcludeSemantics(
                      child: Center(
                        child: Transform.scale(
                          scale: 1 + 0.14 * leaving,
                          child: _SplashContent(frame: frame, colors: colors),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SplashContent extends StatelessWidget {
  final SplashFrame frame;
  final AppColors colors;

  const _SplashContent({required this.frame, required this.colors});

  @override
  Widget build(BuildContext context) {
    final side = MediaQuery.sizeOf(context).shortestSide * 0.56;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            size: Size.square(side),
            painter: _SplashPainter(frame: frame, colors: colors),
          ),
        ),
        Opacity(
          opacity: frame.wordmark.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, lerpDouble(22, 0, frame.wordmark)!),
            child: Text(
              'Rastro',
              style: AppText.screenTitle.copyWith(
                color: colors.text,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashPainter extends CustomPainter {
  final SplashFrame frame;
  final AppColors colors;

  const _SplashPainter({required this.frame, required this.colors});

  static const int _sparkCount = 7;
  static const double _sparkReach = 340;
  static const double _sparkRadius = 30;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / SplashLogo.size;
    canvas.save();
    canvas.scale(unit);
    _scaleAround(canvas, SplashLogo.center, frame.logoScale);

    if (frame.drawProgress > 0) {
      final metric = SplashLogo.metric;
      canvas.drawPath(
        metric.extractPath(0, metric.length * frame.drawProgress),
        Paint()
          ..color = colors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = SplashLogo.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (frame.sparks case final progress?) _paintSparks(canvas, progress);

    // Elipse de area constante: esticar de um lado afina do outro.
    canvas.save();
    canvas.translate(frame.dot.dx, frame.dot.dy);
    canvas.rotate(frame.dotAngle);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: SplashLogo.strokeWidth * frame.dotStretch,
        height: SplashLogo.strokeWidth / frame.dotStretch,
      ),
      Paint()..color = colors.primary,
    );
    canvas.restore();
    canvas.restore();
  }

  void _scaleAround(Canvas canvas, Offset focus, double scale) {
    canvas.translate(focus.dx, focus.dy);
    canvas.scale(scale);
    canvas.translate(-focus.dx, -focus.dy);
  }

  void _paintSparks(Canvas canvas, double progress) {
    final palette = [
      colors.tempo.fill,
      colors.ciano.fill,
      colors.subida.fill,
      colors.primary,
      colors.extra.fill,
      colors.pace.fill,
      colors.primary,
    ];
    final reach = Curves.easeOutCubic.transform(progress) * _sparkReach;
    final paint = Paint();
    for (var i = 0; i < _sparkCount; i++) {
      // Leque para cima a partir do ponto de aterrissagem.
      final angle = -math.pi * (0.06 + 0.88 * i / (_sparkCount - 1));
      final distance = reach * (i.isEven ? 1.0 : 0.72);
      paint.color = palette[i].withValues(alpha: 1 - progress * progress);
      canvas.drawCircle(
        SplashLogo.dotCenter + Offset.fromDirection(angle, distance),
        _sparkRadius * (1 - progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SplashPainter old) =>
      old.frame != frame || old.colors != colors;
}
