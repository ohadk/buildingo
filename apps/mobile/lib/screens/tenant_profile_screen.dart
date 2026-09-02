import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/parking_spots_field.dart';

/// Tenant profile form shown after a building was found (by search or by
/// join code). Everything here lands on the Vaad's approval card:
/// apartment, full name, occupants, floor, parking, email and two
/// documents — an Arnona bill (shows the apartment's sqm, which drives
/// per-sqm Vaad fees) and a proof of residence (rent/purchase
/// agreement). The Vaad can make both mandatory for their building.
class TenantProfileScreen extends StatefulWidget {
  final String buildingName;

  /// Exactly one of these is set: found by search vs. entered a code.
  final String? buildingId;
  final String? joinCode;

  /// The building's policy: documents are mandatory when true.
  final bool requireDocs;

  /// fixed | per_sqm — drives sqm collection and fee preview.
  final String feeMethod;

  const TenantProfileScreen({
    super.key,
    required this.buildingName,
    this.buildingId,
    this.joinCode,
    this.requireDocs = false,
    this.feeMethod = 'fixed',
  }) : assert(buildingId != null || joinCode != null);

  @override
  State<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _apartment = TextEditingController();
  final _floor = TextEditingController();
  final _occupants = TextEditingController(text: '1');
  final _sqm = TextEditingController();
  List<String> _parkingSpots = [];
  PlatformFile? _arnonaDoc;
  PlatformFile? _residenceDoc;
  bool _busy = false;
  bool _extractingSqm = false;
  String? _error;
  Timer? _aptDebounce;

  double? _knownSqm;
  double? _monthlyFeePreview;
  double? _pricePerSqm;
  bool _requiresSqmInput = false;

