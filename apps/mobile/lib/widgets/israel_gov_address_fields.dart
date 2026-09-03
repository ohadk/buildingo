import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/building_address.dart';
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

  /// When true (create-building), block Continue if this address already
  /// has an active building.
  final bool checkDuplicateBuilding;

  /// Fired once when a duplicate active building is detected at this address.
  final ValueChanged<String>? onDuplicateBuilding;

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
    this.checkDuplicateBuilding = false,
    this.onDuplicateBuilding,
  });

  static const israel = 'ישראל';
  static const usa = 'USA';
  static const other = 'Other';

  /// Combined street + house number for `buildings.address`.
  /// Delegates to [BuildingAddress] (client twin of server canonicalize).
  static String composeAddress(String street, String houseNumber) =>
      BuildingAddress.composeAddress(street, houseNumber);

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
  Timer? _dupDebounce;
  List<String> _citySuggestions = [];
  List<String> _streetSuggestions = [];
  String? _selectedCity;
  String? _selectedStreet;
  bool _locating = false;
  bool _didAutoLocate = false;
  String? _locationNote;
  bool _locationNoteIsError = false;
  bool _checkingDuplicate = false;
  String? _duplicateBuildingName;
  bool _lookingUpZip = false;
  String? _lastZipLookupKey;
  String? _zipNote;

  @override
  bool get wantKeepAlive => true;

  bool get _isIsrael =>
      widget.country.text.trim() == IsraelGovAddressFields.israel;

  bool get _addressComplete {
    final city = (_selectedCity ?? widget.city.text).trim();
    final street = (_selectedStreet ?? widget.street.text).trim();
    final house = widget.houseNumber.text.trim();
    if (!_isIsrael) {
      return city.length >= 2 &&
          IsraelGovAddressFields.composeAddress(street, house).length >= 2;
    }
    // City + street + house are enough to continue. Official-list picks are
    // preferred (checkmarks) but GPS / free text must not block Continue.
    return city.length >= 2 && street.isNotEmpty && house.isNotEmpty;
  }

  String get _zipLookupKey {
    final city = _isIsrael
        ? (_selectedCity ?? widget.city.text.trim())
        : widget.city.text.trim();
    final address = IsraelGovAddressFields.composeAddress(
      widget.street.text,
      widget.houseNumber.text,
    );
    return '${widget.country.text.trim()}|$city|$address';
  }

  bool get _canLookupZip {
    final city = widget.city.text.trim();
    final street = widget.street.text.trim();
    final house = widget.houseNumber.text.trim();
    return city.length >= 2 && street.isNotEmpty && house.isNotEmpty;
  }

  bool get _showFindZipButton =>
      _canLookupZip &&
      !_lookingUpZip &&
      (_lastZipLookupKey != _zipLookupKey ||
          widget.postal.text.trim().isEmpty);

  bool get _valid =>
      _addressComplete && _duplicateBuildingName == null;

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
      if (widget.checkDuplicateBuilding) _scheduleDuplicateCheck();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _dupDebounce?.cancel();
    super.dispose();
  }

  void _emitValidity() {
    // Clear a prior duplicate hit as soon as the address changes so Continue
    // isn't stuck on a stale warning while we re-check.
    if (_duplicateBuildingName != null) {
      setState(() => _duplicateBuildingName = null);
    }
    widget.onValidityChanged?.call(_valid);
    widget.onChanged();
    if (widget.checkDuplicateBuilding) _scheduleDuplicateCheck();
  }

  void _scheduleDuplicateCheck() {
    if (!widget.checkDuplicateBuilding) return;
    _dupDebounce?.cancel();
    _dupDebounce = Timer(const Duration(milliseconds: 420), _checkDuplicate);
  }

  Future<void> _checkDuplicate() async {
    if (!widget.checkDuplicateBuilding || !mounted) return;
    if (!_addressComplete) {
      if (_duplicateBuildingName != null || _checkingDuplicate) {
        setState(() {
          _duplicateBuildingName = null;
          _checkingDuplicate = false;
        });
        widget.onValidityChanged?.call(_valid);
      }
      return;
    }

    final city = _isIsrael
        ? (_selectedCity ?? widget.city.text.trim())
        : widget.city.text.trim();
    final address = IsraelGovAddressFields.composeAddress(
      widget.street.text,
      widget.houseNumber.text,
    );
    String currentCity() => _isIsrael
        ? (_selectedCity ?? widget.city.text.trim())
        : widget.city.text.trim();
    setState(() => _checkingDuplicate = true);
    widget.onValidityChanged?.call(_valid);

    try {
      final res = await api.get(
        '/api/buildings/search'
        '?city=${Uri.encodeComponent(city)}'
        '&address=${Uri.encodeComponent(address)}'
        '&country=${Uri.encodeComponent(widget.country.text.trim())}'
        '&exact=1',
      );
      if (!mounted) return;
      // Stale response if user kept typing.
      final still = IsraelGovAddressFields.composeAddress(
            widget.street.text,
            widget.houseNumber.text,
          ) ==
          address &&
          currentCity() == city;
      if (!still) {
        // Superseded by a newer edit — that request owns the spinner.
        return;
      }

      final buildings = ((res['buildings'] ?? []) as List)
          .whereType<Map>()
          .toList();
      // exact=1 resolves via address_hash — any hit is the same building.
      final hit = buildings.isEmpty ? null : buildings.first;
      final hitName =
          hit == null ? null : (hit['name'] ?? address).toString();
      final newlyDetected =
          hitName != null && hitName != _duplicateBuildingName;

      setState(() {
        _checkingDuplicate = false;
        _duplicateBuildingName = hitName;
      });
      widget.onValidityChanged?.call(_valid);
      if (newlyDetected) {
        widget.onDuplicateBuilding?.call(hitName);
      }
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _checkingDuplicate = false;
        // Don't block create if search fails — server still guards on submit.
        _duplicateBuildingName = null;
      });
      widget.onValidityChanged?.call(_valid);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingDuplicate = false;
        _duplicateBuildingName = null;
      });
      widget.onValidityChanged?.call(_valid);
    }
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
        // Always populate + mark selected so Continue can enable after GPS.
        final cityValue = (govCity ?? rawCity)?.trim();
        if (cityValue != null && cityValue.isNotEmpty) {
          _selectedCity = cityValue;
          widget.city.text = cityValue;
          if (govCity == null) _suggestCities(cityValue);
        }
        final streetValue = (govStreet ?? rawStreet)?.trim();
        if (streetValue != null && streetValue.isNotEmpty) {
          _selectedStreet = streetValue;
          widget.street.text = streetValue;
          if (govStreet == null && _selectedCity != null) {
            _suggestStreets(streetValue);
          }
        }
        final house = resolved.houseNumber?.trim();
        if (house != null && house.isNotEmpty) {
          widget.houseNumber.text = house;
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
      if (_addressComplete) _maybeLookupZip(automatic: true);
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

  Future<void> _maybeLookupZip({required bool automatic}) async {
    if (!_canLookupZip || _lookingUpZip) return;
    final key = _zipLookupKey;
    if (automatic) {
      if (widget.postal.text.trim().isNotEmpty && _lastZipLookupKey == key) {
        return;
      }
      // Auto only when postal is empty (don't overwrite a typed value).
      if (widget.postal.text.trim().isNotEmpty) return;
    }
    await _lookupZip();
  }

  Future<void> _lookupZip() async {
    if (!_canLookupZip || _lookingUpZip) return;
    final key = _zipLookupKey;
    final city = _isIsrael
        ? (_selectedCity ?? widget.city.text.trim())
        : widget.city.text.trim();
    setState(() {
      _lookingUpZip = true;
      _zipNote = null;
    });
    try {
      final res = await api.post('/api/geo/zip', {
        'street': widget.street.text.trim(),
        'houseNumber': widget.houseNumber.text.trim(),
        'city': city,
        'country': widget.country.text.trim(),
        if (widget.district != null && widget.district!.text.trim().isNotEmpty)
          'district': widget.district!.text.trim(),
      });
      if (!mounted) return;
      if (_zipLookupKey != key) {
        setState(() => _lookingUpZip = false);
        return;
      }
      final zip = res['zip']?.toString().trim();
      final err = res['error']?.toString();
      setState(() {
        _lookingUpZip = false;
        _lastZipLookupKey = key;
        if (zip != null && zip.isNotEmpty) {
          widget.postal.text = zip;
          _zipNote = null;
        } else if (err == 'missing_api_key' || err == 'llm_failed') {
          _zipNote = context.l10n.zipLookupUnavailable;
        } else {
          _zipNote = context.l10n.zipLookupFailed;
        }
      });
      widget.onChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _lookingUpZip = false;
        _zipNote = e.status >= 500
            ? context.l10n.zipLookupUnavailable
            : context.l10n.zipLookupFailed;
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
    final city = (_selectedCity ?? widget.city.text).trim();
    if (!_isIsrael || city.length < 2 || q.trim().length < 3) {
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
      _zipNote = null;
    });
    _emitValidity();
  }

  void _pickStreet(String street) {
    setState(() {
      _selectedStreet = street;
      widget.street.text = street;
      _streetSuggestions = [];
      _locationNote = null;
      _zipNote = null;
    });
    _emitValidity();
    if (_addressComplete) _maybeLookupZip(automatic: true);
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
                  // Keep street/house so the user can tweak city without
                  // wiping the whole address; they re-confirm via the list.
                  _streetSuggestions = [];
                  _locationNote = null;
                  _duplicateBuildingName = null;
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
                        textInputAction: TextInputAction.next,
                        onChanged: (v) {
                          setState(() {
                            _selectedStreet = null;
                            _locationNote = null;
                            _duplicateBuildingName = null;
                          });
                          _debounced(() => _suggestStreets(v));
                          _emitValidity();
                        },
                        decoration: InputDecoration(
                          hintText: l10n.pickFromGovList,
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
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9A-Za-zא-ת\-/\s]'),
                      ),
                    ],
                    onChanged: (_) {
                      setState(() {
                        _duplicateBuildingName = null;
                        _zipNote = null;
                      });
                      _emitValidity();
                      if (_addressComplete) {
                        _maybeLookupZip(automatic: true);
                      }
                    },
                    decoration: const InputDecoration(hintText: '…'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: widget.postal,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() => _zipNote = null);
                  _emitValidity();
                },
                decoration: InputDecoration(
                  hintText: '…',
                  suffixIcon: _lookingUpZip
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              if (_showFindZipButton || _lookingUpZip) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _lookingUpZip
                        ? null
                        : () => _lookupZip(),
                    icon: const Icon(Icons.markunread_mailbox_outlined, size: 18),
                    label: Text(
                      _lookingUpZip ? l10n.lookingUpZip : l10n.findZipCode,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: DiraColors.brickDark,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
              if (_zipNote != null) ...[
                const SizedBox(height: 6),
                Text(
                  _zipNote!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: DiraColors.brickDark,
                  ),
                ),
              ],
            ],
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
                if (_checkingDuplicate)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ],
        if (_duplicateBuildingName != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: DiraColors.terracottaSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DiraColors.brick.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: DiraColors.brick),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.addressAlreadyRegistered(_duplicateBuildingName!),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: DiraColors.brickDark,
                      fontWeight: FontWeight.w600,
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
