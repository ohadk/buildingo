import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/location_address.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Official Israel data.gov.il city → street pickers so Vaad onboarding
/// stores the same locality/street names as the national registry.
/// Non-Israel countries use free-text city/street fields.
class IsraelGovAddressFields extends StatefulWidget {
  final TextEditingController country;
  final TextEditingController city;
  final TextEditingController street;
  final TextEditingController houseNumber;
  final TextEditingController postal;
  final TextEditingController? district;
  final VoidCallback onChanged;

  /// When non-null, [isValid] is called whenever selection state changes.
  final ValueChanged<bool>? onValidityChanged;

  /// Optional subtitle shown above the country chips (step copy).
  final String? subtitle;

  /// When true (default), try GPS reverse-geocode once if city is empty.
  final bool autofillFromLocation;

  const IsraelGovAddressFields({
    super.key,
    required this.country,
    required this.city,
    required this.street,
    required this.houseNumber,
    required this.postal,
    this.district,
    required this.onChanged,
    this.onValidityChanged,
    this.subtitle,
    this.autofillFromLocation = true,
  });

  static const israel = 'ישראל';
  static const usa = 'USA';
  static const other = 'Other';

  /// Combined street + house number for `buildings.address`.
  static String composeAddress(String street, String houseNumber) {
    final s = street.trim();
    final n = houseNumber.trim();
    if (s.isEmpty) return n;
    if (n.isEmpty) return s;
    return '$s $n';
  }

  /// Full display line for the summary pin card.
  static String composeFullAddress({
    required String street,
    required String houseNumber,
    required String city,
    String? district,
    required String country,
    String? postal,
  }) {
    final parts = <String>[
      composeAddress(street, houseNumber),
      if (city.trim().isNotEmpty) city.trim(),
      if (district != null && district.trim().isNotEmpty) district.trim(),
      if (postal != null && postal.trim().isNotEmpty) postal.trim(),
      if (country.trim().isNotEmpty && country.trim() != israel) country.trim(),
    ];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  @override
  State<IsraelGovAddressFields> createState() => _IsraelGovAddressFieldsState();
}

class _IsraelGovAddressFieldsState extends State<IsraelGovAddressFields>
    with AutomaticKeepAliveClientMixin {
  Timer? _debounce;
  List<String> _citySuggestions = [];
  List<String> _streetSuggestions = [];
  String? _selectedCity;
  String? _selectedStreet;
  bool _locating = false;
  bool _didAutoLocate = false;
  String? _locationNote;
  bool _locationNoteIsError = false;

  @override
  bool get wantKeepAlive => true;

  bool get _isIsrael =>
      widget.country.text.trim() == IsraelGovAddressFields.israel;

  bool get _valid {
    if (!_isIsrael) {
      return widget.city.text.trim().length >= 2 &&
          IsraelGovAddressFields.composeAddress(
                widget.street.text,
                widget.houseNumber.text,
              ).length >=
              2;
    }
    return _selectedCity != null &&
        _selectedStreet != null &&
        widget.houseNumber.text.trim().isNotEmpty;
  }

  void _hydrateSelectionFromControllers() {
    final city = widget.city.text.trim();
    final street = widget.street.text.trim();
    if (city.isNotEmpty) _selectedCity = city;
    if (_selectedCity != null && street.isNotEmpty) _selectedStreet = street;
  }

  @override
  void initState() {
    super.initState();
    if (widget.country.text.trim().isEmpty) {
      widget.country.text = IsraelGovAddressFields.israel;
    }
    _hydrateSelectionFromControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitValidity();
      if (widget.autofillFromLocation &&
          !_didAutoLocate &&
          widget.city.text.trim().isEmpty) {
        _prefillFromLocation(automatic: true);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _emitValidity() {
    widget.onValidityChanged?.call(_valid);
    widget.onChanged();
  }

  void _debounced(void Function() run) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), run);
  }

