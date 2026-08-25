// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Buildingo';

  @override
  String get retry => 'Retry';

  @override
  String get signOut => 'Sign out';

  @override
  String get welcome => 'Welcome to Buildingo';

  @override
  String get signInWithPhone => 'Sign in with your phone number';

  @override
  String enterCodeSentTo(String phone) {
    return 'Enter the code we sent to $phone';
  }

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get smsCode => 'SMS code';

  @override
  String get pleaseWait => 'Please wait…';

  @override
  String get verifyAndSignIn => 'Verify & sign in';

  @override
  String get sendCode => 'Send code';

  @override
  String get useDifferentNumber => 'Use a different number';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get completeProfile => 'Complete your profile';

  @override
  String apartmentAndFloor(String apt, String floor) {
    return 'Apartment $apt, floor $floor';
  }

  @override
  String get noInviteFound =>
      'No invitation matched your phone number. Paste the invite code your Vaad sent you:';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get fullName => 'Full name';

  @override
  String get numOccupants => 'Number of occupants';

  @override
  String get uploadLease => 'Upload lease (optional)';

  @override
  String get saving => 'Saving…';

  @override
  String get enterMyBuilding => 'Enter my building';

  @override
  String get navHome => 'Home';

  @override
  String get navPayments => 'Payments';

  @override
  String get navMaintenance => 'Maintenance';

  @override
  String get navResidents => 'Residents';

  @override
  String get navDocs => 'Docs';

  @override
  String get neighbor => 'neighbor';

  @override
  String hello(String name) {
    return 'Hello, $name!';
  }

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get reportFault => 'Report Fault';

  @override
  String get payDues => 'Pay Dues';

  @override
  String get assemblies => 'Assemblies';

  @override
  String get myTickets => 'My Tickets';

  @override
  String get noOpenTickets => 'No open tickets — all quiet in the building.';

  @override
  String get communityBoard => 'Community Board';

  @override
  String get fromTheVaad => 'New message from the Vaad';

  @override
  String get nothingOnBoard => 'Nothing on the board yet.';

  @override
  String get configureVendorFirst =>
      'Configure a vendor agent first (menu → Vendor Agents).';

  @override
  String get dispatchToWhichVendor => 'Dispatch AI agent to which vendor?';

  @override
  String agentDispatchingTo(String vendor) {
    return 'Agent dispatching to $vendor…';
  }

  @override
  String get vendorContacted => 'Vendor contacted.';

  @override
  String dispatchFailed(String message) {
    return 'Dispatch failed: $message';
  }

  @override
  String get maintenance => 'Maintenance';

  @override
  String get vendorAgents => 'Vendor Agents';

  @override
  String get newReport => 'New Report';

  @override
  String get resident => 'Resident';

  @override
  String agentTo(String vendor) {
    return 'Agent → $vendor';
  }

  @override
  String get statusOpen => 'Open';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get approveAndDispatch => 'Approve & Dispatch Agent';

  @override
  String get markResolved => 'Mark Resolved';

  @override
  String get reportAFault => 'Report a Fault';

  @override
  String get whatHappened => 'What happened?';

  @override
  String get faultHint => 'e.g. Elevator stuck on floor 3';

  @override
  String get details => 'Details';

  @override
  String get detailsHint => 'When did it start? Where exactly?';

  @override
  String get submitting => 'Submitting…';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get newVendorAgent => 'New Vendor Agent';

  @override
  String get vendorName => 'Vendor name';

  @override
  String get vendorNameHint => 'Schindler Elevator Service';

  @override
  String get serviceType => 'Service type';

  @override
  String get serviceTypeHint => 'elevator';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get phoneOptional => 'Phone +972… (optional)';

  @override
  String get vendorContactSection =>
      'How should the agent open a ticket with the vendor?';

  @override
  String get vendorContactHint =>
      'The agent will contact the vendor only through the channels you pick here.';

  @override
  String get channelEmail => 'Email';

  @override
  String get channelSms => 'SMS';

  @override
  String get channelWhatsapp => 'WhatsApp';

  @override
  String get vendorEmailLabel => 'Vendor email';

  @override
  String get vendorPhoneLabel => 'Vendor phone';

  @override
  String get errSelectChannel => 'Pick at least one contact channel';

  @override
  String get errEmailRequired =>
      'The email channel needs the vendor\'s email address';

  @override
  String get errPhoneRequired => 'SMS/WhatsApp need the vendor\'s phone number';

  @override
  String get contractOptional => 'Contract details (optional)';

  @override
  String get aiInstructionsOptional => 'Extra AI instructions (optional)';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get vendorAiAgents => 'Vendor AI Agents';

  @override
  String generatedDues(String count, String month) {
    return 'Generated $count dues rows for $month.';
  }

  @override
  String get recordExpense => 'Record expense';

  @override
  String get titleLabel => 'Title';

  @override
  String get category => 'Category';

  @override
  String get categoryHint => 'electricity';

  @override
  String get amount => 'Amount';

  @override
  String get payments => 'Payments';

  @override
  String get generateMonthDues => 'Generate this month\'s dues';

  @override
  String get outstandingDues => 'Outstanding dues';

  @override
  String get youOwe => 'You owe';

  @override
  String get buildingExpenses => 'Building expenses';

  @override
  String get paymentMatrix => 'Payment matrix';

  @override
  String get myDues => 'My dues';

  @override
  String apartmentShort(String number) {
    return 'Apt $number';
  }

  @override
  String get markPaid => 'Mark paid';

  @override
  String get overdue => 'OVERDUE';

  @override
  String get pendingPayment => 'PENDING';

  @override
  String get expenseLedger => 'Building expense ledger';

  @override
  String inviteResidentTo(String apt) {
    return 'Invite resident to Apt $apt';
  }

  @override
  String get sendInvite => 'Send invite';

  @override
  String get inviteSmsSent => 'Invitation SMS sent.';

  @override
  String inviteCreatedCode(String code) {
    return 'Invite created — code: $code';
  }

  @override
  String get directoryTitle => 'Directory & Parking';

  @override
  String floorN(String n) {
    return 'Floor $n';
  }

  @override
  String get vacant => 'Vacant / not registered';

  @override
  String parkingSpot(String spot) {
    return 'Parking: $spot';
  }

  @override
  String get noParking => 'No parking assigned';

  @override
  String get inviteResident => 'Invite resident';

  @override
  String get cantOpenDocument => 'Could not open document';

  @override
  String get documents => 'Documents';

  @override
  String get noDocuments =>
      'No documents yet. Meeting summaries, receipts and protocols will appear here.';

  @override
  String get buildingWide => 'Building';

  @override
  String voteRecorded(String option) {
    return 'Vote recorded: $option';
  }

  @override
  String get newAssembly => 'New assembly';

  @override
  String get agenda => 'Agenda';

  @override
  String get voteQuestionOptional => 'Yes/No vote question (optional)';

  @override
  String get create => 'Create';

  @override
  String get voteYes => 'Yes';

  @override
  String get voteNo => 'No';

  @override
  String get voteAbstain => 'Abstain';

  @override
  String get aiWritingSummary => 'The AI is writing the summary…';

  @override
  String get summaryPublished =>
      'Summary PDF published to the building bulletin.';

  @override
  String get assembliesAndVoting => 'Assemblies & Voting';

  @override
  String get closeAndPublish => 'Close & publish summary';

  @override
  String get stageReported => 'Reported';

  @override
  String get stageApprovedByVaad => 'Approved\nby Vaad';

  @override
  String get stageAgentWorking => 'AI Agent\nDispatching';

  @override
  String get stageResolved => 'Resolved';

  @override
  String get vendorContactedShort => 'Vendor contacted';

  @override
  String get language => 'עברית';

  @override
  String get howToJoinTitle => 'How would you like to join?';

  @override
  String get welcomeNoBuilding =>
      'Your phone number isn\'t linked to a building yet.';

  @override
  String get choiceVaadTitle => 'I\'m a Vaad member';

  @override
  String get choiceVaadSubtitle =>
      'My building isn\'t on Buildingo yet — create it and invite the residents';

  @override
  String get choiceTenantTitle => 'I\'m a tenant';

  @override
  String get choiceTenantSubtitle =>
      'My building is already on Buildingo — find it and ask to join';

  @override
  String get choiceCodeTitle => 'I have a code';

  @override
  String get choiceCodeSubtitle =>
      'Got an invite or a join link from the Vaad? Enter the code here';

  @override
  String get joinCodeTitle => 'Join with a code';

  @override
  String get codeLabel => 'Code';

  @override
  String get checkCode => 'Check code';

  @override
  String joiningBuilding(String name) {
    return 'Joining $name';
  }

  @override
  String get yourApartmentNumber => 'Your apartment number';

  @override
  String get join => 'Join';

  @override
  String get createBuildingTitle => 'Create your building';

  @override
  String get country => 'Country';

  @override
  String get city => 'City';

  @override
  String get addressLabel => 'Street & number';

  @override
  String get postalCodeOptional => 'Postal code (optional)';

  @override
  String get apartmentsCount => 'Apartments';

  @override
  String get apartmentsPerFloor => 'Per floor';

  @override
  String get feeMethodLabel => 'Vaad fee';

  @override
  String get feeFixed => 'Fixed per apartment';

  @override
  String get feePerSqm => 'Per square meter';

  @override
  String get monthlyAmount => 'Monthly amount (₪)';

  @override
  String get pricePerSqmLabel => 'Price per m² (₪)';

  @override
  String get myApartmentOptional => 'My apartment number (optional)';

  @override
  String get createMyBuilding => 'Create building';

  @override
  String get buildingCreated => 'Your building is ready!';

  @override
  String get shareJoinLink =>
      'Invite the residents with a WhatsApp link — they submit their details and you approve each one:';

  @override
  String get joinPendingNote =>
      'The Vaad approves your request before you get access';

  @override
  String get shareOnWhatsapp => 'Share on WhatsApp';

  @override
  String get joinLinkCopied => 'Join link copied';

  @override
  String get continueLabel => 'Continue';

  @override
  String shareJoinMessage(String name, String link) {
    return 'Hi! Our building $name is now managed on Buildingo. Tap to join: $link';
  }

  @override
  String get findBuildingTitle => 'Find your building';

  @override
  String get searchLabel => 'Search';

  @override
  String get noBuildingFound =>
      'This building isn\'t on Buildingo yet. Ask your Vaad to download the app and create it — it takes two minutes.';

  @override
  String get askToJoin => 'Ask to join';

  @override
  String get requestSent => 'Request sent to the Vaad!';

  @override
  String get waitingApprovalTitle => 'Waiting for Vaad approval';

  @override
  String waitingApprovalBody(String name) {
    return 'We sent your request to the Vaad of $name. You\'ll get access as soon as they approve it.';
  }

  @override
  String get checkAgain => 'Check again';

  @override
  String get requestRejectedTitle => 'Request declined';

  @override
  String requestRejectedBody(String name) {
    return 'The Vaad of $name declined your request. You can search for a different building or contact them directly.';
  }

  @override
  String get searchAnotherBuilding => 'Search again';

  @override
  String get joinRequestsTitle => 'Join requests';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Decline';

  @override
  String wantsApartment(String apt) {
    return 'Apartment $apt';
  }

  @override
  String get inviteLinkShare => 'Invite residents';

  @override
  String aptFloorAddress(String apt, String floor, String address) {
    return 'Apt $apt · Floor $floor · $address';
  }

  @override
  String get openTicketsStat => 'Open tickets';

  @override
  String withAgentCount(String n) {
    return '$n with the AI agent';
  }

  @override
  String get nextPayment => 'Next payment';

  @override
  String get allPaid => 'All paid';

  @override
  String get vaadBadge => 'Vaad';

  @override
  String get unpaidThisMonth => 'Unpaid this month';

  @override
  String get collectedThisMonth => 'Collected this month';

  @override
  String ofTotal(String total) {
    return 'of $total';
  }

  @override
  String pendingJoinBanner(String n) {
    return '$n join requests await your approval';
  }

  @override
  String get newResidents => 'New residents';

  @override
  String get noDuesYet => 'Dues not generated yet';

  @override
  String get allApartmentsPaid => 'All apartments are paid up this month.';

  @override
  String get viewAll => 'View all';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String daysAgo(String n) {
    return '$n days ago';
  }

  @override
  String get announcementTag => 'Notice';

  @override
  String get vendorAgentsEmptyTitle => 'No AI agents yet';

  @override
  String get vendorAgentsEmptyBody =>
      'An AI agent contacts your vendors for you — by email, SMS or WhatsApp — and opens a service ticket the moment you approve a fault.';

  @override
  String get vendorAgentsStep1 => 'Add a vendor with their contact details';

  @override
  String get vendorAgentsStep2 => 'Approve a resident\'s fault report';

  @override
  String get vendorAgentsStep3 =>
      'The agent opens the ticket with the vendor and keeps you posted';

  @override
  String get addFirstVendor => 'Add your first vendor';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get editVendorAgent => 'Edit vendor agent';

  @override
  String get deleteVendorTitle => 'Delete vendor agent?';

  @override
  String deleteVendorConfirm(String name) {
    return 'The agent for $name will be removed and will no longer contact this vendor. Existing tickets are kept.';
  }

  @override
  String get vendorDeleted => 'Vendor agent deleted';
}
