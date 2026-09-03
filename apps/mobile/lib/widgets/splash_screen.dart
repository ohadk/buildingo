import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Brand splash used while Firebase auth / session bootstrap resolve.
/// Soft organic motion — entrance, breathing mark, drifting atmosphere.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _breathe;
  late final AnimationController _drift;
  late final AnimationController _progress;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _footerOpacity;

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _logoScale = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _logoOpacity = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _titleOpacity = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _footerOpacity = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _breathe.dispose();
    _drift.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_enter, _breathe, _drift, _progress]),
        builder: (context, _) {
          final breath = 0.92 + (_breathe.value * 0.08);
          final ring = 1.0 + (_breathe.value * 0.12);

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF8EE),
                      DiraColors.terracottaSoft,
                      Color(0xFFE8D5C4),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              CustomPaint(
                painter: _AtmospherePainter(
                  t: _drift.value,
                  breath: _breathe.value,
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: _logoOpacity.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _logoScale.value * breath,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 148 * ring,
                                  height: 148 * ring,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: DiraColors.brick.withValues(
                                        alpha: 0.12 + _breathe.value * 0.1,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 124 * ring,
                                  height: 124 * ring,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: DiraColors.creamCard.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 104,
                                  height: 104,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: DiraColors.creamCard,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DiraColors.brickDeep.withValues(
                                          alpha: 0.18,
                                        ),
                                        blurRadius: 28,
                                        offset: const Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/icon/app_icon_1024.png',
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FadeTransition(
                          opacity: _titleOpacity,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Column(
                              children: [
                                Text(
                                  'Buildingo',
                                  textAlign: TextAlign.center,
                                  style: heading(
                                    fontSize: 38,
                                    color: DiraColors.brickDeep,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.splashTagline,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.35,
                                    color: DiraColors.brickDark.withValues(
                                      alpha: 0.85,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Opacity(
                          opacity: _footerOpacity.value.clamp(0.0, 1.0),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 120,
                                child: CustomPaint(
                                  painter: _ProgressRibbonPainter(
                                    t: _progress.value,
                                  ),
                                  size: const Size(120, 4),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                l10n.splashLoading,
                                style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                  color: DiraColors.inkSoft.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  final double t;
  final double breath;

  _AtmospherePainter({required this.t, required this.breath});

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset c, double r, Color color) {
      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawCircle(c, r, paint);
    }

    final w = size.width;
    final h = size.height;
    final sway = math.sin(t * math.pi * 2);
    final bob = math.cos(t * math.pi * 2);

    blob(
      Offset(w * 0.18 + sway * 18, h * 0.22 + bob * 12),
      90 + breath * 10,
      DiraColors.gold.withValues(alpha: 0.22),
    );
    blob(
      Offset(w * 0.82 - sway * 14, h * 0.28 - bob * 10),
      110 + breath * 8,
      DiraColors.sageMist.withValues(alpha: 0.2),
    );
    blob(
      Offset(w * 0.5 + bob * 20, h * 0.78 + sway * 16),
      130,
      DiraColors.terracotta.withValues(alpha: 0.16),
    );
    blob(
      Offset(w * 0.12, h * 0.7 - bob * 8),
      70,
      DiraColors.creamCard.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter old) =>
      old.t != t || old.breath != breath;
}

/// Soft sliding highlight on a thin cream track.
class _ProgressRibbonPainter extends CustomPainter {
  final double t;

  _ProgressRibbonPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(999),
    );
    canvas.drawRRect(
      track,
      Paint()..color = DiraColors.brick.withValues(alpha: 0.12),
    );

    final travel = (t * 1.6) - 0.3;
    final start = (travel.clamp(0.0, 1.0)) * size.width;
    final end = ((travel + 0.35).clamp(0.0, 1.0)) * size.width;
    if (end <= start) return;

    final highlight = RRect.fromRectAndRadius(
      Rect.fromLTRB(start, 0, end, size.height),
      const Radius.circular(999),
    );
    canvas.drawRRect(
      highlight,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x00A34A3A),
            DiraColors.brick,
            DiraColors.terracotta,
            Color(0x00A34A3A),
          ],
        ).createShader(Rect.fromLTRB(start, 0, end, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRibbonPainter old) => old.t != t;
}