  Future<void> _prefillFromLocation({required bool automatic}) async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationNote = null;
      if (automatic) _didAutoLocate = true;
    });

    try {
      if (widget.country.text.trim().isEmpty) {
        widget.country.text = IsraelGovAddressFields.israel;
      }

      final resolved = await resolveDeviceAddress();
      if (!mounted) return;
      if (resolved == null) {
        setState(() {
          _locating = false;
          if (!automatic) {
            _locationNote = context.l10n.locationUnavailable;
            _locationNoteIsError = true;
          }
        });
        return;
      }

      if (!resolved.isIsrael) {
        setState(() {
          _locating = false;
          _locationNote = context.l10n.locationOutsideIsrael;
          _locationNoteIsError = true;
        });
        return;
      }

      widget.country.text = IsraelGovAddressFields.israel;

      final rawCity = resolved.city;
      final rawStreet = resolved.street;
      String? govCity;
      String? govStreet;
      if (rawCity != null) {
        govCity = await matchGovCity(rawCity);
      }
      if (govCity != null && rawStreet != null) {
        govStreet = await matchGovStreet(rawStreet, govCity);
      }
      if (!mounted) return;

      setState(() {
        _citySuggestions = [];
        _streetSuggestions = [];
        if (govCity != null) {
          _selectedCity = govCity;
          widget.city.text = govCity;
        } else if (rawCity != null && rawCity.isNotEmpty) {
          _selectedCity = null;
          widget.city.text = rawCity;
          _suggestCities(rawCity);
        }
        if (govStreet != null) {
          _selectedStreet = govStreet;
          widget.street.text = govStreet;
        } else if (rawStreet != null &&
            rawStreet.isNotEmpty &&
            (govCity != null || rawCity != null)) {
          _selectedStreet = null;
          widget.street.text = rawStreet;
          if (govCity != null) _suggestStreets(rawStreet);
        }
        if (resolved.houseNumber != null &&
            resolved.houseNumber!.isNotEmpty &&
            widget.houseNumber.text.trim().isEmpty) {
          widget.houseNumber.text = resolved.houseNumber!;
        }
        if (resolved.postalCode != null &&
            resolved.postalCode!.isNotEmpty &&
            widget.postal.text.trim().isEmpty) {
          widget.postal.text = resolved.postalCode!;
        }
        final district = widget.district;
        if (district != null &&
            district.text.trim().isEmpty &&
            resolved.district != null &&
            resolved.district!.isNotEmpty) {
          district.text = resolved.district!;
        }
        _locating = false;
        _locationNote = context.l10n.locationFilledHint;
        _locationNoteIsError = false;
      });
      _emitValidity();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        if (!automatic) {
          _locationNote = context.l10n.locationUnavailable;
          _locationNoteIsError = true;
        }
      });
    }
  }

  Future<void> _suggestCities(String q) async {
    if (!_isIsrael || q.trim().length < 3) {
      if (mounted) setState(() => _citySuggestions = []);
      return;
    }
    try {
      final res = await api.get(
        '/api/geo/cities?q=${Uri.encodeComponent(q.trim())}',
      );
      if (!mounted || widget.city.text.trim() != q.trim()) return;
      setState(() {
        _citySuggestions = ((res['cities'] ?? []) as List)
            .map((e) => e.toString())
            .toList();
      });
    } on ApiException {
      if (mounted) setState(() => _citySuggestions = []);
    }
  }

  Future<void> _suggestStreets(String q) async {
    final city = _selectedCity;
    if (!_isIsrael || city == null || q.trim().length < 3) {
      if (mounted) setState(() => _streetSuggestions = []);
      return;
    }
    try {
      final res = await api.get(
        '/api/geo/streets?q=${Uri.encodeComponent(q.trim())}'
        '&city=${Uri.encodeComponent(city)}',
      );
      if (!mounted || widget.street.text.trim() != q.trim()) return;
      setState(() {
        _streetSuggestions = ((res['streets'] ?? []) as List)
            .map((e) => e.toString())
            .toList();
      });
    } on ApiException {
      if (mounted) setState(() => _streetSuggestions = []);
    }
  }

  void _pickCity(String city) {
    setState(() {
      _selectedCity = city;
      widget.city.text = city;
      _citySuggestions = [];
      _selectedStreet = null;
      widget.street.clear();
      _streetSuggestions = [];
      widget.houseNumber.clear();
      _locationNote = null;
    });
    _emitValidity();
  }

  void _pickStreet(String street) {
    setState(() {
      _selectedStreet = street;
      widget.street.text = street;
      _streetSuggestions = [];
      _locationNote = null;
    });
    _emitValidity();
  }

  void _setCountry(String value) {
    if (widget.country.text == value) return;
    setState(() {
      widget.country.text = value;
      _citySuggestions = [];
      _streetSuggestions = [];
      _locationNote = null;
      if (value == IsraelGovAddressFields.israel) {
        _selectedCity = null;
        _selectedStreet = null;
        widget.city.clear();
        widget.street.clear();
        widget.houseNumber.clear();
      } else {
        _selectedCity = widget.city.text.trim().isEmpty
            ? null
            : widget.city.text.trim();
        _selectedStreet = widget.street.text.trim().isEmpty
            ? null
            : widget.street.text.trim();
      }
    });
    _emitValidity();
  }

  String get _summaryLine => IsraelGovAddressFields.composeFullAddress(
        street: widget.street.text,
        houseNumber: widget.houseNumber.text,
        city: widget.city.text,
        district: widget.district?.text,
        country: widget.country.text,
        postal: widget.postal.text,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final subtitle = widget.subtitle ?? l10n.createBuildingPlaceSubtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.country,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CountryChip(
                label: l10n.countryIsrael,
                selected: _isIsrael,
                onTap: () => _setCountry(IsraelGovAddressFields.israel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CountryChip(
                label: l10n.countryUsa,
                selected:
                    widget.country.text.trim() == IsraelGovAddressFields.usa,
                onTap: () => _setCountry(IsraelGovAddressFields.usa),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CountryChip(
                label: l10n.countryOther,
                selected:
                    widget.country.text.trim() == IsraelGovAddressFields.other,
                onTap: () => _setCountry(IsraelGovAddressFields.other),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _locating
                ? null
                : () => _prefillFromLocation(automatic: false),
            icon: _locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(
              _locating ? l10n.locatingAddress : l10n.useMyLocation,
            ),
            style: TextButton.styleFrom(
              foregroundColor: DiraColors.brickDark,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        if (_locationNote != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _locationNoteIsError
                  ? DiraColors.terracottaSoft
                  : DiraColors.sagePale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _locationNote!,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: _locationNoteIsError
                    ? DiraColors.brickDark
                    : DiraColors.sageDeep,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (widget.district != null) ...[
          _LabeledField(
            label: l10n.districtOptional,
            child: TextField(
              controller: widget.district,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _emitValidity(),
              decoration: const InputDecoration(hintText: '…'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_isIsrael) ...[
          _LabeledField(
            label: l10n.city,
            child: TextField(
              controller: widget.city,
              textInputAction: TextInputAction.next,
              onChanged: (v) {
                setState(() {
                  _selectedCity = null;
                  _selectedStreet = null;
                  widget.street.clear();
                  widget.houseNumber.clear();
                  _streetSuggestions = [];
                  _locationNote = null;
                });
                _debounced(() => _suggestCities(v));
                _emitValidity();
              },
              decoration: InputDecoration(
                hintText: l10n.pickFromGovList,
                suffixIcon: _selectedCity != null
                    ? const Icon(Icons.check_circle, color: DiraColors.sage)
                    : null,
              ),
            ),
          ),
          _SuggestionList(items: _citySuggestions, onPick: _pickCity),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LabeledField(
                      label: l10n.streetLabel,
                      child: TextField(
                        controller: widget.street,
                        enabled: _selectedCity != null,
                        textInputAction: TextInputAction.next,
                        onChanged: (v) {
                          setState(() {
                            _selectedStreet = null;
                            _locationNote = null;
                          });
                          _debounced(() => _suggestStreets(v));
                          _emitValidity();
                        },
                        decoration: InputDecoration(
                          hintText: _selectedCity == null
                              ? l10n.pickCityFirst
                              : l10n.pickFromGovList,
                          suffixIcon: _selectedStreet != null
                              ? const Icon(
                                  Icons.check_circle,
                                  color: DiraColors.sage,
                                )
                              : null,
                        ),
                      ),
                    ),
                    _SuggestionList(
                      items: _streetSuggestions,
                      onPick: _pickStreet,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _LabeledField(
                  label: l10n.houseNumberLabel,
                  child: TextField(
                    controller: widget.houseNumber,
                    enabled: _selectedStreet != null,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9A-Za-zא-ת\-/\s]'),
                      ),
                    ],
                    onChanged: (_) => _emitValidity(),
                    decoration: InputDecoration(
                      hintText:
                          _selectedStreet == null ? l10n.pickStreetFirst : '…',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          _LabeledField(
            label: l10n.city,
            child: TextField(
              controller: widget.city,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _emitValidity(),
              decoration: const InputDecoration(hintText: '…'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _LabeledField(
                  label: l10n.streetLabel,
                  child: TextField(
                    controller: widget.street,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _emitValidity(),
                    decoration: const InputDecoration(hintText: '…'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _LabeledField(
                  label: l10n.houseNumberLabel,
                  child: TextField(
                    controller: widget.houseNumber,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _emitValidity(),
                    decoration: const InputDecoration(hintText: '…'),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _LabeledField(
          label: l10n.postalCodeOptional,
          child: TextField(
            controller: widget.postal,
            keyboardType: TextInputType.number,
            onChanged: (_) => _emitValidity(),
            decoration: const InputDecoration(hintText: '…'),
          ),
        ),
        if (_summaryLine.isNotEmpty) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: DiraColors.creamCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: DiraColors.brick,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _summaryLine,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DiraColors.ink,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CountryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CountryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DiraColors.sage : DiraColors.creamCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? DiraColors.sage : DiraColors.creamDeep,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: selected ? DiraColors.creamCard : DiraColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SuggestionList extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onPick;

  const _SuggestionList({required this.items, required this.onPick});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              dense: true,
              title: Text(items[i]),
              onTap: () => onPick(items[i]),
            ),
          ],
        ],
      ),
    );
  }
}
