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
    'meeting' => Icons.groups_outlined,
    _ => Icons.event_note_outlined,
  };

  static Color colorFor(String type) => switch (type) {
    'garbage' => DiraColors.sageDark,
    'cleaning' => DiraColors.goldDark,
    'bulk_waste' => DiraColors.brick,
    'meeting' => DiraColors.brickDark,
    _ => DiraColors.inkSoft,
  };

  static String defaultTitle(AppLocalizations l10n, String type) =>
      switch (type) {
        'garbage' => l10n.scheduleGarbage,
        'cleaning' => l10n.scheduleCleaning,
        'bulk_waste' => l10n.scheduleBulkWaste,
        'meeting' => l10n.residentsAssembly,
        _ => l10n.scheduleOther,
      };

  static String recurrenceLabel(AppLocalizations l10n, String recurrence) =>
      switch (recurrence) {
        'daily' => l10n.scheduleDaily,
        'weekly' => l10n.scheduleWeekly,
        'biweekly' => l10n.scheduleBiweekly,
        'monthly' => l10n.scheduleMonthly,
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
                      if (!occurrence.isMeeting && occurrence.recurrence != 'once')
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
  List<ScheduleOccurrence> _occurrences = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<String>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
    _realtimeSub = realtime.listen({'schedule_events', 'meetings'}, _load);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  DateTime get _rangeStart => DateTime(_month.year, _month.month, 1);

  DateTime get _rangeEnd =>
      DateTime(_month.year, _month.month + 1, 0); // last day of month

  Future<void> _load() async {
    final fmt = DateFormat('yyyy-MM-dd');
    try {
      final res = await api.get(
        '/api/schedule-events?from=${fmt.format(_rangeStart)}&to=${fmt.format(_rangeEnd)}',
      );
      if (!mounted) return;
      setState(() {
        _occurrences = ((res['occurrences'] ?? []) as List)
            .map((e) => ScheduleOccurrence.fromJson(e))
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
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
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
      builder: (_) => const _ScheduleComposerSheet(),
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

    final groups = <String, List<ScheduleOccurrence>>{};
    for (final o in _occurrences) {
      final key = DateFormat('yyyy-MM-dd').format(o.occurrenceDate);
      groups.putIfAbsent(key, () => []).add(o);
    }
    final keys = groups.keys.toList()..sort();

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
      body: Column(
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
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: DiraColors.brick),
                  )
                : _error != null
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
                : _occurrences.isEmpty
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(36),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor:
                                  DiraColors.sage.withValues(alpha: 0.35),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                size: 34,
                                color: DiraColors.sageDark,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              l10n.scheduleEmptyTitle,
                              textAlign: TextAlign.center,
                              style: heading(fontSize: 20),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.scheduleEmptyBody,
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
                : RefreshIndicator(
                    onRefresh: _load,
                    color: DiraColors.brick,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      children: [
                        for (final key in keys) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Text(
                              ScheduleUi.relativeDayLabel(
                                l10n,
                                DateTime.parse(key),
                                locale,
                              ),
                              style: heading(fontSize: 15),
                            ),
                          ),
                          ...groups[key]!.map(
                            (o) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ScheduleEventTile(
                                occurrence: o,
                                showRelativeDay: false,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleComposerSheet extends StatefulWidget {
  const _ScheduleComposerSheet();

  @override
  State<_ScheduleComposerSheet> createState() => _ScheduleComposerSheetState();
}

class _ScheduleComposerSheetState extends State<_ScheduleComposerSheet> {
  String _eventType = 'garbage';
  String _recurrence = 'weekly';
  int _dayOfWeek = DateTime.now().weekday % 7; // JS-style 0=Sun
  int _dayOfMonth = DateTime.now().day;
  DateTime _specificDate = DateTime.now();
  TimeOfDay? _time;
  final _title = TextEditingController();
  final _notes = TextEditingController();
  bool _busy = false;
  String? _error;

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
