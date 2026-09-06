import 'dart:convert';

class AppUser {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String? email;
  final String role; // super_admin | vaad | tenant
  final String? buildingId;
  final String? apartmentId;
  final int numOccupants;
  final DateTime? onboardedAt;

  /// Short-lived signed URL for the profile picture (null when unset).
  final String? avatarUrl;

  AppUser.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      phoneNumber = j['phone_number'],
      fullName = j['full_name'] ?? '',
      email = j['email'],
      role = j['role'],
      buildingId = j['building_id'],
      apartmentId = j['apartment_id'],
      numOccupants = j['num_occupants'] ?? 1,
      onboardedAt = j['onboarded_at'] != null
          ? DateTime.parse(j['onboarded_at'])
          : null,
      avatarUrl = j['avatar_url'];

  bool get isVaad => role == 'vaad';
  bool get needsOnboarding => onboardedAt == null && role != 'super_admin';
}

class Building {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? joinCode;
  final String feeMethod; // fixed | per_sqm
  final double? fixedMonthlyFee;
  final double? pricePerSqm;
  final bool requireJoinDocs;

  Building.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      name = j['name'],
      address = j['address'],
      city = j['city'],
      joinCode = j['join_code'],
      feeMethod = j['fee_method'] ?? 'fixed',
      fixedMonthlyFee = (j['fixed_monthly_fee'] as num?)?.toDouble(),
      pricePerSqm = (j['price_per_sqm'] as num?)?.toDouble(),
      requireJoinDocs = j['require_join_docs'] ?? false;
}

/// A tenant's request to join an existing building, decided by the Vaad.
class JoinRequest {
  final String id;
  final String status; // pending | approved | rejected
  final int? apartmentNumber;
  final String? buildingName;
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final int? numOccupants;
  final int? floor;
  final List<String> parkingSpots;
  final String? docUrl;
  final String? arnonaDocUrl;
  final double? sizeSqm;

  /// Display label (joined spots), or null when none.
  String? get parkingSpot =>
      parkingSpots.isEmpty ? null : parkingSpots.join(' · ');

  JoinRequest.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      status = j['status'],
      apartmentNumber = j['apartment_number'],
      buildingName = j['buildings']?['name'],
      fullName = j['full_name'] ?? j['users']?['full_name'],
      phoneNumber = j['users']?['phone_number'],
      email = j['email'],
      numOccupants = j['num_occupants'],
      floor = j['floor'],
      parkingSpots = _parkingSpotsFromJson(j),
      docUrl = j['doc_url'],
      arnonaDocUrl = j['arnona_doc_url'],
      sizeSqm = (j['size_sqm'] as num?)?.toDouble();
}

class Apartment {
  final String id;
  final int apartmentNumber;
  final int floor;
  final List<String> parkingSpots;

  String? get parkingSpot =>
      parkingSpots.isEmpty ? null : parkingSpots.join(' · ');

  Apartment.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      apartmentNumber = j['apartment_number'],
      floor = j['floor'],
      parkingSpots = _parkingSpotsFromJson(j);
}

class TicketEvent {
  final String label;
  final String? detail;
  final DateTime createdAt;

  TicketEvent.fromJson(Map<String, dynamic> j)
    : label = j['label'],
      detail = j['detail'],
      createdAt = DateTime.parse(j['created_at']);
}

class Ticket {
  final String id;
  final String title;
  final String description;
  final String? location;
  final String? imageUrl;
  final List<String> imageUrls;
  /// Storage paths used when editing/uploading photos.
  final List<String> imagePaths;
  final String status;
  final String agentStatus;
  final String category;
  final double? costAmount;
  final String? receiptUrl;
  final String? progressNote;
  final DateTime? fixDate;
  final String? vendorName;
  final String? reporterName;
  final String? reportedBy;
  final DateTime createdAt;
  final List<TicketEvent> events;

  /// Collapses legacy statuses into the 3-stage UI model.
  String get displayStatus {
    switch (status) {
      case 'resolved':
        return 'resolved';
      case 'in_progress':
      case 'approved':
        return 'in_progress';
      default:
        return 'open';
    }
  }

