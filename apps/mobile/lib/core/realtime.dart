import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project connection for Realtime. The publishable (anon) key is
/// designed to ship inside client apps; row access is still protected by
/// RLS and our API. Provide it with:
///   flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
/// or paste it as the defaultValue below.
const supabaseUrl = 'https://wcybxiwnewryvazqpxzg.supabase.co';
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: '',
);

bool get realtimeEnabled => supabasePublishableKey.isNotEmpty;

Future<void> initRealtime() async {
  if (!realtimeEnabled) return;
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
}

/// Live updates for the current building. The database broadcasts a
/// lightweight `changed` event on the `building:<id>` topic whenever a
/// building-scoped row changes (see 0007_realtime_broadcast.sql). The
/// payload only names the table — screens re-fetch actual data through
/// the authenticated API.
class BuildingRealtime {
  RealtimeChannel? _channel;
  String? _buildingId;
  final _changes = StreamController<String>.broadcast();

  /// Table names that changed, as they arrive.
  Stream<String> get changes => _changes.stream;

  /// Calls [onChange] when any of [tables] changes, debounced so bursts
  /// (e.g. a ticket insert plus its timeline events) trigger one reload.
  StreamSubscription<String> listen(
    Set<String> tables,
    void Function() onChange,
  ) {
    Timer? debounce;
    final sub = _changes.stream
        .where((t) => tables.contains(t))
        .listen((_) {
          debounce?.cancel();
          debounce = Timer(const Duration(milliseconds: 400), onChange);
        });
    sub.onDone(() => debounce?.cancel());
    return sub;
  }

  /// Points the listener at the user's building (or detaches when null).
  void setBuilding(String? buildingId) {
    if (!realtimeEnabled || buildingId == _buildingId) return;
    _channel?.unsubscribe();
    _channel = null;
    _buildingId = buildingId;
    if (buildingId == null) return;

    _channel = Supabase.instance.client
        .channel('building:$buildingId')
        .onBroadcast(
          event: 'changed',
          callback: (payload) {
            final inner = payload['payload'];
            final table =
                payload['table'] ?? (inner is Map ? inner['table'] : null);
            if (table != null) _changes.add(table.toString());
          },
        )
      ..subscribe();
  }
}

final realtime = BuildingRealtime();
