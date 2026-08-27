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
          : null;

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
  final bool requireJoinDocs;

  Building.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      name = j['name'],
      address = j['address'],
      city = j['city'],
      joinCode = j['join_code'],
      feeMethod = j['fee_method'] ?? 'fixed',
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
  final String? parkingSpot;
  final String? docUrl;
  final String? arnonaDocUrl;

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
      parkingSpot = j['parking_spot'],
      docUrl = j['doc_url'],
      arnonaDocUrl = j['arnona_doc_url'];
}

class Apartment {
  final String id;
  final int apartmentNumber;
  final int floor;
  final String? parkingSpot;

  Apartment.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      apartmentNumber = j['apartment_number'],
      floor = j['floor'],
      parkingSpot = j['parking_spot'];
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
  final String status;
  final String agentStatus;
  final String? vendorName;
  final String? reporterName;
  final DateTime createdAt;
  final List<TicketEvent> events;

  Ticket.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      title = j['title'],
      description = j['description'],
      location = j['location'],
      imageUrl = j['image_url'],
      status = j['status'],
      agentStatus = j['agent_status'] ?? 'idle',
      vendorName = j['vendor_agents']?['vendor_name'],
      reporterName = j['reporter']?['full_name'],
      createdAt = DateTime.parse(j['created_at']),
      events = ((j['ticket_events'] ?? []) as List)
          .map((e) => TicketEvent.fromJson(e))
          .toList();
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
    this.receiptUrl,
  });

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
      receiptUrl = j['receipt_url'];
}

class Expense {
  final String title;
  final String category;
  final double amount;
  final String expenseDate;
  final String? description;
  final String? provider;
  final String? receiptUrl;

  Expense.fromJson(Map<String, dynamic> j)
    : title = j['title'],
      category = j['category'],
      amount = double.parse(j['amount'].toString()),
      expenseDate = j['expense_date'],
      description = j['description'],
      provider = j['provider'],
      receiptUrl = j['receipt_url'];
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
  final String? parkingSpot;
  final List<({String name, String phone, String role})> residents;

  DirectoryEntry.fromJson(Map<String, dynamic> j)
    : apartmentId = j['id'],
      apartmentNumber = j['apartment_number'],
      floor = j['floor'],
      parkingSpot = j['parking_spot'],
      residents = ((j['users'] ?? []) as List)
          .map(
            (u) => (
              name: (u['full_name'] ?? '') as String,
              phone: (u['phone_number'] ?? '') as String,
              role: (u['role'] ?? 'tenant') as String,
            ),
          )
          .toList();
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
  final int? apartmentNumber;
  final DateTime createdAt;

  DocumentItem.fromJson(Map<String, dynamic> j)
    : title = j['title'],
      filePath = j['file_path'],
      fileType = j['file_type'],
      apartmentNumber = j['apartments']?['apartment_number'],
      createdAt = DateTime.parse(j['created_at']);
}

class Announcement {
  final String title;
  final String body;
  final String? attachmentPath;
  final DateTime createdAt;

  Announcement.fromJson(Map<String, dynamic> j)
    : title = j['title'],
      body = j['body'],
      attachmentPath = j['attachment_path'],
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