  Ticket.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      title = j['title'],
      description = (j['description'] as String?) ?? '',
      location = j['location'],
      imageUrl = j['image_url'],
      imageUrls = _ticketImageUrls(j),
      imagePaths = _ticketImagePaths(j['image_path']),
      status = j['status'],
      agentStatus = j['agent_status'] ?? 'idle',
      category = (j['category'] as String?) ?? 'other',
      costAmount = _asDouble(j['cost_amount']),
      receiptUrl = j['receipt_url'] as String?,
      progressNote = j['progress_note'] as String?,
      fixDate = j['fix_date'] != null
          ? DateTime.tryParse(j['fix_date'].toString())
          : null,
      vendorName = j['vendor_agents']?['vendor_name'],
      reporterName = j['reporter']?['full_name'],
      reportedBy = j['reported_by'] as String?,
      createdAt = DateTime.parse(j['created_at']),
      events = ((j['ticket_events'] ?? []) as List)
          .map((e) => TicketEvent.fromJson(e))
          .toList();

  Ticket copyWith({
    String? status,
    String? title,
    String? description,
    String? location,
    String? category,
    String? progressNote,
    DateTime? fixDate,
    double? costAmount,
    String? receiptUrl,
  }) =>
      Ticket._(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        imageUrl: imageUrl,
        imageUrls: imageUrls,
        imagePaths: imagePaths,
        status: status ?? this.status,
        agentStatus: agentStatus,
        category: category ?? this.category,
        costAmount: costAmount ?? this.costAmount,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        progressNote: progressNote ?? this.progressNote,
        fixDate: fixDate ?? this.fixDate,
        vendorName: vendorName,
        reporterName: reporterName,
        reportedBy: reportedBy,
        createdAt: createdAt,
        events: events,
      );

  const Ticket._({
    required this.id,
    required this.title,
    required this.description,
    this.location,
    this.imageUrl,
    required this.imageUrls,
    required this.imagePaths,
    required this.status,
    required this.agentStatus,
    required this.category,
    this.costAmount,
    this.receiptUrl,
    this.progressNote,
    this.fixDate,
    this.vendorName,
    this.reporterName,
    this.reportedBy,
    required this.createdAt,
    required this.events,
  });
}

List<String> _ticketImageUrls(Map<String, dynamic> j) {
  final raw = j['image_urls'];
  if (raw is List) {
    return raw.whereType<String>().where((u) => u.isNotEmpty).toList();
  }
  final single = j['image_url'] as String?;
  return single == null || single.isEmpty ? const [] : [single];
}

List<String> _ticketImagePaths(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) {
    return raw.whereType<String>().where((p) => p.isNotEmpty).toList();
  }
  final s = raw.toString();
  if (s.isEmpty) return const [];
  if (s.startsWith('[')) {
    try {
      final parsed = jsonDecode(s);
      if (parsed is List) {
        return parsed.whereType<String>().where((p) => p.isNotEmpty).toList();
      }
    } catch (_) {
      /* fall through */
    }
  }
  return [s];
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

/// One row of the building activity trail (audit log).
class AuditLog {
  final String id;
  final String action;
  final Map<String, dynamic> details;
  final String? actorName;
  final DateTime createdAt;

  AuditLog.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      action = j['action'],
      details = Map<String, dynamic>.from(j['details'] ?? {}),
      actorName = j['actor']?['full_name'] ?? j['actor']?['phone_number'],
      createdAt = DateTime.parse(j['created_at']);
}

class Payment {
  final String id;
  final String? apartmentId;
  final int month;
  final int year;
  final double amount;
  final String status;
  final int? apartmentNumber;
  final DateTime? paymentDate;
  final String? receiptPath;
  final String? receiptUrl;

  /// Local synthetic row for optimistic matrix updates.
  Payment({
    required this.id,
    required this.apartmentId,
    required this.month,
    required this.year,
    required this.amount,
    required this.status,
    this.apartmentNumber,
    this.paymentDate,
    this.receiptPath,
    this.receiptUrl,
  });

  bool get hasReceipt =>
      (receiptPath != null && receiptPath!.isNotEmpty) ||
      (receiptUrl != null && receiptUrl!.isNotEmpty);

  Payment.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      apartmentId = j['apartment_id'],
      month = j['month'],
      year = j['year'],
      amount = double.parse(j['amount'].toString()),
      status = j['status'],
      apartmentNumber = j['apartments']?['apartment_number'],
      paymentDate = j['payment_date'] != null
          ? DateTime.tryParse(j['payment_date'])
          : null,
      receiptPath = j['receipt_path'] as String?,
      receiptUrl = j['receipt_url'] as String?;
}

