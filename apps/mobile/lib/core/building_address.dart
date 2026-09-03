/// Single source of truth (client twin) for composing / stripping street
/// addresses before they hit the API.
///
/// Canonical identity + duplicate detection live on the server:
///   apps/web/src/lib/building-address.ts
/// Keep [streetPrefix] and [composeAddress] aligned with that module.
class BuildingAddress {
  BuildingAddress._();

  /// Street-type prefixes — same set as TS `STREET_PREFIX`.
  static final streetPrefix = RegExp(
    r"^(רחוב|רח'|רח׳|רח|street|st\.?|שדרות|שד'|שד׳|שד|avenue|ave\.?|סמטת|סמטה|סמ'|סמ׳|סמ|alley)\s+",
    caseSensitive: false,
  );

  static String collapseSpaces(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Strip רח/רחוב/… while preserving the rest of the text.
  static String stripStreetPrefix(String value) {
    var s = collapseSpaces(value);
    for (var i = 0; i < 2; i++) {
      final next = s.replaceFirst(streetPrefix, '').trim();
      if (next == s) break;
      s = next;
    }
    return s.replaceAll(RegExp(r'''^["'\u05F3\u05F4]+|["'\u05F3\u05F4]+$'''), '');
  }

  /// Compose street + house for `buildings.address` (canonical form).
  /// "רח מייזנר" + "17" → "מייזנר 17"
  static String composeAddress(String street, String houseNumber) {
    final s = stripStreetPrefix(street);
    final n = houseNumber.trim();
    if (s.isEmpty) return n;
    if (n.isEmpty) return s;
    if (RegExp('(^|\\s)${RegExp.escape(n)}\$').hasMatch(s)) return s;
    return '$s $n';
  }
}
