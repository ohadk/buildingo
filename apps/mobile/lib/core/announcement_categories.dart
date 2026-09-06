import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Building-board message labels — Vaad picks one; home cards show the
/// matching icon + color (aligned with the marketing board design).
class AnnouncementCategory {
  final String id;
  final IconData icon;
  final Color color;

  const AnnouncementCategory({
    required this.id,
    required this.icon,
    required this.color,
  });

  String label(AppLocalizations l10n) => switch (id) {
        'meeting' => l10n.boardCatMeeting,
        'maintenance' => l10n.boardCatMaintenance,
        'tip' => l10n.boardCatTip,
        'other' => l10n.boardCatOther,
        _ => l10n.boardCatUpdate,
      };

  /// CTA under the card body (design: Details / Read / View).
  String actionLabel(AppLocalizations l10n) => switch (id) {
        'meeting' => l10n.boardActionDetails,
        'tip' || 'maintenance' => l10n.boardActionView,
        _ => l10n.boardActionRead,
      };

  static const update = AnnouncementCategory(
    id: 'update',
    icon: Icons.campaign_rounded,
    color: DiraColors.brick,
  );
  static const meeting = AnnouncementCategory(
    id: 'meeting',
    icon: Icons.calendar_month_rounded,
    color: DiraColors.sage,
  );
  static const maintenance = AnnouncementCategory(
    id: 'maintenance',
    icon: Icons.eco_rounded,
    color: DiraColors.sageDark,
  );
  static const tip = AnnouncementCategory(
    id: 'tip',
    icon: Icons.tips_and_updates_rounded,
    color: DiraColors.goldDark,
  );
  static const other = AnnouncementCategory(
    id: 'other',
    icon: Icons.sticky_note_2_rounded,
    color: DiraColors.inkSoft,
  );

  static const all = <AnnouncementCategory>[
    update,
    meeting,
    maintenance,
    tip,
    other,
  ];

  static AnnouncementCategory byId(String? id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return update;
  }

  /// Fallback for older rows without a stored category.
  static AnnouncementCategory inferFromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('אסיפ') ||
        t.contains('meeting') ||
        t.contains('assembly')) {
      return meeting;
    }
    if (t.contains('תחזוק') ||
        t.contains('ירוק') ||
        t.contains('maintenance') ||
        t.contains('clean')) {
      return maintenance;
    }
    if (t.contains('טיפ') || t.contains('tip') || t.contains('חיסכון')) {
      return tip;
    }
    return update;
  }
}
