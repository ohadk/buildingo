import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../core/ticket_categories.dart';
import '../core/tickets_controller.dart';
import '../l10n/l10n.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/status_pill.dart';
import '../widgets/ticket_timeline.dart';
import '../widgets/pending_ticket_card.dart';
import '../widgets/ticket_photo.dart';
import '../widgets/vault_file_viewer.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<Ticket> _tickets = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<String>? _realtimeSub;
  Timer? _pollTimer;
  /// Optimistic status while PATCH is in flight.
  final Map<String, String> _statusOverrides = {};
  final Set<String> _statusSaving = {};

  @override
  void initState() {
    super.initState();
    _load();
    _realtimeSub = realtime.listen({
      'tickets',
      'ticket_events',
    }, () => _load(silent: true));
    // Keep tenant/vaad in sync when Realtime is slow or unavailable.
    _pollTimer = Timer.periodic(
      Duration(seconds: realtimeEnabled ? 12 : 4),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final results = await api.get('/api/tickets');
      if (!mounted) return;
      setState(() {
        _tickets = ((results['tickets'] ?? []) as List)
            .map((t) => Ticket.fromJson(t))
            .toList();
        _loading = false;
        _error = null;
        // Drop overrides once server catches up.
        _statusOverrides.removeWhere((id, status) {
          final match = _tickets.where((t) => t.id == id).firstOrNull;
          return match == null || match.status == status;
        });
      });
    } on ApiException catch (e) {
      if (mounted && !silent) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _approveAndDispatch(Ticket ticket) async {
    // AI vendor dispatch ships in the next release; MVP is manual workflow.
    _snack(context.l10n.agentDispatchComingSoon);
  }

  Ticket _displayTicket(Ticket t) {
    final override = _statusOverrides[t.id];
    if (override == null || override == t.status) return t;
    return t.copyWith(status: override);
  }

  String _effectiveStatus(Ticket t) =>
      _statusOverrides[t.id] ?? t.status;

  Future<void> _setStatus(Ticket ticket, String status) async {
    final current = _effectiveStatus(ticket);
    final currentUi = ticket.copyWith(status: current).displayStatus;
    final nextUi = status == 'approved' ? 'in_progress' : status;

    if (currentUi == nextUi) {
      if (nextUi == 'resolved') {
        await _openCostSheet(_displayTicket(ticket));
      } else if (nextUi == 'in_progress') {
        await _openProgressSheet(_displayTicket(ticket));
      }
      return;
    }

    final previous = current;
    final patchStatus = status == 'approved' ? 'in_progress' : status;
    setState(() {
      _statusOverrides[ticket.id] = patchStatus;
      _statusSaving.add(ticket.id);
    });

    try {
      await api.patch('/api/tickets/${ticket.id}', {'status': patchStatus});
      if (!mounted) return;
      setState(() => _statusSaving.remove(ticket.id));
      unawaited(
        _load(silent: true).whenComplete(() {
          if (mounted) {
            setState(() => _statusOverrides.remove(ticket.id));
          }
        }),
      );
      if (patchStatus == 'in_progress') {
        await _openProgressSheet(_displayTicket(ticket));
      } else if (patchStatus == 'resolved') {
        await _openCostSheet(_displayTicket(ticket));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusSaving.remove(ticket.id);
        if (previous == ticket.status) {
          _statusOverrides.remove(ticket.id);
        } else {
          _statusOverrides[ticket.id] = previous;
        }
      });
      _snack(e.message);
    }
  }

  Future<void> _openProgressSheet(Ticket ticket) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TicketProgressSheet(ticket: ticket),
    );
    if (saved == true && mounted) {
      _snack(context.l10n.ticketProgressSaved);
      await _load(silent: true);
    }
  }

  Future<void> _openEditSheet(Ticket ticket) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TicketEditSheet(ticket: ticket),
    );
    if (saved == true && mounted) {
      _snack(context.l10n.ticketEdited);
      await _load(silent: true);
    }
  }

  Future<void> _openCostSheet(Ticket ticket) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TicketCostSheet(ticket: ticket),
    );
    if (saved == true && mounted) {
      _snack(context.l10n.ticketCostSaved);
      await _load();
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isVaad = context.watch<SessionController>().user?.isVaad ?? false;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.maintenance,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'maintenance-fab',
        backgroundColor: DiraColors.brick,
        foregroundColor: DiraColors.creamCard,
        tooltip: l10n.newReport,
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const NewTicketScreen()))
            .then((_) => _load(silent: true)),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DiraColors.brick),
            )
          : _error != null
          ? Center(child: Text(_error!))
          : _buildTicketList(context, isVaad: isVaad, locale: locale),
    );
  }

  Future<void> _openTicketDetail(Ticket ticket) async {
    final session = context.read<SessionController>();
    final isVaad = session.user?.isVaad ?? false;
    final canEdit =
        isVaad ||
        (session.user?.id != null && session.user!.id == ticket.reportedBy);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TicketDetailSheet(
        ticketId: ticket.id,
        initial: _displayTicket(ticket),
        isVaad: isVaad,
        canEdit: canEdit,
        resolveTicket: (id) {
          final t = _tickets.where((x) => x.id == id).firstOrNull;
          return t == null ? null : _displayTicket(t);
        },
        isSaving: (id) => _statusSaving.contains(id),
        onSetStatus: _setStatus,
        onDispatch: _approveAndDispatch,
        onCost: _openCostSheet,
        onProgress: _openProgressSheet,
        onEdit: _openEditSheet,
        onDelete: _deleteTicket,
        onRefresh: () => _load(silent: true),
      ),
    );
    if (mounted) await _load(silent: true);
  }

  Future<void> _deleteTicket(Ticket ticket) async {
    await api.delete('/api/tickets/${ticket.id}');
    if (!mounted) return;
    setState(() => _tickets.removeWhere((t) => t.id == ticket.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.ticketDeleted)),
    );
  }

  Widget _buildTicketList(
    BuildContext context, {
    required bool isVaad,
    required String locale,
  }) {
    final l10n = context.l10n;
    final pending = context.watch<TicketsController>().pending;
    final pendingIds =
        pending.map((p) => p.createdId).whereType<String>().toSet();
    final tickets =
        _tickets.where((t) => !pendingIds.contains(t.id)).toList();
    final empty = pending.isEmpty && tickets.isEmpty;

    return RefreshIndicator(
      onRefresh: () => _load(),
      color: DiraColors.brick,
      child: empty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 110),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor:
                            DiraColors.brick.withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.home_repair_service_outlined,
                          size: 34,
                          color: DiraColors.brick,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.noTicketsYet,
                        textAlign: TextAlign.center,
                        style: heading(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noTicketsHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: DiraColors.inkSoft,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: pending.length + tickets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i < pending.length) {
                  return Card(
                    child: PendingTicketCard(pending: pending[i]),
                  );
                }
                final t = tickets[i - pending.length];
                final display = _displayTicket(t);
                return _TicketListTile(
                  ticket: display,
                  locale: locale,
                  onTap: () => _openTicketDetail(t),
                );
              },
            ),
    );
  }
}

