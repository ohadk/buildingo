import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Tenant flow: search for the building by address; if it exists, ask
/// to join (Vaad approves); if not, explain that the Vaad must create
/// it first.
class JoinBuildingScreen extends StatefulWidget {
  const JoinBuildingScreen({super.key});

  @override
  State<JoinBuildingScreen> createState() => _JoinBuildingScreenState();
}

class _JoinBuildingScreenState extends State<JoinBuildingScreen> {
  final _country = TextEditingController(text: 'ישראל');
  final _city = TextEditingController();
  final _address = TextEditingController();
  List<Map<String, dynamic>>? _results;
  bool _busy = false;
  String? _error;

  Future<void> _search() async {
    setState(() {
      _busy = true;
      _error = null;
      _results = null;
    });
    try {
      final params = <String>[
        if (_city.text.trim().isNotEmpty)
          'city=${Uri.encodeComponent(_city.text.trim())}',
        if (_address.text.trim().isNotEmpty)
          'address=${Uri.encodeComponent(_address.text.trim())}',
        if (_country.text.trim().isNotEmpty)
          'country=${Uri.encodeComponent(_country.text.trim())}',
      ].join('&');
      final res = await api.get('/api/buildings/search?$params');
      if (!mounted) return;
      setState(() {
        _results = ((res['buildings'] ?? []) as List)
            .cast<Map<String, dynamic>>();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askToJoin(Map<String, dynamic> building) async {
    final nameController = TextEditingController(
      text: context.read<SessionController>().user?.fullName ?? '',
    );
    final aptController = TextEditingController();
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: DiraColors.creamCard,
          title: Text(building['name'] ?? '', style: heading(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(labelText: l10n.fullName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aptController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.yourApartmentNumber,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed:
                  nameController.text.trim().length >= 2 &&
                      int.tryParse(aptController.text.trim()) != null
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: Text(l10n.askToJoin),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await context.read<SessionController>().requestJoin(
        buildingId: building['id'],
        apartmentNumber: int.parse(aptController.text.trim()),
        fullName: nameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.requestSent)));
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.findBuildingTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _country,
                  decoration: InputDecoration(labelText: l10n.country),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _city,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: l10n.city),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.addressLabel),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed:
                _busy ||
                    (_city.text.trim().length < 2 &&
                        _address.text.trim().length < 2)
                ? null
                : _search,
            icon: const Icon(Icons.search),
            label: Text(_busy ? l10n.pleaseWait : l10n.searchLabel),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: DiraColors.brick)),
          if (_results != null && _results!.isEmpty)
            Card(
              color: DiraColors.terracottaSoft,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: DiraColors.brickDark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.noBuildingFound,
                        style: const TextStyle(
                          color: DiraColors.brickDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_results != null)
            ..._results!.map(
              (b) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: DiraColors.sagePale,
                    child: Icon(Icons.apartment, color: DiraColors.sageDark),
                  ),
                  title: Text(b['name'] ?? ''),
                  subtitle: Text('${b['address']}, ${b['city']}'),
                  trailing: TextButton(
                    onPressed: _busy ? null : () => _askToJoin(b),
                    child: Text(l10n.askToJoin),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
