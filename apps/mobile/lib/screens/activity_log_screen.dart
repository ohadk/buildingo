import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Vaad-facing building activity trail: who joined, voted, paid, opened
/// tickets and so on — fed by the server-side audit log.
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<AuditLog> _logs = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<String>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _load();
    _realtimeSub = realtime.listen({'audit_logs'}, _load);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await api.get('/api/audit-logs');
      if (!mounted) return;
      setState(() {
        _logs = ((data['logs'] ?? []) as List)
            .map((l) => AuditLog.fromJson(l))
            .toList();
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  (IconData, Color, String) _style(BuildContext context, AuditLog log) {
    final l10n = context.l10n;
    return switch (log.action) {
      'tenant_joined' => (
        Icons.person_add_alt_1_rounded,
        DiraColors.sageDark,
        l10n.auditTenantJoined,
      ),
      'join_requested' => (
        Icons.person_search_rounded,
        DiraColors.goldDark,
        l10n.auditJoinRequested,
      ),
      'join_rejected' => (
        Icons.person_off_rounded,
        DiraColors.brick,
        l10n.auditJoinRejected,
      ),
      'ticket_created' => (
        Icons.handyman_rounded,
        DiraColors.goldDark,
        l10n.auditTicketCreated,
      ),
      'ticket_dispatched' => (
        Icons.smart_toy_rounded,
        DiraColors.sageDark,
        l10n.auditTicketDispatched,
      ),
      'ticket_status_changed' => (
        Icons.sync_rounded,
        DiraColors.inkSoft,
        l10n.auditTicketStatus,
      ),
      'meeting_created' => (
        Icons.groups_rounded,
        DiraColors.sageDark,
        l10n.auditMeetingCreated,
      ),
      'meeting_updated' => (
        Icons.edit_outlined,
        DiraColors.goldDark,
        l10n.auditMeetingUpdated,
      ),
      'meeting_deleted' => (
        Icons.delete_outline,
        DiraColors.brick,
        l10n.auditMeetingDeleted,
      ),
      'ticket_deleted' => (
        Icons.delete_outline,
        DiraColors.brick,
        l10n.auditTicketDeleted,
      ),
      'meeting_closed' => (
        Icons.picture_as_pdf_rounded,
        DiraColors.inkSoft,
        l10n.auditMeetingClosed,
      ),
      'vote_cast' => (
        Icons.how_to_vote_rounded,
        DiraColors.goldDark,
        l10n.auditVoteCast,
      ),
      'payment_marked' => (
        Icons.credit_card_rounded,
        DiraColors.sageDark,
        l10n.auditPaymentMarked,
      ),
      'payments_bulk_marked' => (
        Icons.library_add_check_rounded,
        DiraColors.sageDark,
        l10n.auditPaymentsBulk,
      ),
      'expense_added' => (
        Icons.receipt_long_rounded,
        DiraColors.inkSoft,
        l10n.auditExpenseAdded,
      ),
      'announcement_published' => (
        Icons.campaign_rounded,
        DiraColors.goldDark,
        l10n.auditAnnouncement,
      ),
      'announcement_updated' => (
        Icons.edit_outlined,
        DiraColors.goldDark,
        l10n.auditAnnouncementUpdated,
      ),
      'announcement_deleted' => (
        Icons.delete_outline,
        DiraColors.brick,
        l10n.auditAnnouncementDeleted,
      ),
      'vendor_added' => (
        Icons.engineering_rounded,
        DiraColors.sageDark,
        l10n.auditVendorAdded,
      ),
      'vendor_updated' => (
        Icons.engineering_rounded,
        DiraColors.inkSoft,
        l10n.auditVendorUpdated,
      ),
      'vendor_deleted' => (
        Icons.engineering_rounded,
        DiraColors.brick,
        l10n.auditVendorDeleted,
      ),
      'building_created' => (
        Icons.apartment_rounded,
        DiraColors.sageDark,
        l10n.auditBuildingCreated,
      ),
      'vaad_invited' => (
        Icons.mail_rounded,
        DiraColors.goldDark,
        l10n.auditVaadInvited,
      ),
      'tenant_transferred' => (
        Icons.swap_horiz_rounded,
        DiraColors.sageDark,
        l10n.auditTenantTransferred,
      ),
      _ => (Icons.bolt_rounded, DiraColors.inkSoft, log.action),
    };
  }

  String _summary(BuildContext context, AuditLog log) {
    final l10n = context.l10n;
    final d = log.details;
    final parts = <String>[];
    if (d['title'] is String && (d['title'] as String).isNotEmpty) {
      parts.add(d['title']);
    }
    if (d['name'] is String && (d['name'] as String).isNotEmpty) {
      parts.add(d['name']);
    }
    if (d['apartment'] != null) parts.add(l10n.aptTiny('${d['apartment']}'));
    if (d['option'] is String) parts.add(d['option']);
    if (d['vendor'] is String) parts.add(d['vendor']);
    if (d['service'] is String) parts.add(d['service']);
    if (d['amount'] != null) parts.add('₪${d['amount']}');
    if (d['month'] != null && d['year'] != null) {
      parts.add('${d['month']}/${d['year']}');
    }
    if (d['status'] is String) {
      parts.add(d['status'] == 'paid' ? l10n.statusPaid : l10n.statusUnpaid);
    }
    if (d['location'] is String) parts.add(d['location']);
    // Holder transfer: outgoing names → incoming name.
    if (d['outgoing'] is List && (d['outgoing'] as List).isNotEmpty) {
      final out = (d['outgoing'] as List).whereType<String>().join(', ');
      final inc = d['incoming'] is String ? d['incoming'] as String : '';
      parts.add(inc.isEmpty ? out : '$out ← $inc');
    } else if (d['incoming'] is String) {
      parts.add(d['incoming'] as String);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    // Group by calendar day, newest first.
    final groups = <String, List<AuditLog>>{};
    for (final log in _logs) {
      final key = DateFormat(
        'EEEE, d MMMM',
        locale,
      ).format(log.createdAt.toLocal());
      groups.putIfAbsent(key, () => []).add(log);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.activityLog,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DiraColors.brick),
            )
          : _error != null
          ? Center(child: Text(_error!))
          : _logs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: DiraColors.goldLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: DiraColors.goldDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.activityEmptyTitle,
                      textAlign: TextAlign.center,
                      style: heading(fontSize: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.activityEmptyBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: DiraColors.inkSoft,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: DiraColors.brick,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final entry in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 6),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: DiraColors.inkSoft,
                        ),
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [
                          for (final (i, log) in entry.value.indexed) ...[
                            if (i > 0)
                              const Divider(height: 1, indent: 62, endIndent: 16),
                            Builder(
                              builder: (context) {
                                final (icon, color, label) = _style(
                                  context,
                                  log,
                                );
                                final summary = _summary(context, log);
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 17,
                                    backgroundColor: color.withValues(
                                      alpha: 0.14,
                                    ),
                                    child: Icon(icon, size: 18, color: color),
                                  ),
                                  title: Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      if (summary.isNotEmpty) summary,
                                      if (log.actorName != null) log.actorName!,
                                    ].join(' — '),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: DiraColors.inkSoft,
                                    ),
                                  ),
                                  trailing: Text(
                                    DateFormat(
                                      'HH:mm',
                                    ).format(log.createdAt.toLocal()),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: DiraColors.inkSoft,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
