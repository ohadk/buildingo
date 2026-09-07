import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/phone_field.dart';
import '../widgets/upload_document_sheet.dart';
import '../widgets/vault_file_viewer.dart';
import 'tenant_transfer_screen.dart';
import 'documents_screen.dart';
import 'meetings_screen.dart';
import 'whatsapp_connect_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen>
    with WidgetsBindingObserver {
  List<DirectoryEntry> _entries = [];
  List<JoinRequest> _joinRequests = [];

  /// apartment_id -> phone numbers with a pending (unaccepted) invite.
  Map<String, List<String>> _pendingInvites = {};

  /// Floor collapse state; floors default to collapsed.
  final Map<int, bool> _floorExpanded = {};
  String _query = '';
  bool _loading = true;
  StreamSubscription<String>? _realtimeSub;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _realtimeSub = realtime.listen({
      'users',
      'join_requests',
      'invitations',
      'apartments',
      'tenancies',
    }, () => _load(silent: true));
    // Directory had no poll fallback — if Realtime misses an event the
    // Vaad never saw the new tenant until a full app restart.
    _pollTimer = Timer.periodic(
      Duration(seconds: realtimeEnabled ? 15 : 5),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realtimeSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    final isVaad = context.read<SessionController>().user?.isVaad ?? false;
    try {
      final data = await api.get('/api/directory');
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
        _loading = false;
      });
    } on ApiException {
      if (mounted && !silent) setState(() => _loading = false);
    }

    if (!isVaad || !mounted) return;
    try {
      final jr = await api.get('/api/join-requests');
      if (!mounted) return;
      setState(() {
        _joinRequests = ((jr['joinRequests'] ?? []) as List)
            .map((e) => JoinRequest.fromJson(e))
            .toList();
      });
    } on ApiException {
      // Join requests are secondary — don't blank the directory.
    }
  }

  Future<void> _decide(JoinRequest request, bool approve) async {
    // Optimistic remove so Approve/Reject feels instant.
    setState(() {
      _joinRequests =
          _joinRequests.where((r) => r.id != request.id).toList();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? context.l10n.joinApprovedSnack(request.fullName ?? '')
                : context.l10n.joinRejectedSnack(request.fullName ?? ''),
          ),
        ),
      );
    }
    try {
      await api.patch('/api/join-requests/${request.id}', {
        'action': approve ? 'approve' : 'reject',
      });
      if (mounted) await _load(silent: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      await _load(silent: true);
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
    if (saved != true || !PhoneField.isValid(phoneE164)) return;
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

    // Search filters by resident name/phone or apartment number; while
    // searching, matching floors are force-expanded.
    final q = _query.trim().toLowerCase();
    final entries = q.isEmpty
        ? _entries
        : _entries.where((e) {
            if ('${e.apartmentNumber}' == q) return true;
            final parking = e.parkingSpot?.toLowerCase();
            if (parking != null && parking.contains(q)) return true;
            return e.residents.any(
              (r) =>
                  r.name.toLowerCase().contains(q) || r.phone.contains(q),
            );
          }).toList();

    final floors = <int, List<DirectoryEntry>>{};
    for (final e in entries) {
      floors.putIfAbsent(e.floor, () => []).add(e);
    }
    // Apartment number -> requester awaiting Vaad approval, so the
    // apartment row itself reflects the pending request.
    final pendingByApt = <int, JoinRequest>{
      for (final r in _joinRequests)
        if (r.apartmentNumber != null) r.apartmentNumber!: r,
    };
    final sortedFloors = floors.keys.toList()..sort();

    return Scaffold(
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DiraColors.brick),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: DiraColors.brick,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.directoryTitle,
                          style: heading(fontSize: 26),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.watch<SessionController>().building?.address ??
                              context.watch<SessionController>().building?.name ??
                              '',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: DiraColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isVaad) ...[
                    const _InviteLinkCard(),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: l10n.searchResidents,
                      hintStyle: const TextStyle(
                        fontSize: 13.5,
                        color: DiraColors.inkSoft,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: DiraColors.inkSoft,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: DiraColors.creamCard,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: DiraColors.creamDeep),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: DiraColors.creamDeep),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                          color: DiraColors.brick,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isVaad && _joinRequests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.joinRequestsTitle,
                        style: heading(fontSize: 17),
                      ),
                    ),
                    ..._joinRequests.map(
                      (r) => _JoinRequestCard(
                        request: r,
                        onDecide: (approve) => _decide(r, approve),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  for (final floor in sortedFloors) ...[
                    Builder(
                      builder: (context) {
                        final apts = floors[floor]!;
                        final expanded =
                            q.isNotEmpty || (_floorExpanded[floor] ?? false);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: DiraColors.creamCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: DiraColors.creamDeep),
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () => setState(
                                    () => _floorExpanded[floor] = !expanded,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          l10n.floorN('$floor'),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          l10n.apartmentsCountN('${apts.length}'),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: DiraColors.inkSoft,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          expanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons.keyboard_arrow_down_rounded,
                                          size: 22,
                                          color: DiraColors.inkSoft,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (expanded) ...[
                                  const Divider(
                                    height: 1,
                                    color: DiraColors.creamDeep,
                                  ),
                                  ...apts.map((e) {
                                    final invited =
                                        _pendingInvites[e.apartmentId] ?? [];
                                    final hasResidents = e.residents.isNotEmpty;
                                    final request = hasResidents
                                        ? null
                                        : pendingByApt[e.apartmentNumber];
                                    final waiting =
                                        invited.isNotEmpty || request != null;
                                    final name = hasResidents
                                        ? e.residents
                                              .map(
                                                (r) => r.name.isEmpty
                                                    ? r.phone
                                                    : r.name,
                                              )
                                              .join(', ')
                                        : request != null
                                        ? (request.fullName ??
                                              request.phoneNumber ??
                                              l10n.vacant)
                                        : invited.isNotEmpty
                                        ? invited.join(', ')
                                        : l10n.vacant;
                                    final phone = hasResidents
                                        ? e.residents.first.phone
                                        : null;
                                    final locale =
                                        Localizations.localeOf(context)
                                            .languageCode;
                                    final metaParts = <String>[
                                      if (e.parkingSpot != null)
                                        l10n.parkingSpot(e.parkingSpot!),
                                      if (hasResidents &&
                                          e.numOccupants != null)
                                        l10n.occupantsN('${e.numOccupants}'),
                                      if (hasResidents &&
                                          e.residentSince != null)
                                        l10n.directoryResidentSince(
                                          DateFormat.yMMMd(locale)
                                              .format(e.residentSince!),
                                        ),
                                    ];
                                    return InkWell(
                                      onTap: isVaad
                                          ? () => showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    DiraColors.cream,
                                                shape:
                                                    const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  24,
                                                                ),
                                                          ),
                                                    ),
                                                builder: (_) =>
                                                    _ApartmentSheet(entry: e),
                                              )
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    l10n.apartmentShort(
                                                      '${e.apartmentNumber}',
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: DiraColors.inkSoft,
                                                    ),
                                                  ),
                                                  Text(
                                                    name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: !hasResidents &&
                                                              !waiting
                                                          ? DiraColors.inkSoft
                                                          : DiraColors.ink,
                                                    ),
                                                  ),
                                                  if (metaParts.isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        top: 2,
                                                      ),
                                                      child: Text(
                                                        metaParts.join(' · '),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: DiraColors
                                                              .inkSoft,
                                                          height: 1.25,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            if (isVaad &&
                                                !hasResidents &&
                                                !waiting)
                                              IconButton(
                                                tooltip: l10n.inviteResident,
                                                icon: const Icon(
                                                  Icons.person_add,
                                                  color: DiraColors.brick,
                                                ),
                                                onPressed: () => _invite(e),
                                              )
                                            else if (phone != null &&
                                                phone.isNotEmpty)
                                              InkWell(
                                                onTap: () => launchUrl(
                                                  Uri.parse('tel:$phone'),
                                                ),
                                                customBorder:
                                                    const CircleBorder(),
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: DiraColors.brick,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.phone_rounded,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              )
                                            else if (waiting)
                                              const Icon(
                                                Icons.hourglass_top_rounded,
                                                color: DiraColors.goldDark,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  if (isVaad) ...[
                    const SizedBox(height: 12),
                    Text(l10n.vaadTools, style: heading(fontSize: 17)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _VaadToolTile(
                          icon: Icons.folder_rounded,
                          label: l10n.documents,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DocumentsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _VaadToolTile(
                          icon: Icons.chat_rounded,
                          label: l10n.whatsappConnect,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WhatsAppConnectScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _VaadToolTile(
                          icon: Icons.how_to_vote_rounded,
                          label: l10n.assemblies,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MeetingsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _VaadToolTile(
                          icon: Icons.mail_outline_rounded,
                          label: l10n.toolMessage,
                          onTap: () {
                            // Compose lives on home FAB for Vaad.
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
    );
  }
}

class _VaadToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _VaadToolTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: DiraColors.brick,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apartment card for the Vaad: unit details, residents with tappable
/// contact info, join documents (Arnona / proof of residence), pending
/// invites and open debt.
class _ApartmentSheet extends StatefulWidget {
  final DirectoryEntry entry;
  const _ApartmentSheet({required this.entry});

  @override
  State<_ApartmentSheet> createState() => _ApartmentSheetState();
}

class _ApartmentSheetState extends State<_ApartmentSheet> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await api.get('/api/apartments/${widget.entry.apartmentId}');
      if (mounted) setState(() => _data = res);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _openVaultDoc(String path, {String? title}) async {
    await openVaultFile(
      context,
      bucket: 'documents',
      path: path,
      title: title,
    );
  }

  Future<void> _uploadDocument() async {
    final l10n = context.l10n;
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UploadDocumentSheet(
        apartmentId: widget.entry.apartmentId,
      ),
    );
    if (uploaded == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.documentsUploaded)),
      );
      setState(() => _data = null);
      await _fetch();
    }
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DiraColors.sageDark),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Opens the 3-step holder transfer wizard; on success refetches the
  /// card so the new pending holder and the closed period show up.
  Future<void> _openTransfer(List<Tenancy> tenancies, double debt) async {
    Tenancy? current;
    for (final t in tenancies) {
      if (t.status == 'active') {
        current = t;
        break;
      }
    }
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TenantTransferScreen(
          apartmentId: widget.entry.apartmentId,
          apartmentNumber: widget.entry.apartmentNumber,
          current: current,
          debt: debt,
        ),
      ),
    );
    if (done == true && mounted) {
      setState(() => _data = null);
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.transferDone)),
        );
      }
    }
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: DiraColors.brickDark,
      ),
    ),
  );

  Widget _contactRow(IconData icon, String text, Uri uri) {
    return InkWell(
      onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 15, color: DiraColors.brick),
            const SizedBox(width: 8),
            Text(
              text,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 13,
                color: DiraColors.brick,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    final e = widget.entry;
    final data = _data;
    final apartment = data?['apartment'] as Map<String, dynamic>?;
    final residents = (data?['residents'] ?? []) as List;
    final invites = (data?['pendingInvites'] ?? []) as List;
    final documents = (data?['documents'] ?? []) as List;
    final vaultDocuments = (data?['vaultDocuments'] ?? []) as List;
    final hasAnyDocs = documents.isNotEmpty || vaultDocuments.isNotEmpty;
    final debt = double.tryParse('${data?['debt'] ?? 0}') ?? 0;
    final tenancies = ((data?['tenancies'] ?? []) as List)
        .map((t) => Tenancy.fromJson(t))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: DiraColors.sageLight,
                    child: Text(
                      '${e.apartmentNumber}',
                      style: const TextStyle(
                        color: DiraColors.sageDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.apartmentShort('${e.apartmentNumber}'),
                      style: heading(fontSize: 20),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: debt > 0
                          ? DiraColors.terracottaSoft
                          : DiraColors.sagePale,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      debt > 0
                          ? l10n.debtAmount(currency.format(debt))
                          : l10n.noDebt,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: debt > 0
                            ? DiraColors.brickDark
                            : DiraColors.sageDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(Icons.stairs_rounded, l10n.floorN('${e.floor}')),
                  _chip(
                    Icons.local_parking_rounded,
                    e.parkingSpot != null
                        ? l10n.parkingSpot(e.parkingSpot!)
                        : l10n.noParking,
                  ),
                  if (apartment?['size_sqm'] != null)
                    _chip(
                      Icons.square_foot_rounded,
                      l10n.sqmShort('${apartment!['size_sqm']}'),
                    ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: DiraColors.brick),
                  ),
                )
              else if (data == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: DiraColors.brick),
                  ),
                )
              else ...[
                // Holder transfer entry: rentals change hands, the card
                // and its history stay with the unit.
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: DiraColors.creamCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () => _openTransfer(tenancies, debt),
                        child: Text(
                          l10n.transferHolder,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          [
                            debt > 0
                                ? l10n.debtAmount(currency.format(debt))
                                : l10n.noDebt,
                            tenancies.any((t) => t.status == 'ended')
                                ? l10n.previousHoldersN(
                                    '${tenancies.where((t) => t.status == 'ended').length}',
                                  )
                                : l10n.noPreviousHolders,
                          ].join(' · '),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DiraColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionTitle(l10n.residentsSection),
                if (residents.isEmpty)
                  Text(
                    l10n.vacant,
                    style: const TextStyle(color: DiraColors.inkSoft),
                  )
                else
                  ...residents.map((r) {
                    final name = (r['full_name'] ?? '') as String;
                    final phone = (r['phone_number'] ?? '') as String;
                    final email = (r['email'] ?? '') as String?;
                    final occupants = r['num_occupants'] as int?;
                    final isVaadMember = r['role'] == 'vaad';
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DiraColors.creamCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name.isEmpty ? phone : name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isVaadMember)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DiraColors.sageDeep,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    l10n.vaadBadge,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (occupants != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                l10n.occupantsN('$occupants'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: DiraColors.inkSoft,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          if (phone.isNotEmpty)
                            _contactRow(
                              Icons.phone_rounded,
                              PhoneField.formatDisplay(phone),
                              Uri.parse('tel:$phone'),
                            ),
                          if ((email ?? '').isNotEmpty)
                            _contactRow(
                              Icons.mail_outline_rounded,
                              email!,
                              Uri.parse('mailto:$email'),
                            ),
                        ],
                      ),
                    );
                  }),
                if (tenancies.isNotEmpty) ...[
                  _sectionTitle(l10n.holdersHistory),
                  ...tenancies.map((t) => _TenancyRow(tenancy: t)),
                ],
                if (invites.isNotEmpty) ...[
                  _sectionTitle(l10n.pendingInvitesSection),
                  ...invites.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.hourglass_top_rounded,
                            size: 15,
                            color: DiraColors.goldDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            PhoneField.formatDisplay(
                              '${i['phone_number'] ?? ''}',
                            ),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.invitePending,
                            style: const TextStyle(
                              fontSize: 12,
                              color: DiraColors.goldDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                Row(
                  children: [
                    Expanded(child: _sectionTitle(l10n.documents)),
                    TextButton.icon(
                      onPressed: _uploadDocument,
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(l10n.uploadDocument),
                    ),
                  ],
                ),
                if (!hasAnyDocs)
                  Text(
                    l10n.noDocsForApartment,
                    style: const TextStyle(color: DiraColors.inkSoft),
                  )
                else ...[
                  ...vaultDocuments.map((d) {
                    final title = (d['title'] ?? '') as String;
                    final who = (d['uploaded_by_name'] ?? '') as String?;
                    final isPdf = d['file_type'] == 'application/pdf';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _openVaultDoc('${d['file_path']}'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DiraColors.creamCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isPdf
                                    ? Icons.picture_as_pdf
                                    : Icons.insert_drive_file,
                                size: 18,
                                color: DiraColors.brick,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if ((who ?? '').isNotEmpty)
                                Text(
                                  who!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: DiraColors.inkSoft,
                                  ),
                                ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: DiraColors.inkSoft,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  ...documents.map((d) {
                    final isArnona = d['kind'] == 'arnona';
                    final who = (d['user_name'] ?? '') as String?;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => launchUrl(
                          Uri.parse(d['url']),
                          mode: LaunchMode.externalApplication,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DiraColors.creamCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isArnona
                                    ? Icons.square_foot_rounded
                                    : Icons.description_outlined,
                                size: 18,
                                color: DiraColors.brick,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isArnona
                                      ? l10n.attachArnona
                                      : l10n.attachResidence,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if ((who ?? '').isNotEmpty)
                                Text(
                                  who!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: DiraColors.inkSoft,
                                  ),
                                ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: DiraColors.inkSoft,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of the apartment's holders history: status dot, name, badge
/// (current / awaiting details), holder type, occupancy period, phone.
class _TenancyRow extends StatelessWidget {
  final Tenancy tenancy;
  const _TenancyRow({required this.tenancy});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = tenancy;
    final fmt = DateFormat('dd/MM/yyyy');

    final dotColor = switch (t.status) {
      'active' => DiraColors.sageDark,
      'pending' => DiraColors.goldDark,
      _ => DiraColors.inkSoft,
    };
    final badge = switch (t.status) {
      'active' => l10n.currentHolder,
      'pending' => l10n.pendingHolder,
      _ => null,
    };
    final typeLabel = t.holderType == 'owner'
        ? l10n.holderOwner
        : l10n.holderRenter;
    final period = t.endedAt != null
        ? '${fmt.format(t.startedAt)} – ${fmt.format(t.endedAt!)}'
        : l10n.periodSince(fmt.format(t.startedAt));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        t.fullName ??
                            (t.phoneNumber != null
                                ? PhoneField.formatDisplay(t.phoneNumber!)
                                : l10n.newHolderFallback),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: t.status == 'ended'
                              ? DiraColors.inkSoft
                              : DiraColors.ink,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: t.status == 'active'
                              ? DiraColors.sagePale
                              : DiraColors.goldLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: t.status == 'active'
                                ? DiraColors.sageDark
                                : DiraColors.goldDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    typeLabel,
                    if (t.numOccupants != null)
                      l10n.occupantsN('${t.numOccupants}'),
                    period,
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: DiraColors.inkSoft,
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

/// Inline invite card at the top of the residents list: shows the
/// building's general join link with a copy action and a WhatsApp share
/// button, so the Vaad doesn't have to open a separate sheet.
class _InviteLinkCard extends StatelessWidget {
  const _InviteLinkCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final building = context.watch<SessionController>().building;
    final code = building?.joinCode;
    if (building == null || code == null) return const SizedBox.shrink();

    return FutureBuilder<String>(
      future: ApiClient.joinLinkFor(code),
      builder: (context, snap) {
        final link = snap.data;
        if (link == null) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DiraColors.sageLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DiraColors.sageDark,
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
          decoration: BoxDecoration(
            color: DiraColors.sageLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: DiraColors.sagePale,
                    child: Icon(
                      Icons.group_add_rounded,
                      size: 19,
                      color: DiraColors.sageDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.inviteResidents,
                          style: heading(
                            fontSize: 15.5,
                            color: DiraColors.sageDeep,
                          ),
                        ),
                        Text(
                          l10n.inviteLinkExplain,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: DiraColors.sageDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 18,
                    color: DiraColors.sageDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: link));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.joinLinkCopied)),
                          );
                        }
                      },
                      child: Text(
                        link.replaceFirst(RegExp(r'^https?://'), ''),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: DiraColors.ink,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.copyLink,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 17,
                      color: DiraColors.brick,
                    ),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: link));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.joinLinkCopied)),
                        );
                      }
                    },
                  ),
                  IconButton(
                    tooltip: l10n.shareOnWhatsapp,
                    visualDensity: VisualDensity.compact,
                    icon: const CircleAvatar(
                      radius: 13,
                      backgroundColor: Color(0xFF25D366),
                      child: Icon(
                        Icons.chat_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      final message =
                          l10n.shareJoinMessage(building.name, link);
                      launchUrl(
                        Uri.parse(
                          'https://wa.me/?text=${Uri.encodeComponent(message)}',
                        ),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full review card for a pending join request: the Vaad sees every
/// detail the tenant filled in (apartment, floor, occupants, parking,
/// contact info, supporting document) before deciding.
class _JoinRequestCard extends StatelessWidget {
  final JoinRequest request;
  final void Function(bool approve) onDecide;

  const _JoinRequestCard({required this.request, required this.onDecide});

  Widget _docLink(IconData icon, String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: InkWell(
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Row(
          children: [
            Icon(icon, size: 15, color: DiraColors.brick),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: DiraColors.brick,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String text, {TextDirection? direction}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: DiraColors.goldDark),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              textDirection: direction,
              textAlign: TextAlign.start,
              style: const TextStyle(fontSize: 12.5, color: DiraColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = request;
    return Card(
      color: DiraColors.goldLight,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: DiraColors.creamCard,
                  child: Icon(
                    Icons.person_add_alt_1,
                    color: DiraColors.goldDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.fullName ?? r.phoneNumber ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (r.apartmentNumber != null)
                        Text(
                          l10n.wantsApartment('${r.apartmentNumber}'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: DiraColors.inkSoft,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (r.sizeSqm != null)
              _detail(
                Icons.square_foot_outlined,
                l10n.sqmShort('${r.sizeSqm}'),
              ),
            if (r.floor != null)
              _detail(Icons.stairs_outlined, l10n.floorN('${r.floor}')),
            if (r.numOccupants != null)
              _detail(
                Icons.group_outlined,
                l10n.occupantsN('${r.numOccupants}'),
              ),
            if (r.parkingSpot != null && r.parkingSpot!.isNotEmpty)
              _detail(Icons.local_parking_outlined, r.parkingSpot!),
            if (r.phoneNumber != null)
              _detail(
                Icons.phone_outlined,
                r.phoneNumber!,
                direction: TextDirection.ltr,
              ),
            if (r.email != null && r.email!.isNotEmpty)
              _detail(
                Icons.email_outlined,
                r.email!,
                direction: TextDirection.ltr,
              ),
            if (r.arnonaDocUrl != null)
              _docLink(Icons.square_foot_rounded, l10n.viewArnonaDoc, r.arnonaDocUrl!),
            if (r.docUrl != null)
              _docLink(Icons.description_outlined, l10n.viewResidenceDoc, r.docUrl!),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: DiraColors.sageDark,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.approve),
                    onPressed: () => onDecide(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DiraColors.brick,
                      side: const BorderSide(color: DiraColors.brick),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(l10n.reject),
                    onPressed: () => onDecide(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
