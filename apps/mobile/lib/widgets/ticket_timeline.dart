import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Horizontal progress rail matching the design: Reported → Approved by
/// Vaad → AI Dispatching → Resolved, with the live vendor-contact detail
/// under the dispatch step.
class TicketTimeline extends StatelessWidget {
  final Ticket ticket;
  const TicketTimeline({super.key, required this.ticket});

  static const _stageIcons = [
    Icons.flag_rounded,
    Icons.verified_rounded,
    Icons.smart_toy_rounded,
    Icons.check_circle_rounded,
  ];

  int get _currentStage {
    switch (ticket.status) {
      case 'open':
        return 0;
      case 'approved':
        return 1;
      case 'in_progress':
        return 2;
      case 'resolved':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentStage;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final stageLabels = [
      l10n.stageReported,
      l10n.stageApprovedByVaad,
      l10n.stageAgentWorking,
      l10n.stageResolved,
    ];
    final contactEvent = ticket.events
        .where((e) => e.label == 'Agent Contacted Vendor')
        .lastOrNull;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < stageLabels.length; i++) ...[
              _StageDot(
                label: stageLabels[i],
                icon: _stageIcons[i],
                reached: i <= current,
                active: i == current,
              ),
              if (i < stageLabels.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i < current
                          ? DiraColors.sageMist
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
            ],
          ],
        ),
        if (contactEvent != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${contactEvent.detail ?? l10n.vendorContactedShort} · '
              '${DateFormat('d MMM, HH:mm', locale).format(contactEvent.createdAt.toLocal())}',
              style: const TextStyle(fontSize: 11, color: DiraColors.creamCard),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _StageDot extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool reached;
  final bool active;

  const _StageDot({
    required this.label,
    required this.icon,
    required this.reached,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? DiraColors.brick
                : reached
                ? DiraColors.sageMist
                : Colors.white.withValues(alpha: 0.18),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: DiraColors.brick.withValues(alpha: 0.55),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: active
              ? const Icon(Icons.bolt_rounded, size: 18, color: Colors.white)
              : reached
              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
              : Icon(
                  icon,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 24,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: reached || active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}
