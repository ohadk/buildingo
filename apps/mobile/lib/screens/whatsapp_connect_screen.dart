import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Vaad screen: connect WhatsApp via WAHA QR and link the building group.
class WhatsAppConnectScreen extends StatefulWidget {
  const WhatsAppConnectScreen({super.key});

  @override
  State<WhatsAppConnectScreen> createState() => _WhatsAppConnectScreenState();
}

class _WhatsAppConnectScreenState extends State<WhatsAppConnectScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _status;
  String? _session;
  String? _me;
  String? _groupId;
  String? _qrBase64;
  List<Map<String, dynamic>> _groups = [];
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final data = await api.get('/api/whatsapp');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _status = data['status']?.toString();
        _session = data['session']?.toString();
        _groupId = data['groupId']?.toString();
        final me = data['me'];
        _me = me is Map ? (me['pushName'] ?? me['id'])?.toString() : null;
        if (data['configured'] == false) {
          _error = context.l10n.whatsappNotConfigured;
        }
      });
      if (_status == 'WORKING' && _groupId == null) {
        await _loadGroups();
      }
      _maybePoll();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  void _maybePoll() {
    _poll?.cancel();
    if (_status == 'SCAN_QR_CODE' || _status == 'STARTING') {
      _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
    }
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await api.post('/api/whatsapp', {});
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = data['status']?.toString();
        _session = data['session']?.toString();
        _qrBase64 = data['qrBase64']?.toString();
        final me = data['me'];
        _me = me is Map ? (me['pushName'] ?? me['id'])?.toString() : null;
      });
      if (_qrBase64 == null &&
          (_status == 'SCAN_QR_CODE' || _status == 'STARTING')) {
        await _fetchQr();
      }
      if (_status == 'WORKING') await _loadGroups();
      _maybePoll();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _fetchQr() async {
    try {
      final data = await api.get('/api/whatsapp/qr?format=json');
      if (!mounted) return;
      setState(() {
        _qrBase64 = data['qrBase64']?.toString();
        _status = data['status']?.toString() ?? _status;
      });
    } on ApiException {
      // ignore — poll will retry
    }
  }

  Future<void> _loadGroups() async {
    try {
      final data = await api.get('/api/whatsapp/groups');
      if (!mounted) return;
      setState(() {
        _groups = ((data['groups'] ?? []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _linkGroup(String groupId) async {
    setState(() => _busy = true);
    try {
      await api.post('/api/whatsapp/groups', {'groupId': groupId});
      if (!mounted) return;
      setState(() {
        _busy = false;
        _groupId = groupId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.whatsappGroupLinked)),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  Widget? _qrImage() {
    final raw = _qrBase64;
    if (raw == null || raw.isEmpty) return null;
    final b64 = raw.contains(',') ? raw.split(',').last : raw;
    try {
      return Image.memory(base64Decode(b64), width: 240, height: 240);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connected = _status == 'WORKING';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.whatsappConnect,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DiraColors.brick),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Text(l10n.whatsappConnectBody, style: const TextStyle(height: 1.45)),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: Icon(
                      connected
                          ? Icons.check_circle_rounded
                          : Icons.qr_code_2_rounded,
                      color: connected ? DiraColors.sageDark : DiraColors.brick,
                    ),
                    title: Text(
                      connected
                          ? l10n.whatsappConnected
                          : l10n.whatsappNotConnected,
                    ),
                    subtitle: Text(
                      [
                        ?_status,
                        ?_me,
                        ?_session,
                      ].join(' · '),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (!connected) ...[
                  ElevatedButton(
                    onPressed: _busy ? null : _start,
                    child: Text(
                      _busy ? l10n.pleaseWait : l10n.whatsappStartSession,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_qrImage() != null) ...[
                    Text(
                      l10n.whatsappScanQr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Center(child: _qrImage()),
                  ],
                ] else ...[
                  if (_groupId != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.groups_rounded,
                          color: DiraColors.sageDark,
                        ),
                        title: Text(l10n.whatsappGroupLinked),
                        subtitle: Text(_groupId!),
                      ),
                    )
                  else ...[
                    Text(
                      l10n.whatsappPickGroup,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_groups.isEmpty)
                      TextButton(
                        onPressed: _busy ? null : _loadGroups,
                        child: Text(l10n.whatsappLoadGroups),
                      )
                    else
                      ..._groups.map(
                        (g) => Card(
                          child: ListTile(
                            title: Text(g['name']?.toString() ?? g['id'].toString()),
                            subtitle: Text(g['id']?.toString() ?? ''),
                            trailing: const Icon(Icons.link),
                            onTap: _busy
                                ? null
                                : () => _linkGroup(g['id'].toString()),
                          ),
                        ),
                      ),
                  ],
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: DiraColors.brick),
                  ),
                ],
              ],
            ),
    );
  }
}