  bool get _perSqm => widget.feeMethod == 'per_sqm';

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionController>().user;
    _name.text = user?.fullName ?? '';
    _email.text = user?.email ?? '';
    _apartment.addListener(_onApartmentChanged);
  }

  @override
  void dispose() {
    _aptDebounce?.cancel();
    _apartment.removeListener(_onApartmentChanged);
    _name.dispose();
    _email.dispose();
    _apartment.dispose();
    _floor.dispose();
    _occupants.dispose();
    _sqm.dispose();
    super.dispose();
  }

  void _onApartmentChanged() {
    _aptDebounce?.cancel();
    _aptDebounce = Timer(const Duration(milliseconds: 400), _fetchFeePreview);
  }

  Future<void> _fetchFeePreview() async {
    final buildingId = widget.buildingId;
    final apt = int.tryParse(_apartment.text.trim());
    if (buildingId == null || apt == null) {
      setState(() {
        _knownSqm = null;
        _monthlyFeePreview = null;
        _requiresSqmInput = _perSqm;
      });
      return;
    }
    try {
      final res = await api.get(
        '/api/buildings/$buildingId/apartment-fee-preview?apartmentNumber=$apt',
      );
      if (!mounted) return;
      setState(() {
        _knownSqm = (res['sizeSqm'] as num?)?.toDouble();
        _monthlyFeePreview = (res['monthlyFee'] as num?)?.toDouble();
        _pricePerSqm = (res['pricePerSqm'] as num?)?.toDouble();
        _requiresSqmInput = res['requiresSqmInput'] == true;
        if (_knownSqm != null) {
          _sqm.text = _knownSqm!.toStringAsFixed(
            _knownSqm! == _knownSqm!.roundToDouble() ? 0 : 1,
          );
        }
      });
    } on ApiException {
      // Preview is best-effort during typing.
    }
  }

  double? get _effectiveSqm {
    if (_knownSqm != null) return _knownSqm;
    return double.tryParse(_sqm.text.trim());
  }

  bool get _valid {
    final base =
        _name.text.trim().length >= 2 &&
        int.tryParse(_apartment.text.trim()) != null &&
        (_email.text.trim().isEmpty || _email.text.contains('@')) &&
        (!widget.requireDocs || (_arnonaDoc != null && _residenceDoc != null));
    if (!_perSqm || !_requiresSqmInput) return base;
    if (_knownSqm != null) return base;
    return base &&
        _arnonaDoc != null &&
        _effectiveSqm != null &&
        _effectiveSqm! > 0;
  }

  Future<void> _pickDoc(void Function(PlatformFile) assign) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final file = result.firstOrNull;
    if (file != null) setState(() => assign(file));
  }

  Future<String?> _upload(PlatformFile? doc) async {
    if (doc == null) return null;
    final res = await api.uploadFile(
      '/api/join-requests/upload',
      bytes: await doc.readAsBytes(),
      filename: doc.name,
    );
    return res['docPath'] as String?;
  }

  Future<void> _extractSqmFromArnona(String docPath) async {
    setState(() => _extractingSqm = true);
    try {
      final res = await api.post('/api/join-requests/extract-sqm', {
        'docPath': docPath,
      });
      final sqm = (res['sizeSqm'] as num?)?.toDouble();
      if (sqm != null && mounted) {
        setState(() {
          _sqm.text = sqm.toStringAsFixed(sqm == sqm.roundToDouble() ? 0 : 1);
          if (_pricePerSqm != null) {
            _monthlyFeePreview = (sqm * _pricePerSqm!).ceilToDouble();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.sqmExtracted)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.sqmEnterManually)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _extractingSqm = false);
    }
  }

  Future<void> _submit() async {
    final session = context.read<SessionController>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final arnonaDocPath = await _upload(_arnonaDoc);
      final docPath = await _upload(_residenceDoc);

      if (_requiresSqmInput &&
          _knownSqm == null &&
          arnonaDocPath != null &&
          _sqm.text.trim().isEmpty) {
        await _extractSqmFromArnona(arnonaDocPath);
      }

      final apartmentNumber = int.parse(_apartment.text.trim());
      final email = _email.text.trim();
      final floor = int.tryParse(_floor.text.trim());
      final occupants = int.tryParse(_occupants.text.trim());
      final sizeSqm = _knownSqm ?? double.tryParse(_sqm.text.trim());

      if (widget.buildingId != null) {
        await session.requestJoin(
          buildingId: widget.buildingId!,
          apartmentNumber: apartmentNumber,
          fullName: _name.text.trim(),
          email: email,
          numOccupants: occupants,
          floor: floor,
          parkingSpots: _parkingSpots,
          docPath: docPath,
          arnonaDocPath: arnonaDocPath,
          sizeSqm: sizeSqm,
        );
      } else {
        await session.joinWithCode(
          widget.joinCode!,
          apartmentNumber: apartmentNumber,
          fullName: _name.text.trim(),
          email: email,
          numOccupants: occupants,
          floor: floor,
          parkingSpots: _parkingSpots,
          docPath: docPath,
          arnonaDocPath: arnonaDocPath,
          sizeSqm: sizeSqm,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.requestSent)));
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onArnonaPicked() async {
    await _pickDoc((f) => _arnonaDoc = f);
    if (_arnonaDoc == null || _knownSqm != null) return;
    setState(() => _busy = true);
    try {
      final path = await _upload(_arnonaDoc);
      if (path != null) await _extractSqmFromArnona(path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _feePreviewCard(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final currency = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    if (!_perSqm && _monthlyFeePreview == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DiraColors.sagePale,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_knownSqm != null) ...[
            Text(
              l10n.existingApartmentSize(
                _knownSqm!.toStringAsFixed(
                  _knownSqm! == _knownSqm!.roundToDouble() ? 0 : 1,
                ),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: DiraColors.sageDark,
              ),
            ),
            if (_monthlyFeePreview != null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.monthlyFeePreview(currency.format(_monthlyFeePreview)),
                style: const TextStyle(fontSize: 13.5),
              ),
            ],
          ] else if (_requiresSqmInput) ...[
            Text(
              l10n.apartmentSizeRequired,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: DiraColors.brickDark,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sqm,
              enabled: !_busy && !_extractingSqm,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) {
                final sqm = double.tryParse(_sqm.text.trim());
                setState(() {
                  if (sqm != null && _pricePerSqm != null) {
                    _monthlyFeePreview = (sqm * _pricePerSqm!).ceilToDouble();
                  }
                });
              },
              decoration: InputDecoration(
                labelText: l10n.apartmentSizeSqm,
                suffixText: locale == 'he' ? 'מ"ר' : 'm²',
                isDense: true,
              ),
            ),
            if (_monthlyFeePreview != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.monthlyFeePreviewPerSqm(
                  currency.format(_monthlyFeePreview),
                  _effectiveSqm?.toStringAsFixed(0) ?? '',
                  currency.format(_pricePerSqm ?? 0),
                ),
                style: const TextStyle(fontSize: 12.5, color: DiraColors.inkSoft),
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tenantProfileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DiraColors.sagePale,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.apartment, color: DiraColors.sageDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.buildingName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: DiraColors.sageDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.tenantProfileHint,
              style: const TextStyle(
                color: DiraColors.inkSoft,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.fullName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.emailOptional),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _apartment,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.yourApartmentNumber,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _floor,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: l10n.floorLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _feePreviewCard(context),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _occupants,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: l10n.numOccupantsLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ParkingSpotsField(
            onChanged: (spots) => setState(() => _parkingSpots = spots),
          ),
          const SizedBox(height: 20),
          Text(
            widget.requireDocs || _requiresSqmInput
                ? l10n.docsSectionRequired
                : l10n.docsSection,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: DiraColors.brickDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.docsExplain,
            style: const TextStyle(
              color: DiraColors.inkSoft,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _DocButton(
            file: _arnonaDoc,
            label: l10n.attachArnona,
            hint: l10n.arnonaHint,
            required: widget.requireDocs || _requiresSqmInput,
            busy: _busy || _extractingSqm,
            onPick: _onArnonaPicked,
          ),
          if (_extractingSqm)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(color: DiraColors.brick),
            ),
          const SizedBox(height: 10),
          _DocButton(
            file: _residenceDoc,
            label: l10n.attachResidence,
            hint: l10n.residenceHint,
            required: widget.requireDocs,
            busy: _busy,
            onPick: () => _pickDoc((f) => _residenceDoc = f),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy || !_valid ? null : _submit,
            child: Text(_busy ? l10n.pleaseWait : l10n.sendJoinRequest),
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

/// A labeled document slot: title, one-line explanation of why it's
/// needed, and a check mark once a file was picked.
class _DocButton extends StatelessWidget {
  final PlatformFile? file;
  final String label;
  final String hint;
  final bool required;
  final bool busy;
  final VoidCallback onPick;

  const _DocButton({
    required this.file,
    required this.label,
    required this.hint,
    required this.required,
    required this.busy,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final picked = file != null;
    return InkWell(
      onTap: busy ? null : onPick,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: picked ? DiraColors.sagePale : DiraColors.creamCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: picked ? DiraColors.sageDark : DiraColors.brick,
            width: picked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              picked ? Icons.check_circle : Icons.upload_file_rounded,
              color: picked ? DiraColors.sageDark : DiraColors.brick,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    required ? label : '$label (${context.l10n.optional})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: picked ? DiraColors.sageDark : DiraColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    picked ? file!.name : hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DiraColors.inkSoft,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
