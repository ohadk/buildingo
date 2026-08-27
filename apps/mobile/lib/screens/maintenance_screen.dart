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
import '../widgets/attachment_picker.dart';
import '../widgets/phone_field.dart';
import '../widgets/ticket_timeline.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<Ticket> _tickets = [];
  List<VendorAgent> _vendors = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<String>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _load();
    _realtimeSub = realtime.listen({
      'tickets',
      'ticket_events',
      'vendor_agents',
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
      final results = await Future.wait([
        api.get('/api/tickets'),
        if (isVaad) api.get('/api/vendor-agents'),
      ]);
      if (!mounted) return;
      setState(() {
        _tickets = ((results[0]['tickets'] ?? []) as List)
            .map((t) => Ticket.fromJson(t))
            .toList();
        if (isVaad && results.length > 1) {
          _vendors = ((results[1]['vendorAgents'] ?? []) as List)
              .map((v) => VendorAgent.fromJson(v))
              .toList();
        }
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

  Future<void> _approveAndDispatch(Ticket ticket) async {
    if (_vendors.isEmpty) {
      _snack(context.l10n.configureVendorFirst);
      return;
    }
    final vendor = await showModalBottomSheet<VendorAgent>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                ctx.l10n.dispatchToWhichVendor,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ..._vendors.map(
              (v) => ListTile(
                leading: const Icon(Icons.smart_toy, color: DiraColors.brick),
                title: Text(v.vendorName),
                subtitle: Text(v.serviceType),
                onTap: () => Navigator.pop(ctx, v),
              ),
            ),
          ],
        ),
      ),
    );
    if (vendor == null || !mounted) return;

    _snack(context.l10n.agentDispatchingTo(vendor.vendorName));
    try {
      final res = await api.post('/api/tickets/${ticket.id}/dispatch', {
        'vendorAgentId': vendor.id,
      });
      if (!mounted) return;
      _snack(res['agentSummary'] ?? context.l10n.vendorContacted);
      await _load();
    } on ApiException catch (e) {
      if (mounted) _snack(context.l10n.dispatchFailed(e.message));
    }
  }

  Future<void> _markResolved(Ticket ticket) async {
    try {
      await api.patch('/api/tickets/${ticket.id}', {'status': 'resolved'});
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
    final isVaad = context.watch<SessionController>().user?.isVaad ?? false;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.maintenance,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isVaad)
            IconButton(
              tooltip: l10n.vendorAgents,
              icon: const Icon(Icons.smart_toy_outlined),
              onPressed: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => const VendorAgentsScreen(),
                    ),
                  )
                  .then((_) => _load()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'maintenance-fab',
        backgroundColor: DiraColors.brick,
        foregroundColor: DiraColors.creamCard,
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const NewTicketScreen()))
            .then((_) => _load()),
        icon: const Icon(Icons.add),
        label: Text(l10n.newReport),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DiraColors.brick),
            )
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              color: DiraColors.brick,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _tickets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final t = _tickets[i];
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
                                  t.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              _StatusChip(status: t.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.description,
                            style: const TextStyle(color: DiraColors.inkSoft),
                          ),
                          if (t.location != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 15,
                                  color: DiraColors.inkSoft,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  t.location!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: DiraColors.inkSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (t.imageUrl != null) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: InteractiveViewer(
                                    child: Image.network(t.imageUrl!),
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  t.imageUrl!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            '${t.reporterName ?? l10n.resident} · '
                            '${DateFormat('d MMM yyyy', locale).format(t.createdAt.toLocal())}'
                            '${t.vendorName != null ? ' · ${l10n.agentTo(t.vendorName!)}' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: DiraColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: DiraColors.sage,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: TicketTimeline(ticket: t),
                          ),
                          if (isVaad) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (t.status == 'open')
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _approveAndDispatch(t),
                                      icon: const Icon(
                                        Icons.smart_toy,
                                        size: 18,
                                      ),
                                      label: Text(l10n.approveAndDispatch),
                                    ),
                                  ),
                                if (t.status == 'in_progress')
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _markResolved(t),
                                      icon: const Icon(Icons.check),
                                      label: Text(l10n.markResolved),
                                    ),
                                  ),
                              ],
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

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (color, label) = switch (status) {
      'open' => (DiraColors.gold, l10n.statusOpen),
      'approved' => (DiraColors.terracotta, l10n.statusApproved),
      'in_progress' => (DiraColors.sage, l10n.statusInProgress),
      'resolved' => (DiraColors.sageDark, l10n.statusResolved),
      _ => (DiraColors.inkSoft, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
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
  PickedAttachment? _photo;
  bool _busy = false;
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
  Future<void> _pickPhoto() async {
    final picked = await pickAttachments(context);
    if (picked.isNotEmpty) setState(() => _photo = picked.first);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String? imagePath;
      final photo = _photo;
      if (photo != null) {
        final res = await api.uploadFile(
          '/api/tickets/upload',
          bytes: photo.bytes,
          filename: photo.name,
        );
        imagePath = res['imagePath'] as String?;
      }
      await api.post('/api/tickets', {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        if (_locationText != null) 'location': _locationText,
        'imagePath': ?imagePath,
      });
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportAFault)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
          if (_photo == null)
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l10n.addPhoto),
            )
          else
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _photo!.bytes,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _photo!.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: DiraColors.inkSoft,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.removePhoto,
                  onPressed: () => setState(() => _photo = null),
                  icon: const Icon(Icons.close, color: DiraColors.brick),
                ),
              ],
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                _busy ||
                    _title.text.trim().length < 3 ||
                    _description.text.trim().length < 3
                ? null
                : _submit,
            child: Text(_busy ? l10n.submitting : l10n.submitReport),
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

