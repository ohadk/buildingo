import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Built-in fault categories — the reporter picks one; home/list rows
/// show the matching glyph.
class TicketCategory {
  final String id;
  final IconData icon;
  final Color color;

  const TicketCategory({
    required this.id,
    required this.icon,
    required this.color,
  });

  String label(AppLocalizations l10n) => switch (id) {
        'leak' => l10n.ticketCatLeak,
        'elevator' => l10n.ticketCatElevator,
        'cleaning' => l10n.ticketCatCleaning,
        'lights' => l10n.ticketCatLights,
        'electric' => l10n.ticketCatElectric,
        'door' => l10n.ticketCatDoor,
        _ => l10n.ticketCatOther,
      };

  static const leak = TicketCategory(
    id: 'leak',
    icon: Icons.water_drop_outlined,
    color: DiraColors.sageDark,
  );
  static const elevator = TicketCategory(
    id: 'elevator',
    icon: Icons.elevator_outlined,
    color: DiraColors.brick,
  );
  static const cleaning = TicketCategory(
    id: 'cleaning',
    icon: Icons.cleaning_services_outlined,
    color: DiraColors.sage,
  );
  static const lights = TicketCategory(
    id: 'lights',
    icon: Icons.lightbulb_outline,
    color: DiraColors.goldDark,
  );
  static const electric = TicketCategory(
    id: 'electric',
    icon: Icons.bolt_outlined,
    color: DiraColors.terracotta,
  );
  static const door = TicketCategory(
    id: 'door',
    icon: Icons.door_front_door_outlined,
    color: DiraColors.brickDark,
  );
  static const other = TicketCategory(
    id: 'other',
    icon: Icons.handyman_outlined,
    color: DiraColors.inkSoft,
  );

  static const all = <TicketCategory>[
    leak,
    elevator,
    cleaning,
    lights,
    electric,
    door,
    other,
  ];

  static TicketCategory byId(String? id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return other;
  }

  /// Infer from free text when category was never set (legacy tickets).
  static TicketCategory inferFromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('elev') || t.contains('מעלית')) return elevator;
    if (t.contains('water') ||
        t.contains('leak') ||
        t.contains('מים') ||
        t.contains('נזיל')) {
      return leak;
    }
    if (t.contains('clean') || t.contains('ניק') || t.contains('אשפה')) {
      return cleaning;
    }
    if (t.contains('light') ||
        t.contains('bulb') ||
        t.contains('מנור') ||
        t.contains('נורה') ||
        t.contains('תאור')) {
      return lights;
    }
    if (t.contains('electric') || t.contains('חשמל') || t.contains('קצר')) {
      return electric;
    }
    if (t.contains('door') ||
        t.contains('intercom') ||
        t.contains('דלת') ||
        t.contains('אינטרקום')) {
      return door;
    }
    return other;
  }
}
