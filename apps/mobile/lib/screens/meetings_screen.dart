import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

class MeetingsScreen extends StatefulWidget {
  /// When true, the "new assembly" composer opens immediately (used by
  /// the shell's + action sheet).
  final bool openComposer;
  const MeetingsScreen({super.key, this.openComposer = false});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  List<Meeting> _meetings = [];
  bool _loading = true;
  StreamSubscription<String>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _load();
    _realtimeSub = realtime.listen({
      'meetings',
      'votes',
      'vote_ballots',
    }, _load);
    if (widget.openComposer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _createMeeting();
      });
    }
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await api.get('/api/meetings');
      if (!mounted) return;
      setState(() {
        _meetings = ((data['meetings'] ?? []) as List)
            .map((m) => Meeting.fromJson(m))
            .toList();
        _loading = false;
      });
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _castVote(Vote vote, List<String> options) async {
    try {
      await api.post('/api/votes/${vote.id}/ballots', {
        'selectedOptions': options,
      });
      if (mounted) _snack(context.l10n.voteRecorded(options.join(', ')));
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _createMeeting() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NewMeetingScreen()),
    );
    if (created == true) await _load();
  }

  Future<void> _publishSummary(Meeting m) async {
    _snack(context.l10n.aiWritingSummary);
    try {
      await api.post('/api/meetings/${m.id}/summary');
      if (mounted) _snack(context.l10n.summaryPublished);
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final isVaad = session.user?.isVaad ?? false;
    final myApartment = session.user?.apartmentId;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.assembliesAndVoting,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: isVaad
          ? FloatingActionButton.extended(
              heroTag: 'meetings-fab',
              backgroundColor: DiraColors.brick,
              foregroundColor: DiraColors.creamCard,
              onPressed: _createMeeting,
              icon: const Icon(Icons.add),
              label: Text(l10n.newAssembly),
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DiraColors.brick),
            )
          : _meetings.isEmpty
          ? _EmptyMeetingsState(
              isVaad: isVaad,
              onCreate: _createMeeting,
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: DiraColors.brick,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _meetings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final m = _meetings[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (m.isClosed)
                                const Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: DiraColors.inkSoft,
                                ),
                            ],
                          ),
                          Text(
                            '${DateFormat('EEEE, d MMM yyyy · HH:mm', locale).format(m.meetingDate.toLocal())}'
                            '${m.location != null ? ' · ${m.location}' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: DiraColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(m.agenda),
                          for (final vote in m.votes) ...[
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    vote.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (vote.allowMultiple)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DiraColors.goldLight,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      l10n.multiChoiceChip,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: DiraColors.goldDark,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (vote.isActive &&
                                !m.isClosed &&
                                myApartment != null &&
                                !vote.votedApartments.contains(myApartment))
                              _VotePanel(
                                vote: vote,
                                onCast: (options) => _castVote(vote, options),
                              )
                            else
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: vote.options
                                    .map(
                                      (o) => Chip(
                                        backgroundColor: DiraColors.sageLight,
                                        label: Text(
                                          '$o: ${vote.tally[o] ?? 0}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                          if (isVaad && !m.isClosed) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _publishSummary(m),
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: Text(l10n.closeAndPublish),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// Ballot casting UI. Single-answer polls cast on tap; multi-answer
/// polls toggle selections and submit with a button (WhatsApp style).
class _VotePanel extends StatefulWidget {
  final Vote vote;
  final void Function(List<String> options) onCast;
  const _VotePanel({required this.vote, required this.onCast});

  @override
  State<_VotePanel> createState() => _VotePanelState();
}

class _VotePanelState extends State<_VotePanel> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final vote = widget.vote;
    if (!vote.allowMultiple) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: vote.options
            .map(
              (o) => OutlinedButton(
                onPressed: () => widget.onCast([o]),
                child: Text(o),
              ),
            )
            .toList(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: vote.options
              .map(
                (o) => FilterChip(
                  label: Text(o),
                  selected: _selected.contains(o),
                  selectedColor: DiraColors.sageLight,
                  checkmarkColor: DiraColors.sageDark,
                  onSelected: (v) => setState(
                    () => v ? _selected.add(o) : _selected.remove(o),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _selected.isEmpty
              ? null
              : () => widget.onCast(_selected.toList()),
          icon: const Icon(Icons.how_to_vote_outlined, size: 18),
          label: Text(context.l10n.submitVote),
        ),
      ],
    );
  }
}

/// Friendly first-run state for the assemblies tab.
class _EmptyMeetingsState extends StatelessWidget {
  final bool isVaad;
  final VoidCallback onCreate;
  const _EmptyMeetingsState({required this.isVaad, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: DiraColors.sageLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 48,
                color: DiraColors.sageDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.meetingsEmptyTitle,
              textAlign: TextAlign.center,
              style: heading(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.meetingsEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DiraColors.inkSoft,
                fontSize: 14,
                height: 1.55,
              ),
            ),
            if (isVaad) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: Text(l10n.newAssembly),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One agenda item being drafted: a discussion topic, optionally with a
/// WhatsApp-style poll attached (custom answers, single or multiple).
class _DraftItem {
  final String title;
  final bool withVote;
  final List<String> options;
  final bool allowMultiple;
  _DraftItem(
    this.title,
    this.withVote, {
    this.options = const [],
    this.allowMultiple = false,
  });
}

/// Full-screen assembly composer, following the Buildingo design:
/// date + time boxes, location, then numbered agenda items each tagged
/// as a discussion or a vote.
class NewMeetingScreen extends StatefulWidget {
  const NewMeetingScreen({super.key});

  @override
  State<NewMeetingScreen> createState() => _NewMeetingScreenState();
}

class _NewMeetingScreenState extends State<NewMeetingScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _newItem = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  final List<_DraftItem> _items = [];
  bool _newItemVote = false;

  /// Poll being drafted for the current item (WhatsApp style).
  final List<TextEditingController> _optionCtrls = [];
  bool _newItemMulti = false;
  bool _busy = false;
  String? _error;

  bool get _valid => _items.isNotEmpty;

  List<String> get _draftOptions => [
    for (final c in _optionCtrls)
      if (c.text.trim().isNotEmpty) c.text.trim(),
  ];

  /// A vote item needs at least two non-empty answers.
  bool get _newItemReady =>
      _newItem.text.trim().length >= 2 &&
      (!_newItemVote || _draftOptions.length >= 2);

  void _toggleVote(bool on) {
    setState(() {
      _newItemVote = on;
      if (on && _optionCtrls.isEmpty) {
        final l10n = context.l10n;
        // Classic default, fully editable — like a prefilled WhatsApp poll.
        _optionCtrls.addAll([
          TextEditingController(text: l10n.voteYes),
          TextEditingController(text: l10n.voteNo),
        ]);
      }
    });
  }

  DateTime get _meetingDateTime => DateTime(
    _date.year,
    _date.month,
    _date.day,
    _time.hour,
    _time.minute,
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _addItem() {
    final text = _newItem.text.trim();
    if (!_newItemReady) return;
    setState(() {
      _items.add(
        _DraftItem(
          text,
          _newItemVote,
          options: _newItemVote ? _draftOptions : const [],
          allowMultiple: _newItemVote && _newItemMulti,
        ),
      );
      _newItem.clear();
      _newItemVote = false;
      _newItemMulti = false;
      for (final c in _optionCtrls) {
        c.dispose();
      }
      _optionCtrls.clear();
    });
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final title = _title.text.trim().isEmpty
          ? l10n.residentsAssembly
          : _title.text.trim();
      final agenda = [
        for (final (i, item) in _items.indexed) '${i + 1}. ${item.title}',
      ].join('\n');
      await api.post('/api/meetings', {
        'title': title,
        'agenda': agenda,
        'meetingDate': _meetingDateTime.toIso8601String(),
        if (_location.text.trim().isNotEmpty)
          'location': _location.text.trim(),
        'votes': [
          for (final item in _items.where((x) => x.withVote))
            {
              'title': item.title,
              'options': item.options.length >= 2
                  ? item.options
                  : [l10n.voteYes, l10n.voteNo, l10n.voteAbstain],
              'allowMultiple': item.allowMultiple,
            },
        ],
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  InputDecoration _boxDecoration({String? label, String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: DiraColors.ink.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DiraColors.brick, width: 1.5),
        ),
      );

  Widget _pickerBox({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: DiraColors.creamDeep,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(icon, size: 18, color: DiraColors.inkSoft),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newAssembly)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _title,
            decoration: _boxDecoration(
              label: l10n.titleLabel,
              hint: l10n.residentsAssembly,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _pickerBox(
                  icon: Icons.calendar_month_outlined,
                  text: DateFormat('dd/MM/yyyy', locale).format(_date),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _pickerBox(
                  icon: Icons.access_time_rounded,
                  text: _time.format(context),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: _boxDecoration(
              label: l10n.meetingLocationLabel,
              hint: l10n.locLobby,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l10n.agendaItems,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          if (_items.isEmpty)
            Text(
              l10n.agendaItemsHint,
              style: const TextStyle(
                color: DiraColors.inkSoft,
                fontSize: 13,
              ),
            ),
          for (final (i, item) in _items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: DiraColors.terracottaSoft,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: DiraColors.brickDark,
                      ),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.withVote
                              ? DiraColors.goldLight
                              : DiraColors.creamDeep,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.withVote
                              ? [
                                  l10n.voteChip,
                                  if (item.options.isNotEmpty)
                                    l10n.optionsCount(
                                      '${item.options.length}',
                                    ),
                                  if (item.allowMultiple)
                                    l10n.multiChoiceChip,
                                ].join(' · ')
                              : l10n.discussionChip,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: item.withVote
                                ? DiraColors.goldDark
                                : DiraColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: DiraColors.inkSoft,
                    ),
                    onPressed: () => setState(() => _items.removeAt(i)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          TextField(
            controller: _newItem,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _addItem(),
            decoration: _boxDecoration(hint: l10n.newAgendaItem),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilterChip(
                avatar: Icon(
                  Icons.how_to_vote_outlined,
                  size: 17,
                  color: _newItemVote
                      ? DiraColors.goldDark
                      : DiraColors.inkSoft,
                ),
                label: Text(l10n.withVote),
                selected: _newItemVote,
                selectedColor: DiraColors.goldLight,
                onSelected: _toggleVote,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _newItemReady ? _addItem : null,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addItem),
              ),
            ],
          ),
          // WhatsApp-style poll editor: editable answers + multi toggle.
          if (_newItemVote) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              decoration: BoxDecoration(
                color: DiraColors.creamCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DiraColors.goldLight, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pollOptionsLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final (i, c) in _optionCtrls.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: c,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: l10n.optionHint('${i + 1}'),
                                isDense: true,
                                filled: true,
                                fillColor: DiraColors.creamDeep,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          if (_optionCtrls.length > 2)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.close,
                                size: 17,
                                color: DiraColors.inkSoft,
                              ),
                              onPressed: () => setState(() {
                                _optionCtrls.removeAt(i).dispose();
                              }),
                            ),
                        ],
                      ),
                    ),
                  if (_optionCtrls.length < 12)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => setState(
                          () => _optionCtrls.add(TextEditingController()),
                        ),
                        icon: const Icon(Icons.add, size: 17),
                        label: Text(l10n.addOption),
                      ),
                    ),
                  SwitchListTile(
                    value: _newItemMulti,
                    onChanged: (v) => setState(() => _newItemMulti = v),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeTrackColor: DiraColors.sageDark,
                    title: Text(
                      l10n.allowMultipleAnswers,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _busy || !_valid ? null : _create,
            child: Text(_busy ? l10n.pleaseWait : l10n.createMeetingCta),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: DiraColors.brick),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
