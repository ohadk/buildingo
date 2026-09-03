import 'dart:convert';

import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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

/// Common Apple/Google English locality names → data.gov.il Hebrew.
const _englishCityToHebrew = <String, String>{
  'petah tikva': 'פתח תקווה',
  'petah tiqwa': 'פתח תקווה',
  'petach tikva': 'פתח תקווה',
  'petach tiqva': 'פתח תקווה',
  'tel aviv': 'תל אביב - יפו',
  'tel aviv-yafo': 'תל אביב - יפו',
  'tel aviv yafo': 'תל אביב - יפו',
  'tel aviv-jaffa': 'תל אביב - יפו',
  'jerusalem': 'ירושלים',
  'haifa': 'חיפה',
  'rishon lezion': 'ראשון לציון',
  'rishon leziyyon': 'ראשון לציון',
  'rishon le zion': 'ראשון לציון',
  'ashdod': 'אשדוד',
  'netanya': 'נתניה',
  'natanya': 'נתניה',
  'beer sheva': 'באר שבע',
  "be'er sheva": 'באר שבע',
  'beersheba': 'באר שבע',
  'holon': 'חולון',
  'bnei brak': 'בני ברק',
  'bnei braq': 'בני ברק',
  'ramat gan': 'רמת גן',
  'rehovot': 'רחובות',
  'ashkelon': 'אשקלון',
  'bat yam': 'בת ים',
  'herzliya': 'הרצליה',
  'herzliyya': 'הרצליה',
  'kfar saba': 'כפר סבא',
  'modiin': 'מודיעין-מכבים-רעות',
  'modi\'in': 'מודיעין-מכבים-רעות',
  'raanana': 'רעננה',
  "ra'anana": 'רעננה',
  'ramla': 'רמלה',
  'lod': 'לוד',
  'nahariya': 'נהריה',
  'nahariyya': 'נהריה',
  'acre': 'עכו',
  'akko': 'עכו',
  'tiberias': 'טבריה',
  'eilat': 'אילת',
  'givatayim': 'גבעתיים',
  'kiryat ono': 'קריית אונו',
  'qiryat ono': 'קריית אונו',
  'hod hasharon': 'הוד השרון',
  'yavne': 'יבנה',
  'ness ziona': 'נס ציונה',
  'nes ziona': 'נס ציונה',
  'ramat hasharon': 'רמת השרון',
  'or yehuda': 'אור יהודה',
  'yehud': 'יהוד-מונוסון',
  'kiryat gat': 'קריית גת',
  'qiryat gat': 'קריית גת',
  'afula': 'עפולה',
  'dimona': 'דימונה',
  'arad': 'ערד',
  'sderot': 'שדרות',
  'kiryat shmona': 'קריית שמונה',
  'um el fahem': 'אום אל-פחם',
  'umm al-fahm': 'אום אל-פחם',
};

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

  // Pass locale on the method — Geocoding({locale:}) currently ignores it.
  const he = Locale('he', 'IL');
  final geocoder = Geocoding();
  var marks = await geocoder.placemarkFromCoordinates(
    pos.latitude,
    pos.longitude,
    locale: he,
  );
  if (marks.isEmpty) return null;
  var p = marks.first;

  var city = _firstNonEmpty([
    p.locality,
    p.subLocality,
    p.subAdministrativeArea,
  ]);
  var street = _firstNonEmpty([p.thoroughfare, p.street]);
  var district = _firstNonEmpty([
    p.administrativeArea,
    p.subAdministrativeArea,
  ]);
  var house = _firstNonEmpty([p.subThoroughfare]);
  // Apple often embeds the house number in the street ("Herzl 12").
  if (house == null || house.isEmpty) {
    final parsed = _splitStreetAndHouse(street);
    street = parsed.$1;
    house = parsed.$2;
  }
  var postal = _firstNonEmpty([p.postalCode]);
  var country = p.isoCountryCode ?? p.country;

  // Prefer Hebrew labels for Israel registry matching.
  city = await _ensureHebrewCity(city, pos.latitude, pos.longitude);
  street = await _ensureHebrewStreet(street, city, pos.latitude, pos.longitude);
  // Re-split after Hebrew street resolve (may still include a number).
  if (house == null || house.isEmpty) {
    final parsed = _splitStreetAndHouse(street);
    street = parsed.$1;
    house = parsed.$2;
  }

  return ResolvedDeviceAddress(
    countryCode: country,
    city: city,
    street: _stripHouseFromStreet(street, house),
    houseNumber: house,
    postalCode: postal,
    district: district == null || _looksLatin(district) ? null : district,
  );
}

