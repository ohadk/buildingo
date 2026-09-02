/// Builds a floor → apartment-count map for Vaad onboarding.
class BuildingFloorPlan {
  BuildingFloorPlan._(this.buckets, {this.firstApartmentNumber = 1});

  final List<({int floor, int apartments})> buckets;
  final int firstApartmentNumber;

  int get totalApartments =>
      buckets.fold(0, (s, b) => s + b.apartments);

  int get floorCount => buckets.length;

  /// Inclusive first / last apartment numbers in the sequential map.
  int? get firstNumber =>
      totalApartments < 1 ? null : firstApartmentNumber;

  int? get lastNumber =>
      totalApartments < 1 ? null : firstApartmentNumber + totalApartments - 1;

  bool containsApartment(int number) {
    final from = firstNumber;
    final to = lastNumber;
    if (from == null || to == null) return false;
    return number >= from && number <= to;
  }

  /// Floor that contains [number], or null if outside the plan.
  int? floorForApartment(int number) {
    for (final row in numbered) {
      if (number >= row.from && number <= row.to) return row.floor;
    }
    return null;
  }

  /// Sequential apartment numbers per floor, starting at [firstApartmentNumber].
  List<({int floor, int apartments, int from, int to})> get numbered {
    var next = firstApartmentNumber;
    return [
      for (final b in buckets)
        (
          floor: b.floor,
          apartments: b.apartments,
          from: next,
          to: (next += b.apartments) - 1,
        ),
    ];
  }

  /// Floors from [baseFloor] for [floorCount] levels (e.g. base 0, count 3 → 0,1,2).
  static List<int> floorsFromBase({
    required int baseFloor,
    required int floorCount,
  }) {
    if (floorCount < 1 || baseFloor < 0) return const [];
    return [for (var i = 0; i < floorCount; i++) baseFloor + i];
  }

  /// Typical count on every floor, with optional per-floor [overrides].
  static BuildingFloorPlan fromTypical({
    required int baseFloor,
    required int floorCount,
    required int typical,
    Map<int, int> overrides = const {},
    int firstApartmentNumber = 1,
  }) {
    final floors = floorsFromBase(baseFloor: baseFloor, floorCount: floorCount);
    if (floors.isEmpty || typical < 0) {
      return BuildingFloorPlan._(
        const [],
        firstApartmentNumber: firstApartmentNumber,
      );
    }
    final counts = <int, int>{
      for (final f in floors) f: overrides[f] ?? typical,
    };
    return custom(counts: counts, firstApartmentNumber: firstApartmentNumber);
  }

  /// Explicit per-floor counts. Floors with ≤0 apartments are omitted.
  static BuildingFloorPlan custom({
    required Map<int, int> counts,
    int firstApartmentNumber = 1,
  }) {
    final floors = counts.keys.toList()..sort();
    final buckets = [
      for (final f in floors)
        if ((counts[f] ?? 0) > 0) (floor: f, apartments: counts[f]!),
    ];
    return BuildingFloorPlan._(
      buckets,
      firstApartmentNumber: firstApartmentNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'floors': [
          for (final b in buckets)
            {'floor': b.floor, 'apartments': b.apartments},
        ],
        'firstApartmentNumber': firstApartmentNumber,
      };
}
