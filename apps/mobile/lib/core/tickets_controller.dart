import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';

class TicketPhotoDraft {
  final Uint8List bytes;
  final String name;
  const TicketPhotoDraft({required this.bytes, required this.name});
}

/// Draft captured from the report form; submitted in the background so
/// the UI can show an optimistic row immediately.
class TicketDraft {
  final String title;
  final String description;
  final String category;
  final String? location;
  final List<TicketPhotoDraft> photos;
  final String? reporterName;

  const TicketDraft({
    required this.title,
    required this.description,
    required this.category,
    this.location,
    this.photos = const [],
    this.reporterName,
  });
}

enum PendingTicketPhase { uploadingPhoto, creating, done, failed }

class PendingTicket {
  final String localId;
  final TicketDraft draft;
  PendingTicketPhase phase;
  String? error;
  String? createdId;

  PendingTicket({
    required this.localId,
    required this.draft,
    this.phase = PendingTicketPhase.creating,
  });

  bool get isActive =>
      phase == PendingTicketPhase.uploadingPhoto ||
      phase == PendingTicketPhase.creating;
}

/// Owns in-flight ticket creates so Home / Maintenance can show them
/// instantly while upload + POST finish in the background.
class TicketsController extends ChangeNotifier {
  final List<PendingTicket> _pending = [];
  List<PendingTicket> get pending => List.unmodifiable(_pending);

  Future<void> submit(TicketDraft draft) async {
    final item = PendingTicket(
      localId: 'local-${DateTime.now().microsecondsSinceEpoch}',
      draft: draft,
      phase: draft.photos.isNotEmpty
          ? PendingTicketPhase.uploadingPhoto
          : PendingTicketPhase.creating,
    );
    _pending.insert(0, item);
    notifyListeners();

    try {
      final imagePaths = <String>[];
      if (draft.photos.isNotEmpty) {
        item.phase = PendingTicketPhase.uploadingPhoto;
        notifyListeners();
        for (final photo in draft.photos) {
          final res = await api.uploadFile(
            '/api/tickets/upload',
            bytes: photo.bytes,
            filename: photo.name,
          );
          final path = res['imagePath'] as String?;
          if (path != null) imagePaths.add(path);
        }
      }

      item.phase = PendingTicketPhase.creating;
      notifyListeners();

      final res = await api.post('/api/tickets', {
        'title': draft.title,
        'description': draft.description,
        'category': draft.category,
        if (draft.location != null) 'location': draft.location,
        if (imagePaths.isNotEmpty) 'imagePaths': imagePaths,
      });
      item.createdId = res['ticket']?['id']?.toString();
      item.phase = PendingTicketPhase.done;
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 350));
      _pending.removeWhere((p) => p.localId == item.localId);
      notifyListeners();
    } catch (e) {
      item.phase = PendingTicketPhase.failed;
      item.error = e is ApiException ? e.message : e.toString();
      notifyListeners();
      if (kDebugMode) {
        debugPrint('Ticket submit failed: $e');
      }
    }
  }

  void dismiss(String localId) {
    _pending.removeWhere((p) => p.localId == localId);
    notifyListeners();
  }
}
