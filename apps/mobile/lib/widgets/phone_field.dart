import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

class _Country {
  final String iso;
  final String dial;
  final String nameHe;
  final String nameEn;
  const _Country(this.iso, this.dial, this.nameHe, this.nameEn);

  String get flag =>
      String.fromCharCodes(iso.codeUnits.map((c) => 0x1f1e6 + c - 0x41));

  String name(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'he' ? nameHe : nameEn;
}

const _countries = [
  _Country('IL', '972', 'ישראל', 'Israel'),
  _Country('US', '1', 'ארה״ב / קנדה', 'USA / Canada'),
  _Country('GB', '44', 'בריטניה', 'United Kingdom'),
  _Country('FR', '33', 'צרפת', 'France'),
  _Country('DE', '49', 'גרמניה', 'Germany'),
  _Country('NL', '31', 'הולנד', 'Netherlands'),
  _Country('ES', '34', 'ספרד', 'Spain'),
  _Country('IT', '39', 'איטליה', 'Italy'),
  _Country('GR', '30', 'יוון', 'Greece'),
  _Country('CY', '357', 'קפריסין', 'Cyprus'),
  _Country('RU', '7', 'רוסיה', 'Russia'),
  _Country('UA', '380', 'אוקראינה', 'Ukraine'),
  _Country('GE', '995', 'גאורגיה', 'Georgia'),
  _Country('AU', '61', 'אוסטרליה', 'Australia'),
  _Country('BR', '55', 'ברזיל', 'Brazil'),
  _Country('AR', '54', 'ארגנטינה', 'Argentina'),
  _Country('ZA', '27', 'דרום אפריקה', 'South Africa'),
  _Country('TH', '66', 'תאילנד', 'Thailand'),
];

/// Phone input with a flag + dial-code picker. Reports the composed E.164
/// number (leading local 0 stripped) through [onChanged].
class PhoneField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  /// Overrides the default localized "Phone number" label.
  final String? label;

  /// Pre-fills the field from an existing E.164 number (edit flows).
  final String? initialValue;
  const PhoneField({
    super.key,
    required this.onChanged,
    this.label,
    this.initialValue,
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  _Country _country = _countries.first;
  final _local = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    if (initial != null && initial.startsWith('+')) {
      final digits = initial.substring(1);
      // Longest dial-code prefix wins (e.g. +972 before +9).
      final sorted = [..._countries]
        ..sort((a, b) => b.dial.length.compareTo(a.dial.length));
      for (final c in sorted) {
        if (digits.startsWith(c.dial)) {
          _country = c;
          _local.text = digits.substring(c.dial.length);
          break;
        }
      }
    }
  }

  void _emit() {
    final digits = _local.text
        .replaceAll(RegExp(r'\D'), '')
        .replaceFirst(RegExp(r'^0+'), '');
    widget.onChanged(digits.isEmpty ? '' : '+${_country.dial}$digits');
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<_Country>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _countries
              .map(
                (c) => ListTile(
                  leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                  title: Text(c.name(ctx)),
                  trailing: Text(
                    '+${c.dial}',
                    style: const TextStyle(color: DiraColors.inkSoft),
                  ),
                  selected: c.iso == _country.iso,
                  onTap: () => Navigator.pop(ctx, c),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked != null) {
      setState(() => _country = picked);
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: _pickCountry,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: DiraColors.brick),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_country.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    '+${_country.dial}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _local,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              onChanged: (_) => _emit(),
              decoration: InputDecoration(
                labelText: widget.label ?? context.l10n.phoneNumber,
                hintText: _country.iso == 'IL' ? '054-7760683' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