/// Vaad-only: configure the Claude agents per vendor contract.
class VendorAgentsScreen extends StatefulWidget {
  const VendorAgentsScreen({super.key});

  @override
  State<VendorAgentsScreen> createState() => _VendorAgentsScreenState();
}

class _VendorAgentsScreenState extends State<VendorAgentsScreen> {
  List<VendorAgent> _vendors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await api.get('/api/vendor-agents');
    if (!mounted) return;
    setState(() {
      _vendors = ((data['vendorAgents'] ?? []) as List)
          .map((v) => VendorAgent.fromJson(v))
          .toList();
      _loading = false;
    });
  }

  Future<void> _addVendor() async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _VendorAgentDialog(),
    );
    if (payload == null) return;

    try {
      await api.post('/api/vendor-agents', payload);
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _editVendor(VendorAgent vendor) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _VendorAgentDialog(initial: vendor),
    );
    if (payload == null) return;

    try {
      await api.patch('/api/vendor-agents/${vendor.id}', payload);
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteVendor(VendorAgent vendor) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteVendorTitle),
        content: Text(l10n.deleteVendorConfirm(vendor.vendorName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DiraColors.brick),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await api.delete('/api/vendor-agents/${vendor.id}');
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.vendorDeleted)));
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
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.vendorAiAgents)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'vendors-fab',
        backgroundColor: DiraColors.brick,
        foregroundColor: DiraColors.creamCard,
        onPressed: _addVendor,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DiraColors.brick),
            )
          : _vendors.isEmpty
          ? _EmptyAgentsState(onAdd: _addVendor)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _vendors
                  .map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          onTap: () => _editVendor(v),
                          leading: const Icon(
                            Icons.smart_toy,
                            color: DiraColors.brick,
                          ),
                          title: Text(v.vendorName),
                          subtitle: Text(
                            [
                              v.serviceType,
                              if (v.vendorEmail != null) v.vendorEmail!,
                              if (v.vendorPhone != null) v.vendorPhone!,
                            ].join(' · '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...v.preferredChannels.map(
                                (c) => Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 4,
                                  ),
                                  child: Icon(
                                    switch (c) {
                                      'email' => Icons.alternate_email,
                                      'whatsapp' => Icons.chat_rounded,
                                      _ => Icons.sms_rounded,
                                    },
                                    size: 18,
                                    color: DiraColors.sageDark,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: DiraColors.inkSoft,
                                ),
                                onSelected: (action) => action == 'edit'
                                    ? _editVendor(v)
                                    : _deleteVendor(v),
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(ctx.l10n.edit),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: DiraColors.brick,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          ctx.l10n.delete,
                                          style: const TextStyle(
                                            color: DiraColors.brick,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

/// Friendly first-run state explaining what vendor AI agents do.
class _EmptyAgentsState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyAgentsState({required this.onAdd});

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
                color: DiraColors.terracottaSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 48,
                color: DiraColors.brickDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.vendorAgentsEmptyTitle,
              textAlign: TextAlign.center,
              style: heading(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.vendorAgentsEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DiraColors.inkSoft,
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
            // How it works, in three steps.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _EmptyStep(
                      number: '1',
                      text: l10n.vendorAgentsStep1,
                    ),
                    const SizedBox(height: 10),
                    _EmptyStep(
                      number: '2',
                      text: l10n.vendorAgentsStep2,
                    ),
                    const SizedBox(height: 10),
                    _EmptyStep(
                      number: '3',
                      text: l10n.vendorAgentsStep3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.addFirstVendor),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStep extends StatelessWidget {
  final String number;
  final String text;
  const _EmptyStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: DiraColors.sagePale,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: DiraColors.sageDark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}

/// Vendor-agent create/edit form. The contact section is the contract with
/// the AI agent: the channels picked here are the only ways it may open a
/// ticket with the vendor, so each picked channel requires its detail.
class _VendorAgentDialog extends StatefulWidget {
  /// When set, the dialog edits this agent instead of creating a new one.
  final VendorAgent? initial;
  const _VendorAgentDialog({this.initial});

  @override
  State<_VendorAgentDialog> createState() => _VendorAgentDialogState();
}

class _VendorAgentDialogState extends State<_VendorAgentDialog> {
  late final _name = TextEditingController(
    text: widget.initial?.vendorName ?? '',
  );
  late final _service = TextEditingController(
    text: widget.initial?.serviceType ?? '',
  );
  late final _email = TextEditingController(
    text: widget.initial?.vendorEmail ?? '',
  );
  late final _contract = TextEditingController(
    text: widget.initial?.contractDetails ?? '',
  );
  late final _instructions = TextEditingController(
    text: widget.initial?.aiInstructions ?? '',
  );
  late String _phoneE164 = widget.initial?.vendorPhone ?? '';
  late final Set<String> _channels = widget.initial != null
      ? {...widget.initial!.preferredChannels}
      : {'email'};
  String? _error;

  String? _validate(AppLocalizations l10n) {
    if (_channels.isEmpty) return l10n.errSelectChannel;
    if (_channels.contains('email') && _email.text.trim().isEmpty) {
      return l10n.errEmailRequired;
    }
    if ((_channels.contains('sms') || _channels.contains('whatsapp')) &&
        !PhoneField.isValid(_phoneE164)) {
      return l10n.errPhoneRequired;
    }
    return null;
  }

  void _save() {
    final l10n = context.l10n;
    final error = _validate(l10n);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'vendorName': _name.text.trim(),
      'serviceType': _service.text.trim(),
      if (_email.text.trim().isNotEmpty) 'vendorEmail': _email.text.trim(),
      if (_phoneE164.isNotEmpty) 'vendorPhone': _phoneE164,
      'preferredChannels': _channels.toList(),
      if (_contract.text.trim().isNotEmpty)
        'contractDetails': _contract.text.trim(),
      if (_instructions.text.trim().isNotEmpty)
        'aiInstructions': _instructions.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final channels = [
      ('email', l10n.channelEmail, Icons.alternate_email),
      ('sms', l10n.channelSms, Icons.sms_rounded),
      ('whatsapp', l10n.channelWhatsapp, Icons.chat_rounded),
    ];
    final formReady =
        _name.text.trim().length >= 2 && _service.text.trim().length >= 2;

    return AlertDialog(
      title: Text(
        widget.initial == null ? l10n.newVendorAgent : l10n.editVendorAgent,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.vendorName,
                hintText: l10n.vendorNameHint,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _service,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.serviceType,
                hintText: l10n.serviceTypeHint,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.vendorContactSection,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.vendorContactHint,
              style: const TextStyle(fontSize: 12, color: DiraColors.inkSoft),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: channels
                  .map(
                    (c) => FilterChip(
                      avatar: Icon(
                        c.$3,
                        size: 16,
                        color: _channels.contains(c.$1)
                            ? Colors.white
                            : DiraColors.sageDark,
                      ),
                      label: Text(c.$2),
                      selected: _channels.contains(c.$1),
                      selectedColor: DiraColors.sageDark,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _channels.contains(c.$1)
                            ? Colors.white
                            : DiraColors.ink,
                        fontSize: 12.5,
                      ),
                      onSelected: (on) => setState(() {
                        _error = null;
                        if (on) {
                          _channels.add(c.$1);
                        } else {
                          _channels.remove(c.$1);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            if (_channels.contains('email')) ...[
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(labelText: l10n.vendorEmailLabel),
              ),
              const SizedBox(height: 10),
            ],
            if (_channels.contains('sms') ||
                _channels.contains('whatsapp')) ...[
              PhoneField(
                label: l10n.vendorPhoneLabel,
                initialValue: widget.initial?.vendorPhone,
                onChanged: (v) => setState(() {
                  _phoneE164 = v;
                  _error = null;
                }),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _contract,
              decoration: InputDecoration(labelText: l10n.contractOptional),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _instructions,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.aiInstructionsOptional,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: DiraColors.brick,
                    fontSize: 12.5,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: formReady ? _save : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
