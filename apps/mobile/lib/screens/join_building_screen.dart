import 'dart:async';

import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import 'tenant_profile_screen.dart';

/// Tenant flow: find the building by city + address. Both fields
/// autocomplete from OUR registered buildings, so a selection always
/// matches exactly. Picking a result opens the full profile form whose
/// details the Vaad reviews before approving.
class JoinBuildingScreen extends StatefulWidget {
  const JoinBuildingScreen({super.key});

  @override
  State<JoinBuildingScreen> createState() => _JoinBuildingScreenState();
}

class _JoinBuildingScreenState extends State<JoinBuildingScreen> {
  final _city = TextEditingController();
  final _address = TextEditingController();
  List<String> _citySuggestions = [];
  List<String> _addressSuggestions = [];
  String? _selectedCity;
  List<Map<String, dynamic>>? _results;
  bool _busy = false;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _debounced(void Function() run) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), run);
  }

  Future<void> _suggestCities(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _citySuggestions = []);
      return;
    }
    try {
      final res = await api.get(
        '/api/buildings/search?suggest=city&q=${Uri.encodeComponent(q.trim())}',
      );
      if (!mounted || _city.text.trim() != q.trim()) return;
      setState(() {
        _citySuggestions = ((res['suggestions'] ?? []) as List)
            .cast<String>();
      });
    } on ApiException {
      // Suggestions are best-effort.
    }
  }

  Future<void> _suggestAddresses(String q) async {
    final city = _selectedCity;
    if (city == null) return;
    try {
      final res = await api.get(
        '/api/buildings/search?suggest=address&city=${Uri.encodeComponent(city)}'
        '&q=${Uri.encodeComponent(q.trim())}',
      );
      if (!mounted) return;
      setState(() {
        _addressSuggestions = ((res['suggestions'] ?? []) as List)
            .cast<String>();
      });
    } on ApiException {
      // Suggestions are best-effort.
    }
  }

  Future<void> _search() async {
    final city = _selectedCity;
    if (city == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _results = null;
    });
    try {
      final params = [
        'city=${Uri.encodeComponent(city)}',
        if (_address.text.trim().isNotEmpty)
          'address=${Uri.encodeComponent(_address.text.trim())}',
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

  void _pickCity(String city) {
    setState(() {
      _selectedCity = city;
      _city.text = city;
      _citySuggestions = [];
      _addressSuggestions = [];
      _address.clear();
      _results = null;
    });
    _suggestAddresses('');
    _search();
  }

  void _pickAddress(String address) {
    setState(() {
      _address.text = address;
      _addressSuggestions = [];
    });
    _search();
  }

  Future<void> _openProfile(Map<String, dynamic> building) async {
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TenantProfileScreen(
          buildingId: building['id'],
          buildingName:
              building['name'] ?? '${building['address']}, ${building['city']}',
          requireDocs: building['require_join_docs'] == true,
          feeMethod: building['fee_method'] as String? ?? 'fixed',
        ),
      ),
    );
    if (sent == true && mounted) {
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  Widget _suggestionList(List<String> items, void Function(String) onPick) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items
            .map(
              (s) => ListTile(
                dense: true,
                leading: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: DiraColors.sageDark,
                ),
                title: Text(s, style: const TextStyle(fontSize: 14)),
                onTap: () => onPick(s),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.findBuildingTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.findBuildingHint,
            style: const TextStyle(color: DiraColors.inkSoft, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _city,
            onChanged: (v) {
              setState(() {
                _selectedCity = null;
                _results = null;
              });
              _debounced(() => _suggestCities(v));
            },
            decoration: InputDecoration(
              labelText: l10n.city,
              prefixIcon: const Icon(Icons.location_city_rounded),
              suffixIcon: _selectedCity != null
                  ? const Icon(Icons.check_circle, color: DiraColors.sageDark)
                  : null,
            ),
          ),
          _suggestionList(_citySuggestions, _pickCity),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            enabled: _selectedCity != null,
            onChanged: (v) {
              _debounced(() {
                _suggestAddresses(v);
                _search();
              });
            },
            decoration: InputDecoration(
              labelText: l10n.addressLabel,
              prefixIcon: const Icon(Icons.home_work_outlined),
              helperText: _selectedCity == null ? l10n.pickCityFirst : null,
            ),
          ),
          _suggestionList(_addressSuggestions, _pickAddress),
          const SizedBox(height: 20),
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: DiraColors.brick),
              ),
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: DiraColors.brick)),
          if (_results != null && _results!.isEmpty && !_busy)
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
                    onPressed: _busy ? null : () => _openProfile(b),
                    child: Text(l10n.askToJoin),
                  ),
                  onTap: _busy ? null : () => _openProfile(b),
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Alternative path: the Vaad can always send a personal invite
          // or the building's WhatsApp join link.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DiraColors.sagePale,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.forward_to_inbox_rounded,
                    color: DiraColors.sageDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.askVaadInviteHint,
                    style: const TextStyle(
                      color: DiraColors.sageDark,
                      fontSize: 13,
                      height: 1.4,
                    ),
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
