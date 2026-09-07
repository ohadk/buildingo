import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/announcement_composer_sheet.dart';

/// Icons and colors for building schedule event types.
class ScheduleUi {
  static IconData iconFor(String type) => switch (type) {
    'garbage' => Icons.delete_outline_rounded,
    'cleaning' => Icons.cleaning_services_outlined,
    'bulk_waste' => Icons.inventory_2_outlined,
    'gardening' => Icons.yard_outlined,
    'pest' => Icons.bug_report_outlined,
    'water_tank' => Icons.water_drop_outlined,
    'meeting' => Icons.groups_outlined,
    'announcement' => Icons.campaign_outlined,
    _ => Icons.event_note_outlined,
  };

  static Color colorFor(String type) => switch (type) {
    'garbage' => DiraColors.sageDark,
    'cleaning' => DiraColors.goldDark,
    'bulk_waste' => DiraColors.brick,
    'gardening' => DiraColors.sage,
    'pest' => DiraColors.brickDark,
    'water_tank' => DiraColors.sageMist,
    'meeting' => DiraColors.brickDark,
    'announcement' => DiraColors.goldDark,
    _ => DiraColors.inkSoft,
  };

  static String defaultTitle(AppLocalizations l10n, String type) =>
      switch (type) {
        'garbage' => l10n.scheduleGarbage,
        'cleaning' => l10n.scheduleCleaning,
        'bulk_waste' => l10n.scheduleBulkWaste,
        'gardening' => l10n.serviceGardening,
        'pest' => l10n.servicePest,
        'water_tank' => l10n.serviceWaterTank,
        'meeting' => l10n.residentsAssembly,
        'announcement' => l10n.announcementTag,
        _ => l10n.scheduleOther,
      };

  static String displayTitle(
    AppLocalizations l10n,
    ScheduleOccurrence occurrence,
  ) {
    final t = occurrence.title.trim();
    return t.isEmpty ? defaultTitle(l10n, occurrence.eventType) : t;
  }

  static String recurrenceLabel(AppLocalizations l10n, String recurrence) =>
      switch (recurrence) {
        'daily' => l10n.scheduleDaily,
        'weekly' => l10n.scheduleWeekly,
        'biweekly' => l10n.scheduleBiweekly,
        'monthly' => l10n.scheduleMonthly,
        'quarterly' => l10n.serviceFrequencyQuarterly,
        'yearly' => l10n.serviceFrequencyYearly,
        _ => l10n.scheduleOnce,
      };

  static String recurrenceDetail(
    AppLocalizations l10n,
    ScheduleOccurrence occurrence,
  ) {
    final parts = <String>[
      recurrenceLabel(l10n, occurrence.recurrence),
      if (occurrence.recurrence == 'monthly' && occurrence.dayOfMonth != null)
        '${occurrence.dayOfMonth}',
    ];
    return parts.join(' · ');
  }

  static String weekdayLabel(AppLocalizations l10n, int day) => switch (day) {
    0 => l10n.sunday,
    1 => l10n.monday,
    2 => l10n.tuesday,
    3 => l10n.wednesday,
    4 => l10n.thursday,
    5 => l10n.friday,
    6 => l10n.saturday,
    _ => '',
  };

  static String relativeDayLabel(
    AppLocalizations l10n,
    DateTime date,
    String locale,
  ) {
    final today = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = d.difference(t).inDays;
    if (diff == 0) return l10n.dateToday;
    if (diff == 1) return l10n.scheduleTomorrow;
    return DateFormat('EEEE, d MMM', locale).format(date);
  }

  /// Sunday-start week (common for IL).
  static DateTime startOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday % 7));
  }

  static DateTime endOfWeek(DateTime d) =>
      startOfWeek(d).add(const Duration(days: 6));

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Compact row used on the home screen and the full schedule list.
class ScheduleEventTile extends StatelessWidget {
  final ScheduleOccurrence occurrence;
  final bool showRelativeDay;
  final VoidCallback? onTap;
  final bool canManage;
  final VoidCallback? onEdit;
  /// Confirm dialog + API delete. Return `true` only when the item was removed.
  final Future<bool> Function()? onDelete;
  /// Called after a successful delete (swipe or icon) so the parent can refresh.
  final VoidCallback? onDeleted;

