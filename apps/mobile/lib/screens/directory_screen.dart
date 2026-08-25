import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/invite_sheet.dart';
import '../widgets/phone_field.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  List<DirectoryEntry> _entries = [];
  List<JoinRequest> _joinRequests = [];

  /// apartment_id -> phone numbers with a pending (unaccepted) invite.
  Map<String, List<String>> _pendingInvites = {};
  bool _loading = true;
  StreamSubscription<String>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _load();
    _realtimeSub = realtime.listen({
      'users',
      'join_requests',
      'invitations',
    }, _load);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final isVaad = context.read<SessionController>().user?.isVaad ?? false;
    try {
      final data = await api.get('/api/directory');
      List<JoinRequest> requests = [];
      if (isVaad) {
        final jr = await api.get('/api/join-requests');
        requests = ((jr['joinRequests'] ?? []) as List)
            .map((e) => JoinRequest.fromJson(e))
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _entries = ((data['directory'] ?? []) as List)
            .map((e) => DirectoryEntry.fromJson(e))
            .toList();
        _pendingInvites = {};
        for (final inv in (data['pendingInvitations'] ?? []) as List) {
          final aptId = inv['apartment_id'] as String?;
          final phone = inv['phone_number'] as String?;
          if (aptId != null && phone != null) {
            _pendingInvites.putIfAbsent(aptId, () => []).add(phone);
          }
        }
        _joinRequests = requests;
        _loading = false;
      });
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(JoinRequest request, bool approve) async {
    try {
      await api.patch('/api/join-requests/${request.id}', {
        'action': approve ? 'approve' : 'reject',
      });
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _invite(DirectoryEntry entry) async {
    var phoneE164 = '';
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.inviteResidentTo('${entry.apartmentNumber}')),
        content: PhoneField(onChanged: (v) => phoneE164 = v),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.sendInvite),
          ),
        ],
      ),
    );
    if (saved != true || phoneE164.length < 8) return;
    try {
      final res = await api.post('/api/invitations', {
        'apartmentId': entry.apartmentId,
        'phoneNumber': phoneE164,
      });
      final sent = res['smsDelivery']?['sent'] == true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sent
                  ? context.l10n.inviteSmsSent
                  : context.l10n.inviteCreatedCode(
                      '${res['invitation']['invite_code']}',
                    ),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVaad = context.watch<SessionController>().user?.isVaad ?? false;
    final l10n = context.l10n;
    final floors = <int, List<DirectoryEntry>>{};
    for (final e in _entries) {
      floors.putIfAbsent(e.floor, () => []).add(e);
    }
    final sortedFloors = floors.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.directoryTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isVaad)
            IconButton(
              tooltip: l10n.inviteLinkShare,
              icon: const Icon(Icons.ios_share_rounded, color: DiraColors.brick),
              onPressed: () => showInviteSheet(context),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DiraColors.brick),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: DiraColors.brick,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (isVaad) ...[
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: DiraColors.sageLight,
                        foregroundColor: DiraColors.sageDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.link_rounded),
                      label: Text(l10n.inviteViaLink),
                      onPressed: () => showInviteSheet(context),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (isVaad && _joinRequests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.joinRequestsTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DiraColors.brickDark,
                        ),
                      ),
                    ),
                    ..._joinRequests.map(
                      (r) => Card(
                        color: DiraColors.goldLight,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: DiraColors.creamCard,
                            child: Icon(
                              Icons.person_add_alt_1,
                              color: DiraColors.goldDark,
                            ),
                          ),
                          title: Text(r.fullName ?? r.phoneNumber ?? ''),
                          subtitle: Text(
                            [
                              if (r.apartmentNumber != null)
                                l10n.wantsApartment('${r.apartmentNumber}'),
                              if (r.phoneNumber != null) r.phoneNumber!,
                            ].join(' · '),
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.start,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.approve,
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: DiraColors.sageDark,
                                ),
                                onPressed: () => _decide(r, true),
                              ),
                              IconButton(
                                tooltip: l10n.reject,
                                icon: const Icon(
                                  Icons.cancel,
                                  color: DiraColors.brick,
                                ),
                                onPressed: () => _decide(r, false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  for (final floor in sortedFloors) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.floorN('$floor'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DiraColors.sageDark,
                        ),
                      ),
                    ),
                    ...floors[floor]!.map((e) {
                      final invited = _pendingInvites[e.apartmentId] ?? [];
                      final hasResidents = e.residents.isNotEmpty;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: hasResidents
                                ? DiraColors.sageLight
                                : invited.isNotEmpty
                                ? DiraColors.goldLight
                                : DiraColors.cream,
                            child: Text(
                              '${e.apartmentNumber}',
                              style: TextStyle(
                                color: hasResidents
                                    ? DiraColors.sageDark
                                    : invited.isNotEmpty
                                    ? DiraColors.goldDark
                                    : DiraColors.inkSoft,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            hasResidents
                                ? e.residents
                                      .map(
                                        (r) =>
                                            r.name.isEmpty ? r.phone : r.name,
                                      )
                                      .join(', ')
                                : invited.isNotEmpty
                                ? invited.join(', ')
                                : l10n.vacant,
                            textDirection:
                                !hasResidents && invited.isNotEmpty
                                ? TextDirection.ltr
                                : null,
                            textAlign: !hasResidents && invited.isNotEmpty
                                ? TextAlign.start
                                : null,
                          ),
                          subtitle: Text(
                            [
                              if (isVaad && invited.isNotEmpty)
                                l10n.invitePending,
                              e.parkingSpot != null
                                  ? l10n.parkingSpot(e.parkingSpot!)
                                  : l10n.noParking,
                            ].join(' · '),
                            style: isVaad && invited.isNotEmpty
                                ? const TextStyle(color: DiraColors.goldDark)
                                : null,
                          ),
                          trailing: isVaad && !hasResidents
                              ? invited.isNotEmpty
                                    ? const Icon(
                                        Icons.hourglass_top_rounded,
                                        color: DiraColors.goldDark,
                                        size: 20,
                                      )
                                    : IconButton(
                                        tooltip: l10n.inviteResident,
                                        icon: const Icon(
                                          Icons.person_add,
                                          color: DiraColors.brick,
                                        ),
                                        onPressed: () => _invite(e),
                                      )
                              : null,
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
