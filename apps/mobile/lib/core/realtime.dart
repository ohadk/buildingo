import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_client.dart';

/// Supabase project URL (Realtime).
const supabaseUrl = 'https://wcybxiwnewryvazqpxzg.supabase.co';

/// Optional compile-time override. Prefer fetching from `/api/config` so
/// dual-sim / CI don't need a dart-define.
const supabasePublishableKeyDefine = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: '',
);

String _publishableKey = supabasePublishableKeyDefine;

bool get realtimeEnabled => _publishableKey.isNotEmpty;

/// Loads the publishable key from the API (or keeps the dart-define), then
/// initializes Supabase Realtime. Safe to call multiple times.
Future<void> initRealtime() async {
  if (_publishableKey.isEmpty) {
    try {
      final cfg = await api
          .get('/api/config')
          .timeout(const Duration(seconds: 8));
      final key = cfg['supabasePublishableKey']?.toString() ?? '';
      if (key.isNotEmpty) _publishableKey = key;
    } catch (_) {
      // API down or key not configured — polling fallback still works.
    }
  }
  if (!realtimeEnabled) return;
  if (Supabase.instance.isInitialized) return;
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: _publishableKey,
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
          debounce = Timer(const Duration(milliseconds: 200), onChange);
        });
    sub.onDone(() => debounce?.cancel());
    return sub;
  }

  /// Points the listener at the user's building (or detaches when null).
  Future<void> setBuilding(String? buildingId) async {
    if (buildingId == _buildingId && _channel != null) return;
    await _channel?.unsubscribe();
    _channel = null;
    _buildingId = buildingId;
    if (buildingId == null) return;

    if (!realtimeEnabled) {
      await initRealtime();
    }
    if (!realtimeEnabled) return;

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