class _TicketListTile extends StatelessWidget {
  final Ticket ticket;
  final String locale;
  final VoidCallback onTap;

  const _TicketListTile({
    required this.ticket,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasImage = ticket.imageUrls.isNotEmpty;
    final progress = ticket.progressNote?.trim();
    final hasProgress = progress != null && progress.isNotEmpty;
    final cost = ticket.costAmount;
    final created = DateFormat('d.M.yy', locale).format(ticket.createdAt.toLocal());
    final fixDate = ticket.fixDate;
    final fixLabel = fixDate == null
        ? null
        : DateFormat('d.M.yy', locale).format(fixDate.toLocal());

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryGlyph.forTicket(
                categoryId: ticket.category,
                title: ticket.title,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.ticketCreatedOn(created),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DiraColors.inkSoft,
                      ),
                    ),
                    if (fixLabel != null || cost != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (fixLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: DiraColors.sagePale,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.event_outlined,
                                    size: 13,
                                    color: DiraColors.sageDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.ticketExpectedBy(fixLabel),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: DiraColors.sageDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (cost != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  NumberFormat.currency(
                                    symbol: '₪',
                                    decimalDigits: 0,
                                  ).format(cost),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: DiraColors.brick,
                                  ),
                                ),
                                if (ticket.receiptUrl != null) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.receipt_outlined,
                                    size: 14,
                                    color: DiraColors.brick,
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusPill.ticket(
                      context,
                      ticket.displayStatus,
                      compact: true,
                    ),
                    if (hasProgress) ...[
                      const SizedBox(height: 4),
                      Text(
                        progress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: DiraColors.sageDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: TicketPhoto(
                      url: ticket.imageUrls.first,
                      height: 56,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketDetailSheet extends StatefulWidget {
  final String ticketId;
  final Ticket initial;
  final bool isVaad;
  final bool canEdit;
  final Ticket? Function(String id) resolveTicket;
  final bool Function(String id) isSaving;
  final Future<void> Function(Ticket ticket, String status) onSetStatus;
  final Future<void> Function(Ticket ticket) onDispatch;
  final Future<void> Function(Ticket ticket) onCost;
  final Future<void> Function(Ticket ticket) onProgress;
  final Future<void> Function(Ticket ticket) onEdit;
  final Future<void> Function(Ticket ticket) onDelete;
  final Future<void> Function() onRefresh;

  const _TicketDetailSheet({
    required this.ticketId,
    required this.initial,
    required this.isVaad,
    required this.canEdit,
    required this.resolveTicket,
    required this.isSaving,
    required this.onSetStatus,
    required this.onDispatch,
    required this.onCost,
    required this.onProgress,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  State<_TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends State<_TicketDetailSheet> {
  late Ticket _ticket = widget.initial;
  StreamSubscription<String>? _sub;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _sub = realtime.listen({'tickets', 'ticket_events'}, _syncFromParent);
    _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
      await widget.onRefresh();
      _syncFromParent();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  void _syncFromParent() {
    final next = widget.resolveTicket(widget.ticketId);
    if (next != null && mounted) {
      setState(() => _ticket = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final saving = widget.isSaving(_ticket.id);
    final status = _ticket.displayStatus;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
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
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryGlyph.forTicket(
                    categoryId: _ticket.category,
                    title: _ticket.title,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _ticket.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusPill.ticket(context, status),
                      ],
                    ),
                  ),
                  if (widget.canEdit) ...[
                    IconButton(
                      tooltip: l10n.ticketEdit,
                      onPressed: () async {
                        await widget.onEdit(_ticket);
                        await widget.onRefresh();
                        _syncFromParent();
                      },
                      icon: const Icon(Icons.edit_outlined),
                      color: DiraColors.brick,
                    ),
                    IconButton(
                      tooltip: l10n.deleteTicket,
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: Text(l10n.deleteTicket),
                            content: Text(l10n.deleteTicketConfirm),
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
                        if (ok != true || !mounted) return;
                        try {
                          await widget.onDelete(_ticket);
                          if (mounted) Navigator.pop(context);
                        } on ApiException catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      color: DiraColors.brickDark,
                    ),
                  ],
                ],
              ),
              if (_ticket.description.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _ticket.description,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                    color: DiraColors.inkSoft,
                  ),
                ),
              ],
              if (_ticket.location != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: DiraColors.inkSoft,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _ticket.location!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DiraColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ],
              if (_ticket.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 14),
                TicketPhotoCarousel(urls: _ticket.imageUrls, height: 220),
              ],
              const SizedBox(height: 10),
              Text(
                '${_ticket.reporterName ?? l10n.resident} · '
                '${DateFormat('d MMM yyyy', locale).format(_ticket.createdAt.toLocal())}'
                '${_ticket.vendorName != null ? ' · ${l10n.agentTo(_ticket.vendorName!)}' : ''}',
                style: const TextStyle(fontSize: 12.5, color: DiraColors.inkSoft),
              ),
              // Cost + receipt visible to every resident once Vaad records them.
              if (_ticket.costAmount != null || _ticket.receiptUrl != null) ...[
                const SizedBox(height: 12),
                _TicketCostRow(ticket: _ticket),
              ],
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: DiraColors.sage,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TicketTimeline(
                      ticket: _ticket,
                      saving: saving,
                      onStageTap: widget.isVaad
                          ? (s) async {
                              final future = widget.onSetStatus(_ticket, s);
                              await Future<void>.delayed(Duration.zero);
                              _syncFromParent();
                              await future;
                              await widget.onRefresh();
                              _syncFromParent();
                            }
                          : null,
                    ),
                    if (widget.isVaad) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              l10n.ticketTapStatusHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.isVaad) ...[
                const SizedBox(height: 14),
                if (status == 'open') ...[
                  ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            await widget.onDispatch(_ticket);
                            _syncFromParent();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DiraColors.goldDark,
                      foregroundColor: DiraColors.creamCard,
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      '${l10n.approveAndDispatch} · ${l10n.comingSoon}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            await widget.onSetStatus(_ticket, 'in_progress');
                            await widget.onRefresh();
                            _syncFromParent();
                          },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.statusInProgress),
                  ),
                ],
                if (status == 'in_progress') ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      await widget.onProgress(_ticket);
                      await widget.onRefresh();
                      _syncFromParent();
                    },
                    icon: const Icon(Icons.update),
                    label: Text(l10n.ticketUpdateProgress),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            await widget.onSetStatus(_ticket, 'resolved');
                            await widget.onRefresh();
                            _syncFromParent();
                          },
                    icon: const Icon(Icons.check),
                    label: Text(l10n.markResolved),
                  ),
                ],
                if (status == 'resolved')
                  OutlinedButton.icon(
                    onPressed: () async {
                      await widget.onCost(_ticket);
                      await widget.onRefresh();
                      _syncFromParent();
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(
                      _ticket.costAmount == null
                          ? l10n.ticketAddRepairCost
                          : l10n.ticketEditRepairCost,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketEditSheet extends StatefulWidget {
  final Ticket ticket;
  const _TicketEditSheet({required this.ticket});

  @override
  State<_TicketEditSheet> createState() => _TicketEditSheetState();
}

class _ExistingTicketPhoto {
  final String path;
  final String url;
  const _ExistingTicketPhoto({required this.path, required this.url});
}

class _TicketEditSheetState extends State<_TicketEditSheet> {
  late final _title = TextEditingController(text: widget.ticket.title);
  late final _description =
      TextEditingController(text: widget.ticket.description);
  late final _location =
      TextEditingController(text: widget.ticket.location ?? '');
  late TicketCategory _category = TicketCategory.byId(widget.ticket.category);
  late final List<_ExistingTicketPhoto> _keptPhotos;
  final List<PickedAttachment> _newPhotos = [];
  bool _busy = false;
  String? _error;

  static const _maxPhotos = 8;

  @override
  void initState() {
    super.initState();
    final paths = widget.ticket.imagePaths;
    final urls = widget.ticket.imageUrls;
    final n = paths.length > urls.length ? paths.length : urls.length;
    _keptPhotos = [
      for (var i = 0; i < n; i++)
        if (i < paths.length && paths[i].isNotEmpty)
          _ExistingTicketPhoto(
            path: paths[i],
            url: i < urls.length ? urls[i] : '',
          ),
    ];
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  int get _photoCount => _keptPhotos.length + _newPhotos.length;

  Future<void> _pickPhotos() async {
    if (_photoCount >= _maxPhotos) return;
    final picked = await pickAttachments(context, multiple: true);
    if (picked.isEmpty) return;
    setState(() {
      _newPhotos.addAll(picked);
      final overflow = _photoCount - _maxPhotos;
      if (overflow > 0) {
        _newPhotos.removeRange(_newPhotos.length - overflow, _newPhotos.length);
      }
    });
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final title = _title.text.trim();
    if (title.length < 3) {
      setState(() => _error = context.l10n.whatHappened);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final paths = <String>[for (final p in _keptPhotos) p.path];
      for (final photo in _newPhotos) {
        final res = await api.uploadFile(
          '/api/tickets/upload',
          bytes: photo.bytes,
          filename: photo.name,
        );
        final path = res['imagePath'] as String?;
        if (path != null && path.isNotEmpty) paths.add(path);
      }
      final loc = _location.text.trim();
      await api.patch('/api/tickets/${widget.ticket.id}', {
        'title': title,
        'description': _description.text.trim(),
        'category': _category.id,
        'location': loc.isEmpty ? null : loc,
        'imagePaths': paths,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _busy = false;
        });
      }
    }
  }

  Widget _photoThumb({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 80, height: 80, child: child),
        ),
        Positioned(
          top: 2,
          left: 2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canAdd = _photoCount < _maxPhotos;
    final thumbCount = _photoCount + (canAdd ? 1 : 0);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.ticketEdit, style: heading(fontSize: 20)),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.whatHappened),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.details),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              decoration: InputDecoration(labelText: l10n.ticketLocationLabel),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in TicketCategory.all)
                  ChoiceChip(
                    avatar: Icon(cat.icon, size: 16, color: cat.color),
                    label: Text(cat.label(l10n)),
                    selected: _category.id == cat.id,
                    onSelected: (v) {
                      if (v) setState(() => _category = cat);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_photoCount == 0)
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickPhotos,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(l10n.addMorePhotos),
              )
            else
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: thumbCount,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    if (canAdd && i == _photoCount) {
                      return InkWell(
                        onTap: _busy ? null : _pickPhotos,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DiraColors.creamDeep),
                            color: DiraColors.creamCard,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            color: DiraColors.brick,
                          ),
                        ),
                      );
                    }
                    if (i < _keptPhotos.length) {
                      final photo = _keptPhotos[i];
                      return _photoThumb(
                        onRemove: () =>
                            setState(() => _keptPhotos.removeAt(i)),
                        child: photo.url.isEmpty
                            ? const ColoredBox(
                                color: DiraColors.creamCard,
                                child: Icon(Icons.image_outlined),
                              )
                            : TicketPhoto(
                                url: photo.url,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                      );
                    }
                    final ni = i - _keptPhotos.length;
                    return _photoThumb(
                      onRemove: () => setState(() => _newPhotos.removeAt(ni)),
                      child: Image.memory(
                        _newPhotos[ni].bytes,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
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

class _TicketProgressSheet extends StatefulWidget {
  final Ticket ticket;
  const _TicketProgressSheet({required this.ticket});

  @override
  State<_TicketProgressSheet> createState() => _TicketProgressSheetState();
}

class _TicketProgressSheetState extends State<_TicketProgressSheet> {
  late final _note = TextEditingController(
    text: widget.ticket.progressNote ?? '',
  );
  late DateTime? _fixDate;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fixDate = widget.ticket.fixDate;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fixDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fixDate = picked);
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final note = _note.text.trim();
      await api.patch('/api/tickets/${widget.ticket.id}', {
        'status': 'in_progress',
        'progressNote': note.isEmpty ? null : note,
        'fixDate': _fixDate == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_fixDate!),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final chips = [
      l10n.ticketProgressOpenedProvider,
      l10n.ticketProgressPartsOrdered,
      l10n.ticketProgressScheduled,
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.ticketUpdateProgress, style: heading(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              l10n.ticketProgressNoteHint,
              style: const TextStyle(color: DiraColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in chips)
                  ActionChip(
                    label: Text(chip, style: const TextStyle(fontSize: 12.5)),
                    onPressed: () => setState(() => _note.text = chip),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.ticketProgressNote),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.ticketFixDateLabel),
              subtitle: Text(
                _fixDate == null
                    ? '—'
                    : DateFormat('d MMM yyyy', locale).format(_fixDate!),
              ),
              trailing: IconButton(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
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

class _TicketCostRow extends StatelessWidget {
  final Ticket ticket;
  const _TicketCostRow({required this.ticket});

  Future<void> _openReceipt(BuildContext context) async {
    final url = ticket.receiptUrl;
    if (url == null) return;
    // Prefer path from proxy URL when present.
    final uri = Uri.tryParse(url);
    final path = uri?.queryParameters['path'];
    final bucket = uri?.queryParameters['bucket'] ?? 'receipts';
    if (path != null && path.isNotEmpty) {
      await openVaultFile(
        context,
        bucket: bucket,
        path: path,
        title: context.l10n.viewReceipt,
      );
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Flexible(
              child: TicketPhoto(url: url, height: 420, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final amount = ticket.costAmount;
    final formatted = amount == null
        ? null
        : NumberFormat.currency(symbol: '₪', decimalDigits: 0).format(amount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DiraColors.creamDeep),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 18,
            color: DiraColors.brick,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              formatted ?? l10n.ticketRepairCost,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          if (ticket.receiptUrl != null)
            InkWell(
              onTap: () => _openReceipt(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.receipt_outlined,
                    size: 16,
                    color: DiraColors.brick,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.viewReceipt,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: DiraColors.brick,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TicketCostSheet extends StatefulWidget {
  final Ticket ticket;
  const _TicketCostSheet({required this.ticket});

  @override
  State<_TicketCostSheet> createState() => _TicketCostSheetState();
}

class _TicketCostSheetState extends State<_TicketCostSheet> {
  late final _amount = TextEditingController(
    text: widget.ticket.costAmount == null
        ? ''
        : widget.ticket.costAmount!.truncateToDouble() == widget.ticket.costAmount
            ? widget.ticket.costAmount!.toStringAsFixed(0)
            : widget.ticket.costAmount!.toStringAsFixed(2),
  );
  PickedAttachment? _receipt;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picked = await pickAttachments(context, allowPdf: true);
    final file = picked.firstOrNull;
    if (file != null) setState(() => _receipt = file);
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final parsed = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (parsed == null || parsed < 0) {
      setState(() => _error = context.l10n.ticketRepairCostHint);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String? receiptPath;
      final receipt = _receipt;
      if (receipt != null) {
        final res = await api.uploadFile(
          '/api/expenses/upload',
          bytes: receipt.bytes,
          filename: receipt.name,
        );
        receiptPath = res['receiptPath'] as String?;
      }
      await api.patch('/api/tickets/${widget.ticket.id}', {
        'costAmount': parsed,
        if (receiptPath != null) 'receiptPath': receiptPath,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.ticketRepairCost, style: heading(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              l10n.ticketRepairCostHint,
              style: const TextStyle(color: DiraColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: l10n.amount,
                prefixText: '₪ ',
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickReceipt,
              icon: Icon(
                _receipt == null
                    ? Icons.attach_file_rounded
                    : Icons.check_circle,
                size: 18,
                color: _receipt == null
                    ? DiraColors.brick
                    : DiraColors.sageDark,
              ),
              label: Text(
                _receipt?.name ??
                    (widget.ticket.receiptUrl != null
                        ? l10n.receiptAttached
                        : l10n.attachReceipt),
              ),
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

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _otherLocation = TextEditingController();

  /// Selected location key: a common-area key, 'floor', 'other', or null.
  String? _locationKey;
  int _floor = 1;
  TicketCategory _category = TicketCategory.other;
  final List<PickedAttachment> _photos = [];
  String? _error;

  static const _commonAreas = <(String, IconData)>[
    ('lobby', Icons.meeting_room_outlined),
    ('stairwell', Icons.stairs_outlined),
    ('elevator', Icons.elevator_outlined),
    ('parking', Icons.local_parking_outlined),
    ('roof', Icons.roofing_outlined),
    ('yard', Icons.grass_outlined),
  ];

  String _areaLabel(BuildContext context, String key) {
    final l10n = context.l10n;
    return switch (key) {
      'lobby' => l10n.locLobby,
      'stairwell' => l10n.locStairwell,
      'elevator' => l10n.locElevator,
      'parking' => l10n.locParking,
      'roof' => l10n.locRoof,
      'yard' => l10n.locYard,
      _ => key,
    };
  }

  String? get _locationText {
    final key = _locationKey;
    if (key == null) return null;
    if (key == 'floor') return context.l10n.floorN('$_floor');
    if (key == 'other') {
      final text = _otherLocation.text.trim();
      return text.isEmpty ? null : text;
    }
    return _areaLabel(context, key);
  }

  /// Camera or photo library, via the shared source sheet.
  Future<void> _pickPhotos() async {
    final picked = await pickAttachments(context, multiple: true);
    if (picked.isEmpty) return;
    setState(() {
      _photos.addAll(picked);
      if (_photos.length > 8) {
        _photos.removeRange(8, _photos.length);
      }
    });
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final title = _title.text.trim();
    if (title.length < 3) {
      setState(() => _error = context.l10n.whatHappened);
      return;
    }

    final session = context.read<SessionController>();
    final draft = TicketDraft(
      title: title,
      description: _description.text.trim(),
      category: _category.id,
      location: _locationText,
      photos: [
        for (final p in _photos)
          TicketPhotoDraft(bytes: p.bytes, name: p.name),
      ],
      reporterName: session.user?.fullName,
    );

    // Pop immediately; background upload + create shows as optimistic row.
    final inbox = context.read<TicketsController>();
    Navigator.of(context).pop();
    unawaited(inbox.submit(draft));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportAFault)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.ticketCategoryLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in TicketCategory.all)
                ChoiceChip(
                  avatar: Icon(
                    cat.icon,
                    size: 17,
                    color: _category.id == cat.id
                        ? cat.color
                        : DiraColors.inkSoft,
                  ),
                  label: Text(cat.label(l10n)),
                  selected: _category.id == cat.id,
                  selectedColor: cat.color.withValues(alpha: 0.18),
                  onSelected: (v) {
                    if (v) setState(() => _category = cat);
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.whatHappened,
              hintText: l10n.faultHint,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            onChanged: (_) => setState(() {}),
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.details,
              hintText: l10n.detailsHint,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.ticketLocationLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (key, icon) in _commonAreas)
                ChoiceChip(
                  avatar: Icon(
                    icon,
                    size: 17,
                    color: _locationKey == key
                        ? DiraColors.brickDark
                        : DiraColors.inkSoft,
                  ),
                  label: Text(_areaLabel(context, key)),
                  selected: _locationKey == key,
                  onSelected: (v) =>
                      setState(() => _locationKey = v ? key : null),
                ),
              ChoiceChip(
                avatar: Icon(
                  Icons.apartment_outlined,
                  size: 17,
                  color: _locationKey == 'floor'
                      ? DiraColors.brickDark
                      : DiraColors.inkSoft,
                ),
                label: Text(
                  _locationKey == 'floor'
                      ? l10n.floorN('$_floor')
                      : l10n.floorLabel,
                ),
                selected: _locationKey == 'floor',
                onSelected: (v) =>
                    setState(() => _locationKey = v ? 'floor' : null),
              ),
              ChoiceChip(
                avatar: Icon(
                  Icons.edit_location_alt_outlined,
                  size: 17,
                  color: _locationKey == 'other'
                      ? DiraColors.brickDark
                      : DiraColors.inkSoft,
                ),
                label: Text(l10n.locOther),
                selected: _locationKey == 'other',
                onSelected: (v) =>
                    setState(() => _locationKey = v ? 'other' : null),
              ),
            ],
          ),
          if (_locationKey == 'other') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _otherLocation,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.locOther,
                hintText: l10n.locOtherHint,
              ),
            ),
          ],
          if (_locationKey == 'floor') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  onPressed: _floor > 0
                      ? () => setState(() => _floor--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    l10n.floorN('$_floor'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => setState(() => _floor++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          if (_photos.isEmpty)
            OutlinedButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l10n.addMorePhotos),
            )
          else ...[
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length + (_photos.length < 8 ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == _photos.length) {
                    return InkWell(
                      onTap: _pickPhotos,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DiraColors.creamDeep),
                          color: DiraColors.creamCard,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: DiraColors.brick,
                        ),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _photos[i].bytes,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        left: 2,
                        child: InkWell(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _title.text.trim().length < 3 ? null : _submit,
            child: Text(l10n.submitReport),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: DiraColors.brick),
              ),
            ),
        ],
      ),
    );
  }
}