class Expense {
  final String title;
  final String category;
  final double amount;
  final String expenseDate;
  final String? description;
  final String? provider;
  final String? receiptPath;
  final String? receiptUrl;

  Expense.fromJson(Map<String, dynamic> j)
    : title = j['title'],
      category = j['category'],
      amount = double.parse(j['amount'].toString()),
      expenseDate = j['expense_date'],
      description = j['description'],
      provider = j['provider'],
      receiptPath = j['receipt_path'] as String?,
      receiptUrl = j['receipt_url'] as String?;

  bool get hasReceipt =>
      (receiptPath != null && receiptPath!.isNotEmpty) ||
      (receiptUrl != null && receiptUrl!.isNotEmpty);
}

class VendorAgent {
  final String id;
  final String vendorName;
  final String serviceType;
  final String? vendorEmail;
  final String? vendorPhone;
  final List<String> preferredChannels;
  final String? contractDetails;
  final String? aiInstructions;

  VendorAgent.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      vendorName = j['vendor_name'],
      serviceType = j['service_type'],
      vendorEmail = j['vendor_email'],
      vendorPhone = j['vendor_phone'],
      preferredChannels = ((j['preferred_channels'] ?? []) as List)
          .cast<String>(),
      contractDetails = j['contract_details'],
      aiInstructions = j['ai_instructions'];
}

class DirectoryEntry {
  final String apartmentId;
  final int apartmentNumber;
  final int floor;
  final List<String> parkingSpots;
  final double monthlyFee;
  final double? sizeSqm;
  /// Household size for the apartment (null when vacant / unknown).
  final int? numOccupants;
  /// Date the current tenants entered this apartment (active tenancy).
  final DateTime? residentSince;
  final List<({String name, String phone, String role, int? numOccupants})>
      residents;

  String? get parkingSpot =>
      parkingSpots.isEmpty ? null : parkingSpots.join(' · ');

  DirectoryEntry.fromJson(Map<String, dynamic> j)
    : apartmentId = j['id'],
      apartmentNumber = j['apartment_number'],
      floor = j['floor'],
      parkingSpots = _parkingSpotsFromJson(j),
      monthlyFee = (j['monthly_fee'] as num?)?.toDouble() ?? 0,
      sizeSqm = (j['size_sqm'] as num?)?.toDouble(),
      numOccupants = (j['num_occupants'] as num?)?.toInt(),
      residentSince = j['resident_since'] != null
          ? DateTime.tryParse(j['resident_since'].toString())
          : null,
      residents = ((j['users'] ?? []) as List)
          .map(
            (u) => (
              name: (u['full_name'] ?? '') as String,
              phone: (u['phone_number'] ?? '') as String,
              role: (u['role'] ?? 'tenant') as String,
              numOccupants: (u['num_occupants'] as num?)?.toInt(),
            ),
          )
          .toList();
}

String? _nullableTrimmed(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  return s.isEmpty ? null : s;
}

/// Prefer `parking_spots` array; fall back to legacy single `parking_spot`.
List<String> _parkingSpotsFromJson(Map<String, dynamic> j) {
  final raw = j['parking_spots'] ?? j['parkingSpots'];
  if (raw is List) {
    return [
      for (final e in raw)
        if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
    ];
  }
  final single = _nullableTrimmed(j['parking_spot'] ?? j['parkingSpot']);
  return single == null ? const [] : [single];
}

/// One holding period of an apartment (owner or renter), part of the
/// unit's occupancy history. status: active | pending | ended.
class Tenancy {
  final String id;
  final String? fullName;
  final String? phoneNumber;
  final String holderType; // owner | renter
  final int? numOccupants;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? endDebtPolicy;
  final String status;

  Tenancy.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      fullName = j['full_name'],
      phoneNumber = j['phone_number'],
      holderType = j['holder_type'] ?? 'renter',
      numOccupants = j['num_occupants'],
      startedAt = DateTime.parse(j['started_at']),
      endedAt = j['ended_at'] != null ? DateTime.parse(j['ended_at']) : null,
      endDebtPolicy = j['end_debt_policy'],
      status = j['status'] ?? 'active';
}

