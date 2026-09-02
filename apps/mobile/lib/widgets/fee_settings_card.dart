import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Vaad: change building fee method (fixed vs per sqm) and notify residents.
class FeeSettingsCard extends StatefulWidget {
  final Building building;
  const FeeSettingsCard({super.key, required this.building});

  @override
  State<FeeSettingsCard> createState() => _FeeSettingsCardState();
}

class _FeeSettingsCardState extends State<FeeSettingsCard> {
  late String _feeMethod;
  late final TextEditingController _amount;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final b = widget.building;
    _feeMethod = b.feeMethod;
    _amount = TextEditingController(
      text: _feeMethod == 'fixed'
          ? '${b.fixedMonthlyFee?.toStringAsFixed(0) ?? ''}'
          : '${b.pricePerSqm?.toStringAsFixed(2) ?? ''}',
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final parsed = double.tryParse(_amount.text.trim());
    if (parsed == null || parsed <= 0) return;
    setState(() => _busy = true);
    try {
      await api.patch('/api/buildings/${widget.building.id}', {
        'feeMethod': _feeMethod,
        if (_feeMethod == 'fixed') 'fixedMonthlyFee': parsed,
        if (_feeMethod == 'per_sqm') 'pricePerSqm': parsed,
        'notifyResidents': true,
      });
      if (!mounted) return;
      await context.read<SessionController>().refreshMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vaadFeeSaved)),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'fixed', label: Text(l10n.feeFixed)),
            ButtonSegment(value: 'per_sqm', label: Text(l10n.feePerSqm)),
          ],
          selected: {_feeMethod},
          onSelectionChanged: _busy
              ? null
              : (s) => setState(() => _feeMethod = s.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: DiraColors.terracottaSoft,
            selectedForegroundColor: DiraColors.brickDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amount,
          enabled: !_busy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _feeMethod == 'fixed'
                ? l10n.monthlyAmount
                : l10n.pricePerSqmLabel,
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _busy ? null : _save,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(l10n.saveFee),
          ),
        ),
      ],
    );
  }
}
