import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Self-service building creation: the signing-up Vaad fills in the
/// address and fee model, becomes the building's committee, and gets a
/// WhatsApp-shareable join link for the residents.
class CreateBuildingScreen extends StatefulWidget {
  const CreateBuildingScreen({super.key});

  @override
  State<CreateBuildingScreen> createState() => _CreateBuildingScreenState();
}

class _CreateBuildingScreenState extends State<CreateBuildingScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _country = TextEditingController(text: 'ישראל');
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _postal = TextEditingController();
  final _aptCount = TextEditingController();
  final _perFloor = TextEditingController(text: '2');
  final _fee = TextEditingController();
  final _myApt = TextEditingController();
  String _feeMethod = 'fixed';
  bool _busy = false;
  String? _error;

  bool get _valid =>
      _name.text.trim().length >= 2 &&
      _city.text.trim().length >= 2 &&
      _address.text.trim().length >= 2 &&
      (int.tryParse(_aptCount.text) ?? 0) > 0 &&
      (int.tryParse(_perFloor.text) ?? 0) > 0 &&
      (double.tryParse(_fee.text) ?? -1) >= 0;

  Future<void> _submit() async {
    final session = context.read<SessionController>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final fee = double.parse(_fee.text);
      final joinLink = await session.createBuilding({
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'country': _country.text.trim(),
        if (_postal.text.trim().isNotEmpty) 'postalCode': _postal.text.trim(),
        'apartmentCount': int.parse(_aptCount.text),
        'apartmentsPerFloor': int.parse(_perFloor.text),
        'feeMethod': _feeMethod,
        if (_feeMethod == 'fixed') 'fixedMonthlyFee': fee,
        if (_feeMethod == 'per_sqm') 'pricePerSqm': fee,
        if (int.tryParse(_myApt.text) != null)
          'myApartmentNumber': int.parse(_myApt.text),
        'fullName': _name.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      });
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          joinLink: joinLink,
          buildingName: session.building?.name ?? '',
        ),
      );
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createBuildingTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 14-day free trial notice — the app is a paid product.
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: DiraColors.goldLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: DiraColors.goldDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.trialNotice,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: DiraColors.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
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
            decoration: InputDecoration(labelText: l10n.emailOptional),
          ),
          const SizedBox(height: 12),
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
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _postal,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.postalCodeOptional),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aptCount,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: l10n.apartmentsCount),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _perFloor,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.apartmentsPerFloor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.feeMethodLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: DiraColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'fixed', label: Text(l10n.feeFixed)),
              ButtonSegment(value: 'per_sqm', label: Text(l10n.feePerSqm)),
            ],
            selected: {_feeMethod},
            onSelectionChanged: (s) => setState(() => _feeMethod = s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: DiraColors.terracottaSoft,
              selectedForegroundColor: DiraColors.brickDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fee,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _feeMethod == 'fixed'
                  ? l10n.monthlyAmount
                  : l10n.pricePerSqmLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _myApt,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.myApartmentOptional),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _busy || !_valid ? null : _submit,
            child: Text(_busy ? l10n.pleaseWait : l10n.createMyBuilding),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: DiraColors.brick),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final String joinLink;
  final String buildingName;
  const _SuccessDialog({required this.joinLink, required this.buildingName});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: DiraColors.creamCard,
      title: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: DiraColors.sageLight,
            child: Icon(
              Icons.check_rounded,
              size: 34,
              color: DiraColors.sageDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.buildingCreated,
            textAlign: TextAlign.center,
            style: heading(fontSize: 20),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.shareJoinLink,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DiraColors.inkSoft),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: joinLink));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.joinLinkCopied)),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DiraColors.creamDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      joinLink,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.copy, size: 16, color: DiraColors.inkSoft),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
            ),
            onPressed: () {
              final text = context.l10n.shareJoinMessage(
                buildingName,
                joinLink,
              );
              launchUrl(
                Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'),
                mode: LaunchMode.externalApplication,
              );
            },
            icon: const Icon(Icons.chat),
            label: Text(l10n.shareOnWhatsapp),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.continueLabel),
        ),
      ],
    );
  }
}
