import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';

/// MVP placeholder for the Vaad "Agents" tab — teases AI vendor dispatch
/// for the next release with a light motion treatment.
class VendorAgentsScreen extends StatefulWidget {
  const VendorAgentsScreen({super.key});

  @override
  State<VendorAgentsScreen> createState() => _VendorAgentsScreenState();
}

class _VendorAgentsScreenState extends State<VendorAgentsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 10000),
  )..repeat();

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _pulse.dispose();
    _orbit.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enter = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);

    return Scaffold(
      backgroundColor: DiraColors.cream,
      appBar: AppBar(title: Text(l10n.vendorAiAgents)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
          child: Column(
            children: [
              const SizedBox(height: 12),
              FadeTransition(
                opacity: enter,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(enter),
                  child: _HeroOrb(pulse: _pulse, orbit: _orbit),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: enter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: DiraColors.goldLight,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: DiraColors.gold.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) {
                          final t = 0.55 + (_pulse.value * 0.45);
                          return Opacity(
                            opacity: t,
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: DiraColors.goldDark,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.agentsComingSoonBadge,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: DiraColors.goldDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: enter,
                child: Text(
                  l10n.agentsComingSoonTitle,
                  textAlign: TextAlign.center,
                  style: heading(fontSize: 24),
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: enter,
                child: Text(
                  l10n.agentsComingSoonBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: DiraColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _FeatureCard(
                delay: const Interval(0.25, 1, curve: Curves.easeOutCubic),
                enter: _enter,
                icon: Icons.alternate_email_rounded,
                text: l10n.agentsComingSoonFeature1,
              ),
              const SizedBox(height: 10),
              _FeatureCard(
                delay: const Interval(0.4, 1, curve: Curves.easeOutCubic),
                enter: _enter,
                icon: Icons.touch_app_rounded,
                text: l10n.agentsComingSoonFeature2,
              ),
              const SizedBox(height: 10),
              _FeatureCard(
                delay: const Interval(0.55, 1, curve: Curves.easeOutCubic),
                enter: _enter,
                icon: Icons.campaign_rounded,
                text: l10n.agentsComingSoonFeature3,
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _enter,
                  curve: const Interval(0.65, 1, curve: Curves.easeOut),
                ),
                child: Text(
                  l10n.agentsComingSoonFootnote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: DiraColors.inkSoft,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  final Animation<double> pulse;
  final Animation<double> orbit;

  const _HeroOrb({required this.pulse, required this.orbit});

  @override
  Widget build(BuildContext context) {
    const size = 168.0;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: Listenable.merge([pulse, orbit]),
        builder: (context, _) {
          final scale = 1 + (pulse.value * 0.045);
          final glow = 0.18 + (pulse.value * 0.16);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      DiraColors.terracottaSoft.withValues(alpha: 0.95),
                      DiraColors.cream.withValues(alpha: 0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DiraColors.brick.withValues(alpha: glow),
                      blurRadius: 36,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DiraColors.creamCard,
                    border: Border.all(
                      color: DiraColors.terracottaBlush,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DiraColors.brickDeep.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 48,
                    color: DiraColors.brick,
                  ),
                ),
              ),
              ..._orbitIcons(orbit.value),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _orbitIcons(double t) {
    const icons = <(IconData, Color)>[
      (Icons.alternate_email_rounded, DiraColors.sageDark),
      (Icons.sms_rounded, DiraColors.brickDark),
      (Icons.chat_rounded, DiraColors.goldDark),
    ];
    return [
      for (var i = 0; i < icons.length; i++)
        Transform.translate(
          offset: Offset(
            math.cos((t * 2 * math.pi) + (i * 2 * math.pi / 3)) * 66,
            math.sin((t * 2 * math.pi) + (i * 2 * math.pi / 3)) * 66,
          ),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DiraColors.creamCard,
              shape: BoxShape.circle,
              border: Border.all(color: DiraColors.sageLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icons[i].$1, size: 18, color: icons[i].$2),
          ),
        ),
    ];
  }
}

class _FeatureCard extends StatelessWidget {
  final Animation<double> enter;
  final Interval delay;
  final IconData icon;
  final String text;

  const _FeatureCard({
    required this.enter,
    required this.delay,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: enter, curve: delay);
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(anim),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: DiraColors.creamCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DiraColors.sageLight),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: DiraColors.sagePale,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: DiraColors.sageDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: DiraColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