/// Best official city name from data.gov via our API, or null.
Future<String?> matchGovCity(String raw) async {
  final mapped = _mapEnglishCity(raw);
  final q = (mapped ?? raw).trim();
  if (q.length < 2) return null;
  // Short Hebrew names (e.g. לוד) still need a hit; API min is 3 — pad search.
  final searchQ = q.length >= 3 ? q : q;
  if (searchQ.length < 3) {
    // Exact known Hebrew from map.
    if (mapped != null) return mapped;
    return null;
  }
  try {
    final res = await api.get(
      '/api/geo/cities?q=${Uri.encodeComponent(searchQ)}',
    );
    final cities = ((res['cities'] ?? []) as List)
        .map((e) => e.toString())
        .toList();
    return _bestMatch(q, cities) ?? mapped;
  } on ApiException {
    return mapped;
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

String? _mapEnglishCity(String? raw) {
  if (raw == null) return null;
  final key = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (_englishCityToHebrew.containsKey(key)) return _englishCityToHebrew[key];
  // Strip punctuation variants.
  final soft = key.replaceAll(RegExp(r"[^\w\s']"), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  return _englishCityToHebrew[soft];
}

bool _looksLatin(String s) => !RegExp(r'[א-ת]').hasMatch(s);

Future<String?> _ensureHebrewCity(
  String? city,
  double lat,
  double lon,
) async {
  if (city == null || city.isEmpty) {
    return _nominatimHebrewField(lat, lon, 'city');
  }
  if (!_looksLatin(city)) return city;
  final mapped = _mapEnglishCity(city);
  if (mapped != null) return mapped;
  final fromOsm = await _nominatimHebrewField(lat, lon, 'city');
  if (fromOsm != null && !_looksLatin(fromOsm)) return fromOsm;
  return city;
}

Future<String?> _ensureHebrewStreet(
  String? street,
  String? city,
  double lat,
  double lon,
) async {
  if (street == null || street.isEmpty) {
    return _nominatimHebrewField(lat, lon, 'road');
  }
  if (!_looksLatin(street)) return street;
  final fromOsm = await _nominatimHebrewField(lat, lon, 'road');
  if (fromOsm != null && !_looksLatin(fromOsm)) return fromOsm;
  return street;
}

/// OSM Nominatim reverse geocode with Hebrew language preference.
Future<String?> _nominatimHebrewField(
  double lat,
  double lon,
  String field,
) async {
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=jsonv2&lat=$lat&lon=$lon&accept-language=he'
      '&addressdetails=1',
    );
    final res = await http.get(
      uri,
      headers: const {
        'User-Agent': 'Buildingo/1.0 (building-management; address-onboarding)',
      },
    ).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body);
    if (json is! Map) return null;
    final addr = json['address'];
    if (addr is! Map) return null;
    if (field == 'city') {
      return _firstNonEmpty([
        addr['city']?.toString(),
        addr['town']?.toString(),
        addr['village']?.toString(),
        addr['municipality']?.toString(),
      ]);
    }
    return _firstNonEmpty([
      addr['road']?.toString(),
      addr['pedestrian']?.toString(),
      addr['residential']?.toString(),
    ]);
  } catch (_) {
    return null;
  }
}

/// Split "הרצל 12" / "Herzl 12א" into street + house when needed.
(String? street, String? house) _splitStreetAndHouse(String? street) {
  if (street == null) return (null, null);
  final trimmed = street.trim();
  final m = RegExp(r'^(.*\S)\s+(\d+[א-תA-Za-z/\-]?)$').firstMatch(trimmed);
  if (m == null) return (trimmed, null);
  return (m.group(1)!.trim(), m.group(2)!.trim());
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
