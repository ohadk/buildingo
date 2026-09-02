import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Three-stage progress rail: New → In progress → Done.
class TicketTimeline extends StatelessWidget {
  final Ticket ticket;
  final ValueChanged<String>? onStageTap;
  final bool saving;

  const TicketTimeline({
    super.key,
    required this.ticket,
    this.onStageTap,
    this.saving = false,
  });

  static const _stageStatuses = ['open', 'in_progress', 'resolved'];

  static const _stageIcons = [
    Icons.flag_rounded,
    Icons.build_circle_outlined,
    Icons.check_circle_rounded,
  ];

  int get _currentStage {
    switch (ticket.displayStatus) {
      case 'in_progress':
        return 1;
      case 'resolved':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentStage;
    final interactive = onStageTap != null;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final stageLabels = [
      l10n.statusOpen,
      l10n.statusInProgress,
      l10n.statusResolved,
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
                interactive: interactive,
                saving: saving && i == current,
                onTap: interactive
                    ? () => onStageTap!(_stageStatuses[i])
                    : null,
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
        if (ticket.progressNote != null &&
            ticket.progressNote!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              ticket.progressNote!.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: DiraColors.creamCard),
            ),
          ),
        if (ticket.fixDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.ticketFixDate(
                DateFormat('d MMM yyyy', locale).format(ticket.fixDate!),
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
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

class _StageDot extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool reached;
  final bool active;
  final bool interactive;
  final bool saving;
  final VoidCallback? onTap;

  const _StageDot({
    required this.label,
    required this.icon,
    required this.reached,
    required this.active,
    required this.interactive,
    required this.saving,
    this.onTap,
  });

  @override
  State<_StageDot> createState() => _StageDotState();
}

class _StageDotState extends State<_StageDot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;
    final scale = _pressed ? 0.9 : 1.0;

    return Semantics(
      button: tappable,
      enabled: tappable,
      label: widget.label,
      child: SizedBox(
        width: 64,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  onHighlightChanged: tappable
                      ? (v) => setState(() => _pressed = v)
                      : null,
                  customBorder: const CircleBorder(),
                  splashColor: Colors.white.withValues(alpha: 0.35),
                  highlightColor: Colors.white.withValues(alpha: 0.18),
                  child: Ink(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: tappable
                          ? Border.all(
                              color: widget.active
                                  ? DiraColors.creamCard.withValues(alpha: 0.9)
                                  : Colors.white.withValues(
                                      alpha: widget.reached ? 0.75 : 0.5,
                                    ),
                              width: widget.active ? 2.5 : 2,
                            )
                          : null,
                      boxShadow: tappable && !widget.active
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.active
                              ? DiraColors.brick
                              : widget.reached
                              ? DiraColors.sageMist
                              : tappable
                              ? Colors.white.withValues(alpha: 0.28)
                              : Colors.white.withValues(alpha: 0.18),
                          boxShadow: widget.active
                              ? [
                                  BoxShadow(
                                    color: DiraColors.brick.withValues(
                                      alpha: 0.55,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: widget.saving
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : widget.active
                            ? const Icon(
                                Icons.bolt_rounded,
                                size: 18,
                                color: Colors.white,
                              )
                            : widget.reached
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Colors.white,
                              )
                            : Icon(
                                widget.icon,
                                size: 16,
                                color: Colors.white.withValues(
                                  alpha: tappable ? 0.85 : 0.55,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 26,
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: tappable ? FontWeight.w600 : FontWeight.normal,
                    decoration: tappable && !widget.active
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: Colors.white.withValues(alpha: 0.55),
                    color: widget.reached || widget.active
                        ? Colors.white
                        : Colors.white.withValues(alpha: tappable ? 0.75 : 0.55),
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
