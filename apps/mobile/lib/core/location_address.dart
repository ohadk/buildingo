import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'api_client.dart';

/// Reverse-geocoded placemark fields we care about for onboarding.
class ResolvedDeviceAddress {
  const ResolvedDeviceAddress({
    this.countryCode,
    this.city,
    this.street,
    this.houseNumber,
    this.postalCode,
    this.district,
  });

  final String? countryCode;
  final String? city;
  final String? street;
  final String? houseNumber;
  final String? postalCode;
  final String? district;

  bool get isIsrael =>
      (countryCode ?? '').toUpperCase() == 'IL' ||
      (countryCode ?? '') == 'ישראל';
}

/// Current GPS → placemark. Returns null when permission/service unavailable.
Future<ResolvedDeviceAddress?> resolveDeviceAddress() async {
  final serviceOn = await Geolocator.isLocationServiceEnabled();
  if (!serviceOn) return null;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 12),
    ),
  );

  // Prefer Hebrew placenames so they match data.gov.il spelling.
  final geocoder = Geocoding(locale: const Locale('he', 'IL'));
  final marks = await geocoder.placemarkFromCoordinates(
    pos.latitude,
    pos.longitude,
  );
  if (marks.isEmpty) return null;
  final p = marks.first;

  final city = _firstNonEmpty([
    p.locality,
    p.subLocality,
    p.subAdministrativeArea,
  ]);
  final street = _firstNonEmpty([p.thoroughfare, p.street]);
  final district = _firstNonEmpty([
    p.administrativeArea,
    p.subAdministrativeArea,
  ]);

  return ResolvedDeviceAddress(
    countryCode: p.isoCountryCode ?? p.country,
    city: city,
    street: _stripHouseFromStreet(street, p.subThoroughfare),
    houseNumber: _firstNonEmpty([p.subThoroughfare]),
    postalCode: _firstNonEmpty([p.postalCode]),
    district: district,
  );
}

/// Best official city name from data.gov via our API, or null.
Future<String?> matchGovCity(String raw) async {
  final q = raw.trim();
  if (q.length < 3) return null;
  try {
    final res = await api.get(
      '/api/geo/cities?q=${Uri.encodeComponent(q)}',
    );
    final cities = ((res['cities'] ?? []) as List)
        .map((e) => e.toString())
        .toList();
    return _bestMatch(q, cities);
  } on ApiException {
    return null;
  }
}

/// Best official street name for [city], or null.
Future<String?> matchGovStreet(String raw, String city) async {
  final q = raw.trim();
  if (q.length < 3 || city.trim().isEmpty) return null;
  try {
    final res = await api.get(
      '/api/geo/streets?q=${Uri.encodeComponent(q)}'
      '&city=${Uri.encodeComponent(city)}',
    );
    final streets = ((res['streets'] ?? []) as List)
        .map((e) => e.toString())
        .toList();
    return _bestMatch(q, streets);
  } on ApiException {
    return null;
  }
}

String? _firstNonEmpty(List<String?> values) {
  for (final v in values) {
    final t = v?.trim();
    if (t != null && t.isNotEmpty && t.toLowerCase() != 'null') return t;
  }
  return null;
}

/// Apple sometimes puts "Herzl 12" in thoroughfare — drop trailing number
/// when we already have subThoroughfare.
String? _stripHouseFromStreet(String? street, String? house) {
  if (street == null) return null;
  final h = house?.trim();
  if (h == null || h.isEmpty) return street.trim();
  final cleaned =
      street.trim().replaceFirst(RegExp('${RegExp.escape(h)}\$'), '').trim();
  return cleaned.isEmpty ? street.trim() : cleaned;
}

String _normalize(String s) {
  final buf = StringBuffer();
  for (final rune in s.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    if (RegExp(r'[a-z0-9א-ת]').hasMatch(ch)) buf.write(ch);
  }
  return buf.toString();
}

String? _bestMatch(String query, List<String> options) {
  if (options.isEmpty) return null;
  final nq = _normalize(query);
  if (nq.isEmpty) return options.first;
  for (final o in options) {
    if (_normalize(o) == nq) return o;
  }
  for (final o in options) {
    final no = _normalize(o);
    if (no.startsWith(nq) || nq.startsWith(no)) return o;
  }
  for (final o in options) {
    final no = _normalize(o);
    if (no.contains(nq) || nq.contains(no)) return o;
  }
  final token = query.trim().split(RegExp(r'\s+')).first;
  if (token.length >= 2) {
    final nt = _normalize(token);
    for (final o in options) {
      final no = _normalize(o);
      if (no.startsWith(nt) || no.contains(nt)) return o;
    }
  }
  return options.first;
}
