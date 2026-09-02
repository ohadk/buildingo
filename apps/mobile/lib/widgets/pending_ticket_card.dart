import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/ticket_categories.dart';
import '../core/tickets_controller.dart';
import '../l10n/l10n.dart';
import 'status_pill.dart';

/// Same compact service-call row as a real ticket, plus upload/create state.
class PendingTicketCard extends StatelessWidget {
  final PendingTicket pending;

  const PendingTicketCard({
    super.key,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = pending.draft;
    final cat = TicketCategory.byId(draft.category);
    final (statusLabel, statusBg, statusFg) = switch (pending.phase) {
      PendingTicketPhase.uploadingPhoto => (
          l10n.ticketUploadingPhoto,
          DiraColors.goldLight,
          DiraColors.goldDark,
        ),
      PendingTicketPhase.creating => (
          l10n.ticketCreating,
          DiraColors.terracottaSoft,
          DiraColors.brickDark,
        ),
      PendingTicketPhase.done => (
          l10n.ticketCreateDone,
          DiraColors.sageLight,
          DiraColors.sageDark,
        ),
      PendingTicketPhase.failed => (
          l10n.ticketCreateFailed,
          const Color(0xFFF8E4DE),
          DiraColors.brick,
        ),
    };

    return AnimatedOpacity(
      opacity: pending.phase == PendingTicketPhase.done ? 0.55 : 1,
      duration: const Duration(milliseconds: 280),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CategoryGlyph(category: cat),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: pending.phase == PendingTicketPhase.failed
                            ? DiraColors.brick
                            : DiraColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (pending.isActive)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DiraColors.brick,
                  ),
                )
              else
                StatusPill(
                  label: pending.phase == PendingTicketPhase.done
                      ? l10n.ticketCreateDone
                      : l10n.ticketCreateFailed,
                  background: statusBg,
                  foreground: statusFg,
                ),
              if (pending.phase == PendingTicketPhase.failed) ...[
                const SizedBox(width: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.ticketRetry,
                  onPressed: () {
                    final inbox = context.read<TicketsController>();
                    inbox.dismiss(pending.localId);
                    inbox.submit(draft);
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ] else
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: DiraColors.inkSoft,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
