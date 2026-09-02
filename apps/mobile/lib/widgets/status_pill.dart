import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/ticket_categories.dart';
import '../l10n/l10n.dart';

/// Soft rounded status chip used on home service-call rows and payments.
class StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final bool compact;

  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.compact = false,
  });

  factory StatusPill.ticket(
    BuildContext context,
    String status, {
    bool compact = false,
  }) {
    final l10n = context.l10n;
    switch (status) {
      case 'resolved':
        return StatusPill(
          label: l10n.statusResolved,
          background: DiraColors.sageLight,
          foreground: DiraColors.sageDark,
          compact: compact,
        );
      case 'in_progress':
      case 'approved':
        return StatusPill(
          label: l10n.statusInProgress,
          background: DiraColors.terracottaSoft,
          foreground: DiraColors.brickDark,
          compact: compact,
        );
      default:
        return StatusPill(
          label: l10n.statusOpen,
          background: const Color(0xFFF8E4DE),
          foreground: DiraColors.brick,
          compact: compact,
        );
    }
  }

  factory StatusPill.payment(BuildContext context, {required bool paid}) {
    final l10n = context.l10n;
    if (paid) {
      return StatusPill(
        label: l10n.statusPaid,
        background: DiraColors.sageLight,
        foreground: DiraColors.sageDark,
      );
    }
    return StatusPill(
      label: l10n.statusUnpaid,
      background: DiraColors.terracottaSoft,
      foreground: DiraColors.brickDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10.5 : 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

/// Rounded square glyph used on service-call list rows.
class CategoryGlyph extends StatelessWidget {
  final TicketCategory category;

  const CategoryGlyph({super.key, required this.category});

  factory CategoryGlyph.forTicket({
    required String? categoryId,
    required String title,
  }) {
    if (categoryId != null &&
        categoryId.isNotEmpty &&
        categoryId != 'other') {
      return CategoryGlyph(category: TicketCategory.byId(categoryId));
    }
    return CategoryGlyph(category: TicketCategory.inferFromTitle(title));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(category.icon, size: 22, color: category.color),
    );
  }
}
