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
  const MeetingsScreen({super.key});

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

  Future<void> _castVote(Vote vote, String option) async {
    try {
      await api.post('/api/votes/${vote.id}/ballots', {
        'selectedOption': option,
      });
      if (mounted) _snack(context.l10n.voteRecorded(option));
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _createMeeting() async {
    final title = TextEditingController();
    final agenda = TextEditingController();
    final voteTitle = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.newAssembly),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: InputDecoration(labelText: ctx.l10n.titleLabel),
              ),
              TextField(
                controller: agenda,
                maxLines: 3,
                decoration: InputDecoration(labelText: ctx.l10n.agenda),
              ),
              TextField(
                controller: voteTitle,
                decoration: InputDecoration(
                  labelText: ctx.l10n.voteQuestionOptional,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.create),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final l10n = context.l10n;
    try {
      await api.post('/api/meetings', {
        'title': title.text.trim(),
        'agenda': agenda.text.trim(),
        'meetingDate': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        if (voteTitle.text.trim().isNotEmpty)
          'votes': [
            {
              'title': voteTitle.text.trim(),
              'options': [l10n.voteYes, l10n.voteNo, l10n.voteAbstain],
            },
          ],
      });
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
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
                            Text(
                              vote.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (vote.isActive &&
                                !m.isClosed &&
                                myApartment != null &&
                                !vote.votedApartments.contains(myApartment))
                              Wrap(
                                spacing: 8,
                                children: vote.options
                                    .map(
                                      (o) => OutlinedButton(
                                        onPressed: () => _castVote(vote, o),
                                        child: Text(o),
                                      ),
                                    )
                                    .toList(),
                              )
                            else
                              Wrap(
                                spacing: 12,
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
