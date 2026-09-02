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

  const ScheduleEventTile({
    super.key,
    required this.occurrence,
    this.showRelativeDay = true,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        ScheduleUi.recurrenceLabel(l10n, occurrence.recurrence),
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
          ],
        ),
      ),
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
                        icon: const Icon(Icons.chevron_left),
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
                        icon: const Icon(Icons.chevron_right),
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
                                  itemBuilder: (_, i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ScheduleEventTile(
                                      occurrence: dayEvents[i],
                                      showRelativeDay: false,
                                    ),
                                  ),
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
  const _ScheduleComposerSheet({this.initialDate});

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

  @override
  void initState() {
    super.initState();
    final seed = widget.initialDate ?? DateTime.now();
    _specificDate = DateTime(seed.year, seed.month, seed.day);
    _dayOfWeek = _specificDate.weekday % 7;
    _dayOfMonth = _specificDate.day;
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
    try {
      await api.post('/api/schedule-events', {
        'eventType': _eventType,
        'title': _titleValue(l10n),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'recurrence': _recurrence,
        if (_recurrence == 'weekly' || _recurrence == 'biweekly')
          'dayOfWeek': _dayOfWeek,
        if (_recurrence == 'monthly') 'dayOfMonth': _dayOfMonth,
        if (_recurrence == 'once')
          'specificDate': fmt.format(_specificDate),
        if (_recurrence == 'biweekly')
          'specificDate': fmt.format(_specificDate),
        if (_time != null)
          'timeOfDay':
              '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
      });
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
            Text(l10n.addScheduleEvent, style: heading(fontSize: 20)),
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
