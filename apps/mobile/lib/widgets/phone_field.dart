import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// The one phone input for the whole app: flag + dial-code picker,
/// as-you-type grouping (054-776-0683), and inline validation. Reports
/// the composed E.164 number (leading local 0 stripped) via [onChanged].
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

  /// Shared validity rule used by every screen that collects a phone.
  /// Israeli numbers must be +972 followed by 8–9 digits; other
  /// countries get the generic E.164 envelope (8–15 digits).
  /// Human-friendly rendering of a stored E.164 number,
  /// e.g. +972547760683 → 054-776-0683.
  static String formatDisplay(String e164) {
    if (e164.startsWith('+972')) {
      final local = '0${e164.substring(4)}';
      if (local.length == 10) {
        return '${local.substring(0, 3)}-${local.substring(3, 6)}-${local.substring(6)}';
      }
      return local;
    }
    return e164;
  }

  static bool isValid(String e164) {
    if (!RegExp(r'^\+\d{8,15}$').hasMatch(e164)) return false;
    if (e164.startsWith('+972')) {
      return RegExp(r'^\+972[2-9]\d{7,8}$').hasMatch(e164);
    }
    return true;
  }

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  _Country _country = _countries.first;
  final _local = TextEditingController();
  bool _touched = false;

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
          _local.text = _formatLocal(c.iso, digits.substring(c.dial.length));
          break;
        }
      }
    }
  }

  /// Groups local digits for display: 054-776-0683 for Israel,
  /// space-separated triplets elsewhere.
  static String _formatLocal(String iso, String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 15 ? digits.substring(0, 15) : digits;
    if (capped.isEmpty) return '';
    if (iso == 'IL') {
      final head = capped.startsWith('0') ? 3 : 2;
      final parts = <String>[
        capped.substring(0, capped.length < head ? capped.length : head),
        if (capped.length > head)
          capped.substring(head, capped.length < head + 3 ? capped.length : head + 3),
        if (capped.length > head + 3)
          capped.substring(
            head + 3,
            capped.length < head + 7 ? capped.length : head + 7,
          ),
      ];
      return parts.join('-');
    }
    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(' ');
      buf.write(capped[i]);
    }
    return buf.toString();
  }

  String get _e164 {
    final digits = _local.text
        .replaceAll(RegExp(r'\D'), '')
        .replaceFirst(RegExp(r'^0+'), '');
    return digits.isEmpty ? '' : '+${_country.dial}$digits';
  }

  void _emit() => widget.onChanged(_e164);

  void _reformat() {
    final formatted = _formatLocal(_country.iso, _local.text);
    if (formatted != _local.text) {
      _local.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() => _touched = true);
    _emit();
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
      _reformat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showError =
        _touched && _local.text.trim().isNotEmpty && !PhoneField.isValid(_e164);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s-]')),
              ],
              onChanged: (_) => _reformat(),
              decoration: InputDecoration(
                labelText: widget.label ?? context.l10n.phoneNumber,
                hintText: _country.iso == 'IL' ? '054-776-0683' : null,
                errorText: showError ? context.l10n.invalidPhone : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