  const ScheduleEventTile({
    super.key,
    required this.occurrence,
    this.showRelativeDay = true,
    this.onTap,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final color = ScheduleUi.colorFor(occurrence.eventType);
    final when = showRelativeDay
        ? ScheduleUi.relativeDayLabel(l10n, occurrence.occurrenceDate, locale)
        : DateFormat('EEEE, d MMM', locale).format(occurrence.occurrenceDate);
    final timeLabel = occurrence.startsAt != null
        ? DateFormat.Hm(locale).format(occurrence.startsAt!.toLocal())
        : occurrence.timeOfDay;

    Future<void> deleteViaIcon() async {
      final deleted = await onDelete?.call() ?? false;
      if (deleted) onDeleted?.call();
    }

    final tile = Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(
                  ScheduleUi.iconFor(occurrence.eventType),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occurrence.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        when,
                        ?timeLabel,
                        if (occurrence.isMeeting) l10n.residentsAssembly,
                        if (occurrence.eventType == 'announcement')
                          l10n.announcementTag,
                        if (!occurrence.isMeeting &&
                            occurrence.eventType != 'announcement' &&
                            occurrence.recurrence != 'once')
                          ScheduleUi.recurrenceLabel(
                            l10n,
                            occurrence.recurrence,
                          ),
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: DiraColors.inkSoft,
                      ),
                    ),
                    if (occurrence.notes != null &&
                        occurrence.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        occurrence.notes!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: DiraColors.inkSoft,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canManage) ...[
                IconButton(
                  tooltip: l10n.edit,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: l10n.delete,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: onDelete == null ? null : deleteViaIcon,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: DiraColors.brickDark,
                  ),
                ),
              ] else if (onTap != null)
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: 8),
                  child: Icon(
                    // Forward affordance — mirrors in RTL.
                    Icons.chevron_right,
                    color: DiraColors.inkSoft,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!canManage || onDelete == null) return tile;

    return Dismissible(
      key: ValueKey(
        '${occurrence.id}:${occurrence.occurrenceDate.toIso8601String()}',
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete!(),
      onDismissed: (_) => onDeleted?.call(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        decoration: BoxDecoration(
          color: DiraColors.brick,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      child: tile,
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _month;
  late DateTime _selectedDay;
  List<ScheduleOccurrence> _occurrences = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<String>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _month = DateTime(now.year, now.month);
    _load();
    _realtimeSub = realtime.listen(
      {'schedule_events', 'meetings', 'announcements'},
      _load,
    );
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  DateTime get _rangeStart => DateTime(_month.year, _month.month, 1);

  DateTime get _rangeEnd => DateTime(_month.year, _month.month + 1, 0);

  Set<String> get _daysWithEvents => {
        for (final o in _occurrences)
          DateFormat('yyyy-MM-dd').format(o.occurrenceDate),
      };

  List<ScheduleOccurrence> get _dayEvents {
    return _occurrences
        .where((o) => ScheduleUi.sameDay(o.occurrenceDate, _selectedDay))
        .toList();
  }

  Future<void> _load() async {
    final fmt = DateFormat('yyyy-MM-dd');
    try {
      final res = await api.get(
        '/api/schedule-events?from=${fmt.format(_rangeStart)}&to=${fmt.format(_rangeEnd)}',
      );
      if (!mounted) return;
      setState(() {
        _occurrences = ((res['occurrences'] ?? []) as List)
            .map((e) => ScheduleOccurrence.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) {
        final msg = e.message.toLowerCase();
        setState(() {
          _loading = false;
          _error = e.status == 503 ||
                  msg.contains('schedule_events') ||
                  msg.contains('schema cache') ||
                  msg.contains('not set up yet')
              ? context.l10n.scheduleNotReady
              : e.message;
        });
      }
    }
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    setState(() {
      _month = next;
      // Keep selection inside the visible month when possible.
      final last = DateTime(next.year, next.month + 1, 0).day;
      final day = _selectedDay.day.clamp(1, last);
      _selectedDay = DateTime(next.year, next.month, day);
      _loading = true;
    });
    _load();
  }

  Future<void> _addEvent() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ScheduleComposerSheet(initialDate: _selectedDay),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.scheduleSaved)),
      );
      await _load();
    }
  }

  Future<void> _openOccurrence(ScheduleOccurrence o) async {
    final result = await showScheduleOccurrenceDetail(context, o);
    if (result == null || !mounted) return;
    await _load();
    if (!mounted) return;
    final l10n = context.l10n;
    final msg = switch (result) {
      ScheduleDetailResult.deleted => l10n.scheduleEventDeleted,
      ScheduleDetailResult.edited => l10n.scheduleEventUpdated,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _editFromRow(ScheduleOccurrence o) async {
    final saved = await _editOccurrence(context, o);
    if (saved != true || !mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.scheduleEventUpdated)),
    );
  }

  /// Dialog + API only — used by swipe/icon; refresh via [_onOccurrenceDeleted].
  Future<bool> _confirmDeleteOccurrence(ScheduleOccurrence o) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.deleteScheduleEvent),
        content: Text(l10n.deleteScheduleEventConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: TextButton.styleFrom(foregroundColor: DiraColors.brickDark),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return false;
    try {
      await _deleteOccurrence(o);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return false;
    }
  }

  Future<void> _onOccurrenceDeleted() async {
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.scheduleEventDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isVaad = context.watch<SessionController>().user?.isVaad ?? false;
    final monthLabel = DateFormat('MMMM yyyy', locale).format(_month);
    final dayEvents = _dayEvents;
    final dayLabel = ScheduleUi.relativeDayLabel(l10n, _selectedDay, locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.buildingSchedule,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: isVaad
          ? FloatingActionButton(
              heroTag: 'schedule-fab',
              backgroundColor: DiraColors.brick,
              foregroundColor: DiraColors.creamCard,
              tooltip: l10n.addScheduleEvent,
              onPressed: _addEvent,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      body: _error != null && !_loading
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor:
                            DiraColors.goldLight.withValues(alpha: 0.6),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          size: 34,
                          color: DiraColors.goldDark,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: DiraColors.inkSoft,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _shiftMonth(-1),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                      Expanded(
                        child: Text(
                          monthLabel,
                          textAlign: TextAlign.center,
                          style: heading(fontSize: 18),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shiftMonth(1),
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: _MonthCalendarGrid(
                    month: _month,
                    selectedDay: _selectedDay,
                    markedDays: _daysWithEvents,
                    onSelect: (d) => setState(() {
                      _selectedDay = d;
                      if (d.month != _month.month || d.year != _month.year) {
                        _month = DateTime(d.year, d.month);
                        _loading = true;
                        _load();
                      }
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(dayLabel, style: heading(fontSize: 16)),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: DiraColors.brick,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: DiraColors.brick,
                          child: dayEvents.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    12,
                                    24,
                                    100,
                                  ),
                                  children: [
                                    const SizedBox(height: 24),
                                    CircleAvatar(
                                      radius: 34,
                                      backgroundColor: DiraColors.sage
                                          .withValues(alpha: 0.3),
                                      child: const Icon(
                                        Icons.event_available_outlined,
                                        size: 32,
                                        color: DiraColors.sageDark,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.scheduleDayEmptyTitle,
                                      textAlign: TextAlign.center,
                                      style: heading(fontSize: 18),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isVaad
                                          ? l10n.scheduleDayEmptyBodyVaad
                                          : l10n.scheduleDayEmptyBody,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: DiraColors.inkSoft,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    100,
                                  ),
                                  itemCount: dayEvents.length,
                                  itemBuilder: (_, i) {
                                    final o = dayEvents[i];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: ScheduleEventTile(
                                        occurrence: o,
                                        showRelativeDay: false,
                                        canManage: isVaad,
                                        onTap: () => _openOccurrence(o),
                                        onEdit: isVaad
                                            ? () => _editFromRow(o)
                                            : null,
                                        onDelete: isVaad
                                            ? () =>
                                                _confirmDeleteOccurrence(o)
                                            : null,
                                        onDeleted: isVaad
                                            ? () {
                                                _onOccurrenceDeleted();
                                              }
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
    );
  }
}

/// Compact month grid with event dots (Sunday → Saturday).
class _MonthCalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final Set<String> markedDays;
  final ValueChanged<DateTime> onSelect;

  const _MonthCalendarGrid({
    required this.month,
    required this.selectedDay,
    required this.markedDays,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday % 7; // Sun=0
    final today = DateTime.now();
    final cells = leading + daysInMonth;
    final rows = ((cells + 6) / 7).floor();

    final weekdayLabels = [
      l10n.sunday,
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
    ];

    return Container(
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DiraColors.ink.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Text(
                    label.isEmpty ? '' : String.fromCharCode(label.runes.first),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: DiraColors.inkSoft,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _dayCell(
                      index: r * 7 + c,
                      leading: leading,
                      daysInMonth: daysInMonth,
                      today: today,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dayCell({
    required int index,
    required int leading,
    required int daysInMonth,
    required DateTime today,
  }) {
    final dayNum = index - leading + 1;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 42);
    }
    final date = DateTime(month.year, month.month, dayNum);
    final key = DateFormat('yyyy-MM-dd').format(date);
    final selected = ScheduleUi.sameDay(date, selectedDay);
    final isToday = ScheduleUi.sameDay(date, today);
    final hasEvents = markedDays.contains(key);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: selected
            ? DiraColors.brick
            : isToday
                ? DiraColors.terracottaSoft
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(date),
          child: SizedBox(
            height: 42,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? DiraColors.creamCard : DiraColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasEvents
                        ? (selected ? DiraColors.creamCard : DiraColors.brick)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleComposerSheet extends StatefulWidget {
  final DateTime? initialDate;
  final ScheduleOccurrence? initialEvent;

  const _ScheduleComposerSheet({this.initialDate, this.initialEvent});

  @override
  State<_ScheduleComposerSheet> createState() => _ScheduleComposerSheetState();
}

class _ScheduleComposerSheetState extends State<_ScheduleComposerSheet> {
  String _eventType = 'garbage';
  String _recurrence = 'once';
  int _dayOfWeek = DateTime.now().weekday % 7; // JS-style 0=Sun
  int _dayOfMonth = DateTime.now().day;
  late DateTime _specificDate;
  TimeOfDay? _time;
  final _title = TextEditingController();
  final _notes = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.initialEvent;
    if (existing != null) {
      _eventType = existing.eventType;
      _recurrence = existing.recurrence;
      _dayOfWeek = existing.dayOfWeek ?? DateTime.now().weekday % 7;
      _dayOfMonth = existing.dayOfMonth ?? DateTime.now().day;
      final seed = existing.specificDate != null
          ? DateTime.tryParse(existing.specificDate!)
          : existing.occurrenceDate;
      _specificDate = DateTime(
        (seed ?? existing.occurrenceDate).year,
        (seed ?? existing.occurrenceDate).month,
        (seed ?? existing.occurrenceDate).day,
      );
      if (existing.timeOfDay != null && existing.timeOfDay!.length >= 4) {
        final parts = existing.timeOfDay!.split(':');
        _time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      _title.text = existing.title;
      _notes.text = existing.notes ?? '';
    } else {
      final seed = widget.initialDate ?? DateTime.now();
      _specificDate = DateTime(seed.year, seed.month, seed.day);
      _dayOfWeek = _specificDate.weekday % 7;
      _dayOfMonth = _specificDate.day;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _titleValue(AppLocalizations l10n) {
    final t = _title.text.trim();
    return t.isEmpty ? ScheduleUi.defaultTitle(l10n, _eventType) : t;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _specificDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _specificDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final l10n = context.l10n;
    final fmt = DateFormat('yyyy-MM-dd');
    final payload = {
      'eventType': _eventType,
      'title': _titleValue(l10n),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'recurrence': _recurrence,
      if (_recurrence == 'weekly' || _recurrence == 'biweekly')
        'dayOfWeek': _dayOfWeek,
      if (_recurrence == 'monthly') 'dayOfMonth': _dayOfMonth,
      if (_recurrence == 'once') 'specificDate': fmt.format(_specificDate),
      if (_recurrence == 'biweekly') 'specificDate': fmt.format(_specificDate),
      if (_time != null)
        'timeOfDay':
            '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
    };
    try {
      if (_isEdit) {
        await api.patch(
          '/api/schedule-events/${widget.initialEvent!.id}',
          payload,
        );
      } else {
        await api.post('/api/schedule-events', payload);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        final msg = e.message.toLowerCase();
        setState(() {
          _busy = false;
          _error = e.status == 503 ||
                  msg.contains('schedule_events') ||
                  msg.contains('schema cache') ||
                  msg.contains('not set up yet')
              ? l10n.scheduleNotReady
              : e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEdit ? l10n.editScheduleEvent : l10n.addScheduleEvent,
              style: heading(fontSize: 20),
            ),
            const SizedBox(height: 14),
            Text(l10n.scheduleEventType, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in [
                  'garbage',
                  'cleaning',
                  'bulk_waste',
                  'other',
                ])
                  ChoiceChip(
                    label: Text(ScheduleUi.defaultTitle(l10n, type)),
                    selected: _eventType == type,
                    onSelected: (_) => setState(() => _eventType = type),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: InputDecoration(labelText: l10n.scheduleRepeat),
              items: [
                DropdownMenuItem(
                  value: 'once',
                  child: Text(l10n.scheduleOnce),
                ),
                DropdownMenuItem(
                  value: 'daily',
                  child: Text(l10n.scheduleDaily),
                ),
                DropdownMenuItem(
                  value: 'weekly',
                  child: Text(l10n.scheduleWeekly),
                ),
                DropdownMenuItem(
                  value: 'biweekly',
                  child: Text(l10n.scheduleBiweekly),
                ),
                DropdownMenuItem(
                  value: 'monthly',
                  child: Text(l10n.scheduleMonthly),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _recurrence = v);
              },
            ),
            const SizedBox(height: 12),
            if (_recurrence == 'weekly' || _recurrence == 'biweekly')
              DropdownButtonFormField<int>(
                initialValue: _dayOfWeek,
                decoration: InputDecoration(labelText: l10n.scheduleDay),
                items: [
                  for (var d = 0; d < 7; d++)
                    DropdownMenuItem(
                      value: d,
                      child: Text(ScheduleUi.weekdayLabel(l10n, d)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _dayOfWeek = v);
                },
              ),
            if (_recurrence == 'monthly')
              DropdownButtonFormField<int>(
                initialValue: _dayOfMonth,
                decoration: InputDecoration(labelText: l10n.scheduleDayOfMonth),
                items: [
                  for (var d = 1; d <= 31; d++)
                    DropdownMenuItem(value: d, child: Text('$d')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _dayOfMonth = v);
                },
              ),
            if (_recurrence == 'once' || _recurrence == 'biweekly') ...[
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.scheduleDate),
                subtitle: Text(
                  DateFormat('EEEE, d MMMM yyyy', locale)
                      .format(_specificDate),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
            ],
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.scheduleTimeOptional),
              subtitle: Text(
                _time == null
                    ? '—'
                    : _time!.format(context),
              ),
              trailing: const Icon(Icons.schedule_outlined),
              onTap: _pickTime,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: l10n.scheduleEventTitle,
                hintText: ScheduleUi.defaultTitle(l10n, _eventType),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.scheduleNotesOptional),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? l10n.pleaseWait : l10n.save),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: DiraColors.brick),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum ScheduleDetailResult { edited, deleted }

Future<ScheduleDetailResult?> showScheduleOccurrenceDetail(
  BuildContext context,
  ScheduleOccurrence occurrence,
) {
  final isVaad = context.read<SessionController>().user?.isVaad ?? false;
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).languageCode;
  final color = ScheduleUi.colorFor(occurrence.eventType);
  final when = DateFormat(
    'EEEE, d MMM yyyy',
    locale,
  ).format(occurrence.occurrenceDate);
  final timeLabel = occurrence.startsAt != null
      ? DateFormat.Hm(locale).format(occurrence.startsAt!.toLocal())
      : occurrence.timeOfDay;

  return showModalBottomSheet<ScheduleDetailResult>(
    context: context,
    backgroundColor: DiraColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DiraColors.ink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(
                    ScheduleUi.iconFor(occurrence.eventType),
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(occurrence.title, style: heading(fontSize: 20)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              [
                when,
                if (timeLabel != null) timeLabel,
                if (occurrence.isMeeting) l10n.residentsAssembly,
                if (occurrence.isAnnouncement) l10n.announcementTag,
              ].join(' · '),
              style: const TextStyle(
                fontSize: 12.5,
                color: DiraColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (occurrence.notes != null &&
                occurrence.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                occurrence.notes!,
                style: const TextStyle(fontSize: 15, height: 1.45),
              ),
            ],
            if (isVaad) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final saved = await _editOccurrence(ctx, occurrence);
                        if (saved == true && ctx.mounted) {
                          Navigator.pop(ctx, ScheduleDetailResult.edited);
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l10n.edit),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DiraColors.brickDark,
                        side: const BorderSide(color: DiraColors.brick),
                      ),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: ctx,
                          builder: (dCtx) => AlertDialog(
                            title: Text(l10n.deleteScheduleEvent),
                            content: Text(l10n.deleteScheduleEventConfirm),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: DiraColors.brickDark,
                                ),
                                child: Text(l10n.delete),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !ctx.mounted) return;
                        try {
                          await _deleteOccurrence(occurrence);
                          if (ctx.mounted) {
                            Navigator.pop(ctx, ScheduleDetailResult.deleted);
                          }
                        } on ApiException catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l10n.delete),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<bool?> _editOccurrence(
  BuildContext context,
  ScheduleOccurrence occurrence,
) async {
  if (occurrence.isAnnouncement) {
    final a = Announcement.fromJson({
      'id': occurrence.id,
      'title': occurrence.title,
      'body': occurrence.notes ?? '',
      'event_date': DateFormat('yyyy-MM-dd').format(occurrence.occurrenceDate),
      'created_at': DateTime.now().toIso8601String(),
      'category': 'update',
    });
    return showAnnouncementComposer(context, initial: a);
  }

  if (occurrence.isMeeting) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MeetingEditSheet(occurrence: occurrence),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DiraColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ScheduleComposerSheet(initialEvent: occurrence),
  );
}

Future<void> _deleteOccurrence(ScheduleOccurrence occurrence) async {
  if (occurrence.isAnnouncement) {
    await api.delete('/api/announcements/${occurrence.id}');
    return;
  }
  if (occurrence.isMeeting) {
    await api.delete('/api/meetings/${occurrence.id}');
    return;
  }
  await api.delete('/api/schedule-events/${occurrence.id}');
}

class _MeetingEditSheet extends StatefulWidget {
  final ScheduleOccurrence occurrence;
  const _MeetingEditSheet({required this.occurrence});

  @override
  State<_MeetingEditSheet> createState() => _MeetingEditSheetState();
}

class _MeetingEditSheetState extends State<_MeetingEditSheet> {
  late final TextEditingController _title;
  late final TextEditingController _agenda;
  late final TextEditingController _location;
  late DateTime _date;
  late TimeOfDay _time;
  bool _busy = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final o = widget.occurrence;
    _title = TextEditingController(text: o.title);
    _agenda = TextEditingController();
    _location = TextEditingController(text: o.notes ?? '');
    final start = o.startsAt?.toLocal() ?? o.occurrenceDate;
    _date = DateTime(start.year, start.month, start.day);
    _time = TimeOfDay(hour: start.hour, minute: start.minute);
    _loadMeeting();
  }

  Future<void> _loadMeeting() async {
    try {
      final data = await api.get('/api/meetings');
      final list = (data['meetings'] ?? []) as List;
      final match = list.cast<Map>().where((m) => m['id'] == widget.occurrence.id);
      if (match.isNotEmpty) {
        final m = match.first;
        _agenda.text = (m['agenda'] ?? '').toString();
        if (m['location'] != null) _location.text = m['location'].toString();
      }
    } catch (_) {
      /* keep defaults from occurrence */
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _title.dispose();
    _agenda.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().length < 2 || _agenda.text.trim().length < 2) {
      setState(() => _error = context.l10n.authErrorGeneric);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final local = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    try {
      await api.patch('/api/meetings/${widget.occurrence.id}', {
        'title': _title.text.trim(),
        'agenda': _agenda.text.trim(),
        'meetingDate': local.toUtc().toIso8601String(),
        'location': _location.text.trim().isEmpty
            ? null
            : _location.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.editMeeting, style: heading(fontSize: 20)),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.titleLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _agenda,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.agenda),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              decoration: InputDecoration(labelText: l10n.meetingLocationLabel),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.scheduleDate),
              subtitle: Text(
                DateFormat('EEEE, d MMMM yyyy', locale).format(_date),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.scheduleTimeOptional),
              subtitle: Text(_time.format(context)),
              trailing: const Icon(Icons.schedule_outlined),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
            ),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? l10n.pleaseWait : l10n.save),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: DiraColors.brick),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