class DocumentItem {
  final String title;
  final String filePath;
  final String? fileType;
  final String bucket;
  final String source; // document | payment_receipt
  final int? apartmentNumber;
  final int? month;
  final int? year;
  final DateTime createdAt;

  bool get isPaymentReceipt => source == 'payment_receipt';
  bool get isPdf =>
      (fileType ?? '').contains('pdf') ||
      filePath.toLowerCase().endsWith('.pdf');
  bool get isImage {
    final t = (fileType ?? '').toLowerCase();
    if (t.startsWith('image/')) return true;
    final p = filePath.toLowerCase();
    return p.endsWith('.png') ||
        p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.webp') ||
        p.endsWith('.gif') ||
        p.endsWith('.heic') ||
        p.endsWith('.heif');
  }

  DocumentItem.fromJson(Map<String, dynamic> j)
    : title = (j['title'] as String?) ?? '',
      filePath = j['file_path'],
      fileType = j['file_type'],
      bucket = (j['bucket'] as String?) ?? 'documents',
      source = (j['source'] as String?) ?? 'document',
      apartmentNumber = j['apartments']?['apartment_number'] as int?,
      month = (j['month'] as num?)?.toInt(),
      year = (j['year'] as num?)?.toInt(),
      createdAt = DateTime.parse(j['created_at']);
}

class Announcement {
  final String id;
  final String title;
  final String body;
  final String? attachmentPath;
  final String? category;
  final DateTime? eventDate;
  final DateTime createdAt;

  Announcement.fromJson(Map<String, dynamic> j)
    : id = j['id']?.toString() ?? '${j['created_at']}-${j['title']}',
      title = j['title'],
      body = j['body'],
      attachmentPath = j['attachment_path'],
      category = j['category']?.toString(),
      eventDate = j['event_date'] != null
          ? DateTime.parse(j['event_date'] as String)
          : null,
      createdAt = DateTime.parse(j['created_at']);
}

class Vote {
  final String id;
  final String title;
  final List<String> options;
  final bool allowMultiple;
  final bool isActive;
  final Map<String, int> tally;
  final Set<String> votedApartments;

  Vote.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      title = j['title'],
      options = (j['options'] as List).map((o) => o.toString()).toList(),
      allowMultiple = j['allow_multiple'] ?? false,
      isActive = j['is_active'] ?? true,
      tally = _tally(j['vote_ballots']),
      votedApartments = ((j['vote_ballots'] ?? []) as List)
          .map((b) => b['apartment_id'].toString())
          .toSet();

  static Map<String, int> _tally(dynamic ballots) {
    final result = <String, int>{};
    for (final b in (ballots ?? []) as List) {
      final opt = b['selected_option'].toString();
      result[opt] = (result[opt] ?? 0) + 1;
    }
    return result;
  }
}

class Meeting {
  final String id;
  final String title;
  final String agenda;
  final DateTime meetingDate;
  final String? location;
  final String? summaryDocPath;
  final bool isClosed;
  final List<Vote> votes;

  Meeting.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      title = j['title'],
      agenda = j['agenda'],
      meetingDate = DateTime.parse(j['meeting_date']),
      location = j['location'],
      summaryDocPath = j['summary_doc_path'],
      isClosed = j['is_closed'] ?? false,
      votes = ((j['votes'] ?? []) as List)
          .map((v) => Vote.fromJson(v))
          .toList();
}

/// One concrete date for a building schedule rule (garbage, cleaning…).
class ScheduleOccurrence {
  final String id;
  final String eventType;
  final String title;
  final String? notes;
  final String recurrence;
  final DateTime occurrenceDate;
  final String? timeOfDay;
  final int? dayOfMonth;
  final DateTime? startsAt;

  ScheduleOccurrence.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      eventType = j['event_type'],
      title = j['title'],
      notes = j['notes'],
      recurrence = j['recurrence'],
      occurrenceDate = DateTime.parse(j['occurrence_date']),
      timeOfDay = j['time_of_day']?.toString().substring(0, 5),
      dayOfMonth = j['day_of_month'],
      startsAt = j['starts_at'] != null
          ? DateTime.parse(j['starts_at'] as String)
          : null;

  bool get isMeeting => eventType == 'meeting';
}
