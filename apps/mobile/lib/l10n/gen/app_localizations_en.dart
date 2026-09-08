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
  String enterWhatsAppCodeSentTo(String phone) {
    return 'Enter the WhatsApp code we sent to $phone';
  }

  @override
  String get sendCodeViaWhatsApp => 'Send code via WhatsApp';

  @override
  String get sendViaSmsInstead => 'Send via SMS instead';

  @override
  String get sendViaWhatsAppInstead => 'Send via WhatsApp instead';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get smsCode => 'SMS code';

  @override
  String get pleaseWait => 'Please wait…';

  @override
  String get splashTagline => 'Your building, together';

  @override
  String get splashLoading => 'Getting things ready…';

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
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get authErrorSmsSendFailed =>
      'Couldn\'t send the verification code. Please try again in a moment.';

  @override
  String get authErrorWhatsAppSendFailed =>
      'Couldn\'t send the WhatsApp code. Please try again, or use SMS instead.';

  @override
  String get authErrorSmsUnavailable =>
      'SMS to this number isn\'t available right now (carrier or rate limit). Wait a few minutes, try another Israeli number, or try again later.';

  @override
  String get authErrorInvalidPhone =>
      'That phone number doesn\'t look right. Check the country code and try again.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get authErrorNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get authErrorInvalidCode =>
      'That code isn\'t valid. Please check it and try again.';

  @override
  String get authErrorSessionExpired => 'This code expired. Request a new one.';

  @override
  String get authErrorNotEnabled =>
      'Phone sign-in is temporarily unavailable. Please try again later.';

  @override
  String get completeProfile => 'Complete your profile';

  @override
  String get myProfile => 'My profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get settingsNotificationsNote =>
      'Banner push notifications are not enabled yet. While the app is open, updates appear live. These switches save your preferences for when push alerts are turned on.';

  @override
  String get settingsNotifyTickets => 'Tickets & maintenance';

  @override
  String get settingsNotifyTicketsHint => 'New tickets and status updates';

  @override
  String get settingsNotifyAnnouncements => 'Board announcements';

  @override
  String get settingsNotifyAnnouncementsHint => 'Messages from the committee';

  @override
  String get settingsNotifyPayments => 'Payments & fees';

  @override
  String get settingsNotifyPaymentsHint => 'Dues reminders and payment updates';

  @override
  String get settingsNotifyMessages => 'Building messages';

  @override
  String get settingsNotifyMessagesHint => 'General building chat and alerts';

  @override
  String get settingsPrivacySection => 'Privacy';

  @override
  String get settingsPrivacyBody =>
      'Buildingo is built for your building community. We collect only what is needed to run the building — not ads, not selling personal data.';

  @override
  String get settingsPrivacyBullets =>
      '• Phone number — to sign in and reach you as a resident\n• Name and optional email — shown to your building directory\n• Apartment details and documents you upload (e.g. Arnona) — for fees and Vaad review\n• Location — only if you choose “use current location” when setting an address\n• Sensitive fields are encrypted at rest on our servers';

  @override
  String get settingsPrivacyPolicyLink => 'Open privacy policy';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get deleteAccountConfirmBody =>
      'This cannot be undone. Your account will be permanently deleted and you will not be able to restore it. Your profile data will be removed from the app.';

  @override
  String get deleteAccountConfirmAction => 'Delete my account';

  @override
  String get deleteAccountFailed =>
      'Could not delete the account. Please try again.';

  @override
  String get deletingAccount => 'Deleting…';

  @override
  String get menu => 'Menu';

  @override
  String get leftToCollect => 'Left to collect';

  @override
  String get profileUpdated => 'Profile saved';

  @override
  String get changePhoto => 'Change photo';

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
  String get navResidents => 'Residents';

  @override
  String get navDocs => 'Docs';

  @override
  String get navAgents => 'Agents';

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
  String get myTickets => 'Service calls';

  @override
  String get noOpenTickets => 'No open tickets — all quiet in the building.';

  @override
  String get homeTicketsClearTitle => 'All quiet';

  @override
  String get homeTicketsClearBody =>
      'No open service calls right now. Anything new will show up here.';

  @override
  String get noTicketsYet => 'No tickets yet';

  @override
  String get noTicketsHint => 'Tap + below to report a fault in the building.';

  @override
  String get communityBoard => 'Building board';

  @override
  String get seeDetails => 'Details';

  @override
  String get viewAllCalls => 'All service calls';

  @override
  String get viewAllBoardMessages => 'All messages';

  @override
  String get allBoardMessages => 'All board messages';

  @override
  String boardPublishedOn(String date) {
    return 'Published $date';
  }

  @override
  String get noCurrentBoardMessages => 'No messages for this week';

  @override
  String get paymentsSubtitle => 'All payments, clear and organized.';

  @override
  String get buildingBalance => 'Building balance';

  @override
  String balanceAsOf(String date) {
    return 'As of $date';
  }

  @override
  String get buildingIncome => 'Total income';

  @override
  String get buildingExpensesTotal => 'Total expenses';

  @override
  String get monthlyCommitteeFees => 'Monthly committee fees';

  @override
  String get paymentsAutoUpdated => 'Payments update automatically';

  @override
  String get residentsDirectory => 'Residents directory';

  @override
  String apartmentsCountN(String n) {
    return '$n apartments';
  }

  @override
  String get vaadTools => 'Committee tools';

  @override
  String get toolGuests => 'Guests';

  @override
  String get toolSurveys => 'Surveys';

  @override
  String get toolMessage => 'Message';

  @override
  String get ticketCatLeak => 'Leak';

  @override
  String get ticketCatElevator => 'Elevator';

  @override
  String get ticketCatCleaning => 'Cleaning';

  @override
  String get ticketCatLights => 'Lights';

  @override
  String get ticketCatElectric => 'Electrical';

  @override
  String get ticketCatDoor => 'Door / intercom';

  @override
  String get ticketCatOther => 'Other';

  @override
  String get ticketCategoryLabel => 'What kind of fault?';

  @override
  String ticketCreatedOn(String date) {
    return 'Created on $date';
  }

  @override
  String get ticketUploadingPhoto => 'Uploading photo…';

  @override
  String get ticketCreating => 'Sending report…';

  @override
  String get ticketCreateDone => 'Report sent';

  @override
  String get ticketCreateFailed => 'Couldn’t send report';

  @override
  String get ticketRetry => 'Retry';

  @override
  String get ticketDismiss => 'Dismiss';

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
  String get maintenance => 'Faults & Repairs';

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
  String get statusOpen => 'New';

  @override
  String get statusApproved => 'In progress';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusResolved => 'Done';

  @override
  String get approveAndDispatch => 'Approve & Dispatch Agent';

  @override
  String get markResolved => 'Mark Done';

  @override
  String get ticketTapStatusHint => 'Tap a stage to update status';

  @override
  String get ticketRepairCost => 'Repair cost';

  @override
  String get ticketRepairCostHint => 'How much did this fix cost?';

  @override
  String get ticketAddRepairCost => 'Add repair cost';

  @override
  String get ticketEditRepairCost => 'Update cost & receipt';

  @override
  String get ticketCostSaved => 'Repair cost saved';

  @override
  String ticketCostAmount(String amount) {
    return '₪$amount';
  }

  @override
  String get ticketEdit => 'Edit ticket';

  @override
  String get ticketEdited => 'Ticket updated';

  @override
  String get deleteTicket => 'Delete ticket';

  @override
  String get deleteTicketConfirm =>
      'Remove this ticket permanently? This cannot be undone.';

  @override
  String get ticketDeleted => 'Ticket deleted';

  @override
  String get auditTicketDeleted => 'Ticket deleted';

  @override
  String get editScheduleEvent => 'Edit schedule event';

  @override
  String get editMeeting => 'Edit assembly';

  @override
  String get deleteScheduleEvent => 'Delete from schedule';

  @override
  String get deleteScheduleEventConfirm =>
      'Remove this item from the building schedule?';

  @override
  String get scheduleEventUpdated => 'Schedule updated';

  @override
  String get scheduleEventDeleted => 'Removed from schedule';

  @override
  String get auditMeetingUpdated => 'Assembly updated';

  @override
  String get auditMeetingDeleted => 'Assembly deleted';

  @override
  String get ticketUpdateProgress => 'Update progress';

  @override
  String get ticketProgressSaved => 'Progress updated';

  @override
  String get ticketProgressNote => 'What\'s happening?';

  @override
  String get ticketProgressNoteHint =>
      'e.g. Opened with provider, parts ordered…';

  @override
  String get ticketFixDateLabel => 'Expected fix date';

  @override
  String ticketFixDate(String date) {
    return 'Fix date: $date';
  }

  @override
  String ticketExpectedBy(String date) {
    return 'Expected $date';
  }

  @override
  String get ticketProgressOpenedProvider => 'Opened with provider';

  @override
  String get ticketProgressPartsOrdered => 'Parts ordered';

  @override
  String get ticketProgressScheduled => 'Fix scheduled';

  @override
  String get reportAFault => 'Report a Fault';

  @override
  String get whatHappened => 'What happened?';

  @override
  String get faultHint => 'e.g. Elevator stuck on floor 3';

  @override
  String get details => 'Details (optional)';

  @override
  String get detailsHint => 'When did it start? Where exactly?';

  @override
  String get addMorePhotos => 'Add photos';

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
  String get directoryTitle => 'Residents directory';

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
  String directoryResidentSince(String date) {
    return 'Since $date';
  }

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
  String get activityLog => 'Activity log';

  @override
  String get activityEmptyTitle => 'No activity yet';

  @override
  String get activityEmptyBody =>
      'Every action in the building — tenants joining, tickets, assemblies, votes and payments — will be recorded here.';

  @override
  String get auditTenantJoined => 'Tenant joined';

  @override
  String get auditJoinRequested => 'Join request';

  @override
  String get auditJoinRejected => 'Request rejected';

  @override
  String get auditTicketCreated => 'Ticket opened';

  @override
  String get auditTicketDispatched => 'Ticket sent to vendor';

  @override
  String get auditTicketStatus => 'Ticket status updated';

  @override
  String get auditMeetingCreated => 'Assembly scheduled';

  @override
  String get auditMeetingClosed => 'Assembly closed';

  @override
  String get auditVoteCast => 'Vote cast';

  @override
  String get auditPaymentMarked => 'Payment marked';

  @override
  String get auditPaymentsBulk => 'Bulk payments marked';

  @override
  String get auditExpenseAdded => 'Expense recorded';

  @override
  String get auditAnnouncement => 'Announcement published';

  @override
  String get auditVendorAdded => 'Vendor agent added';

  @override
  String get auditVendorUpdated => 'Vendor agent updated';

  @override
  String get auditVendorDeleted => 'Vendor agent deleted';

  @override
  String get auditBuildingCreated => 'Building created';

  @override
  String get auditVaadInvited => 'Invitation sent';

  @override
  String get meetingsEmptyTitle => 'No assemblies yet';

  @override
  String get meetingsEmptyBody =>
      'Plan resident assemblies, vote on decisions and publish summaries for the whole building.';

  @override
  String get residentsAssembly => 'Residents assembly';

  @override
  String get meetingLocationLabel => 'Location';

  @override
  String get agendaItems => 'Agenda items';

  @override
  String get agendaItemsHint =>
      'Add agenda items — each one can be a discussion or a vote.';

  @override
  String get newAgendaItem => 'New item';

  @override
  String get withVote => 'With a vote';

  @override
  String get addItem => 'Add';

  @override
  String get voteChip => 'Vote';

  @override
  String get discussionChip => 'Discussion';

  @override
  String get createMeetingCta => 'Create assembly';

  @override
  String get whatToCreate => 'What would you like to create?';

  @override
  String get ticketLocationLabel => 'Fault location';

  @override
  String get locLobby => 'Lobby';

  @override
  String get locStairwell => 'Stairwell';

  @override
  String get locElevator => 'Elevator';

  @override
  String get locParking => 'Parking';

  @override
  String get locRoof => 'Roof';

  @override
  String get locYard => 'Yard';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get messageToBuilding => 'Message to the building';

  @override
  String get announcementBody => 'Message body';

  @override
  String get announcementSubtitle => 'Will be sent to all building residents';

  @override
  String get announcementCategoryLabel => 'Message type';

  @override
  String get boardCatUpdate => 'Important update';

  @override
  String get boardCatMeeting => 'Residents meeting';

  @override
  String get boardCatMaintenance => 'Maintenance';

  @override
  String get boardCatTip => 'Tip';

  @override
  String get boardCatOther => 'Other';

  @override
  String get boardActionDetails => 'Details';

  @override
  String get boardActionRead => 'Read';

  @override
  String get boardActionView => 'View';

  @override
  String get publishAnnouncement => 'Publish message';

  @override
  String get announcementPublished => 'The message was published to residents';

  @override
  String get editBoardMessage => 'Edit board message';

  @override
  String get deleteBoardMessage => 'Delete message';

  @override
  String get deleteBoardMessageConfirm =>
      'Remove this message from the building board? Residents will no longer see it.';

  @override
  String get announcementUpdated => 'Message updated';

  @override
  String get announcementDeleted => 'Message deleted';

  @override
  String get auditAnnouncementUpdated => 'Announcement updated';

  @override
  String get auditAnnouncementDeleted => 'Announcement deleted';

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
  String get findZipCode => 'Find postal code';

  @override
  String get lookingUpZip => 'Looking up postal code…';

  @override
  String get zipLookupFailed =>
      'Couldn’t find a postal code for this address. You can enter it manually.';

  @override
  String get zipLookupUnavailable =>
      'Postal-code lookup is unavailable right now (AI service). You can enter it manually.';

  @override
  String get apartmentsCount => 'Apartments';

  @override
  String get apartmentsPerFloor => 'Per floor';

  @override
  String get numberOfApartments => 'Number of apartments';

  @override
  String get numberOfFloors => 'Number of floors';

  @override
  String get typicalFloorLabel => 'On a typical floor';

  @override
  String get baseFloorLabel => 'First floor';

  @override
  String get firstApartmentShortLabel => 'First apartment';

  @override
  String get structureStepSubtitle =>
      'Set the typical floor, then fix only the exceptions.';

  @override
  String floorsRangeSummary(
    String from,
    String to,
    String aptFrom,
    String aptTo,
  ) {
    return 'Floors will run from $from to $to · apartments numbered $aptFrom–$aptTo';
  }

  @override
  String get floorDivisionTitle => 'Floor breakdown';

  @override
  String resetExceptions(String count) {
    return 'Reset $count exceptions';
  }

  @override
  String floorBadge(String floor) {
    return 'fl.$floor';
  }

  @override
  String get floorBadgeGround => 'G';

  @override
  String floorAptsCount(String count) {
    return '$count apartments';
  }

  @override
  String floorAptsRange(String from, String to) {
    return 'Apts $from–$to';
  }

  @override
  String get exceptionBadge => 'Exception';

  @override
  String get mappingTotalLabel => 'Total in mapping';

  @override
  String mappingTotalMeta(String apts, String floors) {
    return '$apts apartments · $floors floors';
  }

  @override
  String get floorPlanMismatch =>
      'Floor counts must add up to the total apartments';

  @override
  String get feeMethodLabel => 'Vaad fee';

  @override
  String get feeFixed => 'Fixed per apartment';

  @override
  String get feePerSqm => 'Per square meter';

  @override
  String get monthlyAmount => 'Monthly amount (₪)';

  @override
  String get feeFixedMonthlyLabel => 'Apartment fee · monthly';

  @override
  String get feePerApartmentUnit => 'per apt';

  @override
  String get pricePerSqmLabel => 'Price per m² (₪)';

  @override
  String get updateVaadFee => 'Vaad fee settings';

  @override
  String get buildingSettings => 'Building settings';

  @override
  String get joinPolicySection => 'Join policy';

  @override
  String get createBuildingStepYou => 'Your details';

  @override
  String get createBuildingStepPlace => 'Building address';

  @override
  String get createBuildingStepEntrances => 'Entrances & elevators';

  @override
  String get createBuildingStepStructure => 'Floors & apartments';

  @override
  String get createBuildingStepFees => 'Committee fees';

  @override
  String get createBuildingStepMyApartment => 'Your apartment';

  @override
  String get createBuildingStepServices => 'Regular services';

  @override
  String get createBuildingStepBalance => 'Bank balance';

  @override
  String get createBuildingStepSummary => 'Summary & confirm';

  @override
  String get createBuildingYouSubtitle =>
      'These details are shown to residents as the committee contact.';

  @override
  String get createBuildingYouAptLaterNote =>
      'On the apartment step you’ll set your unit — number, occupants, and documents — like any resident.';

  @override
  String get createBuildingMyAptSubtitle =>
      'Enter your unit details. We’ll create the apartment and assign you to it as Vaad.';

  @override
  String get createBuildingPlaceSubtitle =>
      'One address for protocols, receipts, and invites.';

  @override
  String get createBuildingEntrancesSubtitle =>
      'Entrance codes and elevators for your building.';

  @override
  String get createBuildingFeesSubtitle =>
      'Set how monthly committee fees are calculated.';

  @override
  String get createBuildingServicesSubtitle =>
      'Set recurring services for the building calendar. You can change these later.';

  @override
  String get createBuildingSummarySubtitle =>
      'Review everything before creating the building.';

  @override
  String get serviceCleaningStairs => 'Stairwell cleaning';

  @override
  String get serviceGarbage => 'Trash removal';

  @override
  String get serviceGardening => 'Gardening';

  @override
  String get servicePest => 'Pest control';

  @override
  String get serviceWaterTank => 'Water tank cleaning';

  @override
  String get serviceFrequencyWeekly => 'Weekly';

  @override
  String get serviceFrequencyBiweekly => 'Biweekly';

  @override
  String get serviceFrequencyMonthly => 'Monthly';

  @override
  String get serviceFrequencyQuarterly => 'Quarterly';

  @override
  String get serviceFrequencyYearly => 'Yearly';

  @override
  String get serviceCostHint => '₪ Cost';

  @override
  String get serviceProviderHint => 'Provider name';

  @override
  String get serviceAddCustom => 'Add custom service';

  @override
  String get serviceCustomTitle => 'Service name';

  @override
  String get serviceSkipLater => 'Skip — you can add later';

  @override
  String serviceEstimatedMonthly(String amount) {
    return 'Estimated monthly expense · ₪$amount';
  }

  @override
  String serviceBalanceAfterFees(String amount) {
    return 'Remaining after collection · ₪$amount';
  }

  @override
  String get serviceCalendarNote =>
      'Enabled services appear on the building calendar with reminders for the committee.';

  @override
  String get serviceDayOfMonth => 'Day of month';

  @override
  String get serviceOffHint => 'Off — tap to set schedule';

  @override
  String get serviceDaySun => 'S';

  @override
  String get serviceDayMon => 'M';

  @override
  String get serviceDayTue => 'T';

  @override
  String get serviceDayWed => 'W';

  @override
  String get serviceDayThu => 'T';

  @override
  String get serviceDayFri => 'F';

  @override
  String get serviceDaySat => 'S';

  @override
  String get summaryServicesTitle => 'Regular services';

  @override
  String get summaryServicesNone => 'None selected';

  @override
  String get verifiedPhoneLabel => 'Verified phone';

  @override
  String get myApartmentNumber => 'Apartment number';

  @override
  String get committeeApartmentNote =>
      'This apartment will be marked as the committee apartment in the directory.';

  @override
  String get vaadAptClaimTitle => 'Your apartment';

  @override
  String get vaadAptClaimSubtitle =>
      'Pick your unit from the mapped apartments. We’ll create every unit in the building and assign you to this one as Vaad.';

  @override
  String vaadAptRangeHint(String from, String to) {
    return 'Numbers in this plan: $from–$to';
  }

  @override
  String get vaadAptOutOfPlan =>
      'That apartment number is not in the floor plan you set';

  @override
  String vaadAptSqmHint(String typical) {
    return 'Optional — building typical is $typical m²';
  }

  @override
  String get countryIsrael => 'Israel';

  @override
  String get countryUsa => 'USA';

  @override
  String get countryOther => 'Other';

  @override
  String get districtOptional => 'District / region (optional)';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get locatingAddress => 'Finding your address…';

  @override
  String get locationFilledHint =>
      'Filled from your location — you can edit any field.';

  @override
  String get locationOutsideIsrael =>
      'Location isn’t in Israel. Country stays Israel — fill the address manually, or switch country.';

  @override
  String get locationUnavailable =>
      'Couldn’t read your location. You can fill the address manually.';

  @override
  String addressAlreadyRegistered(String name) {
    return 'A building already exists at this exact address ($name). You can’t create another one here — ask to join it instead.';
  }

  @override
  String get addressAlreadyRegisteredTitle => 'Address already taken';

  @override
  String get gotIt => 'Got it';

  @override
  String get entrancesCountLabel => 'Entrances';

  @override
  String get elevatorsCountLabel => 'Elevators';

  @override
  String get entranceCodesTitle => 'Entrance codes';

  @override
  String get entranceCodeHint => 'Code (optional)';

  @override
  String get entranceCodesPrivacyNote =>
      'Entrance codes are visible only to residents of this building.';

  @override
  String get typicalApartmentSqmLabel => 'Typical apartment size (m²)';

  @override
  String feePreviewSize(String sqm) {
    return '$sqm m² apartment';
  }

  @override
  String feePreviewTypical(String sqm) {
    return 'Typical · $sqm m²';
  }

  @override
  String get feeTemporaryNote =>
      'Until each apartment has its size set, billing uses the typical size.';

  @override
  String get billingDayLabel => 'Billing day of month';

  @override
  String billingDaySummary(String day) {
    return 'Billing day: $day';
  }

  @override
  String get expectedMonthlyCollection => 'Expected monthly collection';

  @override
  String get sqmUnit => 'm²';

  @override
  String get summaryContactTitle => 'Contact';

  @override
  String get summaryAddressTitle => 'Address';

  @override
  String get summaryBuildingTitle => 'Building';

  @override
  String get summaryFloorsTitle => 'Floors';

  @override
  String get summaryFeesTitle => 'Fees';

  @override
  String summaryEntrancesLine(String entrances, String elevators) {
    return '$entrances entrances · $elevators elevators';
  }

  @override
  String apartmentLabel(String n) {
    return 'Apt $n';
  }

  @override
  String createBuildingNextWithApts(String n) {
    return 'Continue · $n apartments';
  }

  @override
  String get openingBalanceTitle => 'Building cash balance';

  @override
  String get openingBalanceBody =>
      'How much money is currently in the building bank account or cash box? This is the starting balance in the app — paid dues add up, expenses subtract. You can leave 0 and update later.';

  @override
  String get openingBalanceLabel => 'Current cash balance (₪)';

  @override
  String get openingBalanceHint => 'Optional — leave empty for now.';

  @override
  String get openingBalanceSkip => 'Start from zero';

  @override
  String get openingBalanceRow => 'Opening balance';

  @override
  String get createBuildingNext => 'Continue';

  @override
  String get createBuildingBack => 'Back';

  @override
  String createBuildingStepOf(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String get comingSoonSection => 'More configuration';

  @override
  String get shareAppSection => 'Share Buildingo';

  @override
  String get shareAppTitle => 'Share the app';

  @override
  String get shareAppSubtitle => 'Invite other buildings via WhatsApp';

  @override
  String shareAppMessage(String link) {
    return 'Hey! We run our building with Buildingo — dues, residents, and maintenance in one app. Download here: $link';
  }

  @override
  String get comingSoon => 'Soon';

  @override
  String get entranceCodesSoon => 'Entrance codes (front / back)';

  @override
  String get garbageScheduleSoon => 'Garbage collection schedule';

  @override
  String get cleaningScheduleSoon => 'Cleaning schedule';

  @override
  String get saveFee => 'Save & notify residents';

  @override
  String get vaadFeeSaved => 'Fee updated — residents were notified';

  @override
  String get apartmentSizeSqm => 'Apartment size (m²)';

  @override
  String get apartmentSizeRequired =>
      'Apartment size from Arnona bill is required';

  @override
  String monthlyFeePreview(String amount) {
    return 'Your monthly Vaad fee: $amount';
  }

  @override
  String monthlyFeePreviewPerSqm(String amount, String sqm, String rate) {
    return '$amount/mo ($sqm m² × $rate/m², rounded up)';
  }

  @override
  String existingApartmentSize(String sqm) {
    return 'Known apartment size: $sqm m²';
  }

  @override
  String get sqmExtracted => 'Size read from your Arnona bill';

  @override
  String get sqmEnterManually =>
      'Could not read size — enter it manually below';

  @override
  String get yourMonthlyVaadFee => 'Monthly Vaad fee';

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
  String collectionSummaryLine(String unpaid, String total, String pct) {
    return '$unpaid apartments unpaid · of $total · $pct% collected';
  }

  @override
  String collectionStatSub(String unpaid, String total, String pct) {
    return '$unpaid of $total · $pct% collected';
  }

  @override
  String get collectedThisMonth => 'Collected this month';

  @override
  String get remainingThisMonth => 'Still to collect';

  @override
  String collectionHeroSub(String collected, String pct) {
    return '$collected collected · $pct%';
  }

  @override
  String get noTicketsThisMonth => 'No new tickets this month';

  @override
  String ticketsThisMonth(String n) {
    return '$n new this month';
  }

  @override
  String get ticketsSameAsLastMonth => 'Same as last month';

  @override
  String ticketsUpVsLastMonth(String pct) {
    return '+$pct% vs last month';
  }

  @override
  String ticketsDownVsLastMonth(String pct) {
    return '-$pct% vs last month';
  }

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
  String get buildingSchedule => 'Building schedule';

  @override
  String get whatsappConnect => 'WhatsApp';

  @override
  String get whatsappConnectBody =>
      'Connect a WhatsApp number for this building, then link the residents group. Buildingo will listen for fault reports in that group and open tickets automatically. You can also message tenants over WhatsApp.';

  @override
  String get whatsappNotConfigured =>
      'WhatsApp (WAHA) is not configured on the server yet.';

  @override
  String get whatsappConnected => 'WhatsApp connected';

  @override
  String get whatsappNotConnected => 'WhatsApp not connected';

  @override
  String get whatsappStartSession => 'Start WhatsApp connection';

  @override
  String get whatsappScanQr => 'Scan this QR with WhatsApp → Linked devices';

  @override
  String get whatsappPickGroup => 'Choose the building WhatsApp group';

  @override
  String get whatsappGroupLinked => 'Building group linked';

  @override
  String get whatsappLoadGroups => 'Load groups';

  @override
  String get comingUp => 'Coming up';

  @override
  String get viewCalendar => 'Full schedule';

  @override
  String get scheduleGarbage => 'Garbage collection';

  @override
  String get scheduleCleaning => 'Building cleaning';

  @override
  String get scheduleBulkWaste => 'Bulk waste pickup';

  @override
  String get scheduleOther => 'Other';

  @override
  String get addScheduleEvent => 'Add to schedule';

  @override
  String get scheduleEmptyTitle => 'No schedule yet';

  @override
  String get scheduleEmptyBody =>
      'Add garbage collection days, cleaning times and one-off pickups so everyone in the building knows what\'s coming.';

  @override
  String get scheduleDayEmptyTitle => 'Nothing on this day';

  @override
  String get scheduleDayEmptyBody =>
      'No building events scheduled for this day.';

  @override
  String get scheduleDayEmptyBodyVaad =>
      'No events yet — tap + to add something for this day.';

  @override
  String get announcementDateOptional => 'Date on calendar (optional)';

  @override
  String get announcementDateHint =>
      'Add a date to show this on the building calendar';

  @override
  String get clear => 'Clear';

  @override
  String get scheduleWeekly => 'Weekly';

  @override
  String get scheduleBiweekly => 'Every 2 weeks';

  @override
  String get scheduleDaily => 'Daily';

  @override
  String get scheduleMonthly => 'Monthly';

  @override
  String get scheduleRepeat => 'Repeat';

  @override
  String get scheduleDayOfMonth => 'Day of month';

  @override
  String get scheduleOnce => 'One-time';

  @override
  String get scheduleDay => 'Day of week';

  @override
  String get scheduleDate => 'Date';

  @override
  String get scheduleTimeOptional => 'Time (optional)';

  @override
  String get scheduleNotesOptional => 'Notes (optional)';

  @override
  String get scheduleSaved => 'Schedule updated';

  @override
  String get scheduleNotReady =>
      'Building schedule is not ready yet. Run migration 0018_schedule_events.sql in the Supabase SQL editor, then try again.';

  @override
  String get scheduleTomorrow => 'Tomorrow';

  @override
  String get happeningToday => 'Happening today';

  @override
  String scheduleEventToday(String title) {
    return '$title today';
  }

  @override
  String get scheduleRecurring => 'Repeats weekly';

  @override
  String get scheduleEventTitle => 'Title';

  @override
  String get scheduleEventType => 'Event type';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

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
  String get agentsComingSoonBadge => 'Coming in the next version';

  @override
  String get agentsComingSoonTitle => 'AI agents for your vendors';

  @override
  String get agentsComingSoonBody =>
      'Soon, Buildingo will contact elevator, plumbing, and cleaning vendors for you — open the service call, follow up, and keep residents in the loop.';

  @override
  String get agentsComingSoonFeature1 =>
      'Reach vendors by email, SMS, or WhatsApp';

  @override
  String get agentsComingSoonFeature2 =>
      'One tap after you approve a resident fault';

  @override
  String get agentsComingSoonFeature3 =>
      'Automatic updates back to the building board';

  @override
  String get agentsComingSoonFootnote =>
      'Available in the next Buildingo release — stay tuned.';

  @override
  String get paymentsComingSoonBadge => 'Coming soon';

  @override
  String get paymentsComingSoonTitle => 'Pay building dues in the app';

  @override
  String get paymentsComingSoonBody =>
      'You opened Buildingo from your payment reminder. In-app payment is on the way — for now you can review dues in the Payments tab, or pay as usual outside the app.';

  @override
  String get agentDispatchComingSoon =>
      'AI vendor dispatch arrives in the next version. For now, move the ticket to In progress and handle the vendor yourself.';

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

  @override
  String get inviteViaLink => 'Invite residents via link';

  @override
  String get inviteResidents => 'Invite residents';

  @override
  String get inviteLinkExplain =>
      'Anyone who opens this link can ask to join the building — you approve them here.';

  @override
  String get copyLink => 'Copy link';

  @override
  String get invitePending => 'Invited · waiting to connect';

  @override
  String get findBuildingHint =>
      'Search by city and address — pick from the suggestions so we find an exact match.';

  @override
  String get pickCityFirst => 'Choose a city first';

  @override
  String get pickStreetFirst => 'Choose a street first';

  @override
  String get streetLabel => 'Street';

  @override
  String get houseNumberLabel => 'House number';

  @override
  String get pickFromGovList => 'Pick from the official list';

  @override
  String get govAddressHint =>
      'City and street come from the Israel government registry so every building uses the same spelling.';

  @override
  String get askVaadInviteHint =>
      'Can\'t find your building? Ask your Vaad to send you a personal invite or the building\'s join link.';

  @override
  String get tenantProfileTitle => 'Your details';

  @override
  String get tenantProfileHint =>
      'These details are sent to the building\'s Vaad, who approves your request.';

  @override
  String get floorLabel => 'Floor';

  @override
  String get numOccupantsLabel => 'Occupants';

  @override
  String get parkingOptional => 'Parking (optional)';

  @override
  String get parkingSpotsLabel => 'Parking spots (optional)';

  @override
  String get parkingSpotHint => 'e.g. B-12';

  @override
  String get addParkingSpot => 'Add another parking spot';

  @override
  String get attachDocOptional => 'Attach a document (optional)';

  @override
  String get sendJoinRequest => 'Send join request';

  @override
  String occupantsN(String n) {
    return '$n occupants';
  }

  @override
  String get viewAttachedDoc => 'View attached document';

  @override
  String get docsSection => 'Recommended documents';

  @override
  String get docsSectionRequired => 'Required documents';

  @override
  String get docsExplain =>
      'The Arnona bill shows the apartment\'s size (sqm), which affects the Vaad fee. The agreement confirms you live in this apartment.';

  @override
  String get attachArnona => 'Arnona bill';

  @override
  String get arnonaHint => 'Shows the apartment size in sqm';

  @override
  String get attachResidence => 'Proof of residence';

  @override
  String get residenceHint => 'Rent or purchase agreement';

  @override
  String get optional => 'optional';

  @override
  String get requireDocsTitle => 'Require documents to join';

  @override
  String get requireDocsSubtitle =>
      'New residents must attach an Arnona bill and proof of residence';

  @override
  String get joinRequestPending => 'Join request awaiting approval';

  @override
  String get financesTitle => 'Payments';

  @override
  String get expensesTab => 'Expenses';

  @override
  String collectionSummary(String count, String pct, String amount) {
    return '$count apartments · $pct% collected · $amount debt';
  }

  @override
  String get allApartments => 'All apartments';

  @override
  String get onlyWithDebt => 'With debt only';

  @override
  String get searchPayments => 'Search by apartment, name or phone';

  @override
  String get noPaymentSearchResults => 'No apartments match your search';

  @override
  String get collapseAll => 'Collapse all';

  @override
  String get apartmentColumn => 'Apt';

  @override
  String get debtColumn => 'Debt';

  @override
  String aptTiny(String n) {
    return 'Apt $n';
  }

  @override
  String debtAmount(String amount) {
    return '$amount debt';
  }

  @override
  String get noDebt => 'No debt';

  @override
  String get markFloorPaid => 'Mark floor as paid';

  @override
  String get residentsSection => 'Residents';

  @override
  String occupiedOfTotal(String occupied, String total) {
    return '$occupied/$total occupied';
  }

  @override
  String get searchResidents => 'Search by name, phone or apartment';

  @override
  String get pendingInvitesSection => 'Pending invitations';

  @override
  String get noDocsForApartment => 'No documents attached';

  @override
  String sqmShort(String n) {
    return '$n sqm';
  }

  @override
  String get currentPeriod => 'Current';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusUnpaid => 'Not paid';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get noApartmentsYet => 'No apartments defined yet';

  @override
  String get noExpensesYet => 'No expenses recorded yet';

  @override
  String get providerOptional => 'Provider (optional)';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get attachReceipt => 'Attach a receipt (optional)';

  @override
  String get viewReceipt => 'View receipt';

  @override
  String paymentReceiptTitle(String month, String year) {
    return 'Payment receipt · $month $year';
  }

  @override
  String get paymentReceiptsSection => 'Payment receipts';

  @override
  String get expenseSaved => 'Expense recorded';

  @override
  String joinApprovedSnack(String name) {
    return '$name was approved and joined the building';
  }

  @override
  String joinRejectedSnack(String name) {
    return '$name\'s request was rejected';
  }

  @override
  String newJoinRequestSnack(String name) {
    return 'New join request from $name';
  }

  @override
  String get newJoinRequestSnackGeneric => 'New join request awaiting approval';

  @override
  String get viewArnonaDoc => 'View Arnona bill';

  @override
  String get viewResidenceDoc => 'View proof of residence';

  @override
  String get myBuilding => 'My building';

  @override
  String get trialNotice =>
      '14-day free trial: full access for the whole building. Afterwards it\'s just ₪4.90 per apartment per month — contact us to subscribe.';

  @override
  String get trialEndedTitle => 'The free trial has ended';

  @override
  String get trialEndedBody =>
      'Your building\'s 14-day trial is over. All your data is safe and waiting for you.';

  @override
  String get accessBlockedTitle => 'Access is suspended';

  @override
  String get accessBlockedBody =>
      'Access for this building has been suspended. Contact us to restore it — all data is kept.';

  @override
  String get accountSuspendedTitle => 'Account suspended';

  @override
  String get accountSuspendedBody =>
      'Your account has been suspended. Contact support if you believe this is a mistake.';

  @override
  String get pricingLine => '₪4.90 per apartment / month';

  @override
  String get likeItContactUs =>
      'Like Buildingo? Contact us and we\'ll activate your building\'s subscription — no in-app payment needed.';

  @override
  String get contactUs => 'Contact us';

  @override
  String get contactFormHint =>
      'Leave your details and we\'ll get back to you shortly.';

  @override
  String get contactMessage => 'Message';

  @override
  String get contactSend => 'Send';

  @override
  String get invalidPhone => 'Invalid phone number';

  @override
  String get contactSentTitle => 'Message sent!';

  @override
  String get contactSentBody =>
      'Thanks! We received your message and will get back to you soon.';

  @override
  String get transferHolder => 'Replace holder';

  @override
  String get holdersHistory => 'Holders history';

  @override
  String get currentHolder => 'Current holder';

  @override
  String get pendingHolder => 'Awaiting details';

  @override
  String get holderOwner => 'Owner';

  @override
  String get holderRenter => 'Renter';

  @override
  String get noPreviousHolders => 'No previous holders';

  @override
  String previousHoldersN(String n) {
    return '$n previous holders';
  }

  @override
  String periodSince(String date) {
    return 'Since $date';
  }

  @override
  String get newHolderFallback => 'New holder';

  @override
  String get noPhone => 'no phone';

  @override
  String apartmentCardTitle(String n) {
    return 'Apartment $n card';
  }

  @override
  String get stepEndTenancy => 'End tenancy';

  @override
  String get stepIncomingHolder => 'Incoming holder';

  @override
  String get stepConfirmTransfer => 'Confirm & transfer';

  @override
  String endTenancyTitle(String name) {
    return 'End tenancy — $name';
  }

  @override
  String get endTenancyBody =>
      'The apartment card is fully preserved. The outgoing holder is archived with their period, and the history stays attached to the apartment.';

  @override
  String get endDateLabel => 'Effective end date';

  @override
  String get debtQuestion => 'What happens to open dues';

  @override
  String get debtKeepTitle => 'Debt stays with the outgoing renter';

  @override
  String get debtKeepBody =>
      'Open dues remain in their name and stay in collection tracking';

  @override
  String get debtOwnerTitle => 'Debt is transferred to the owner';

  @override
  String get debtOwnerBody =>
      'The Vaad will collect from the owner per the contract clause';

  @override
  String get debtCloseTitle => 'Close the debt';

  @override
  String get debtCloseBody =>
      'The debt is cleared by Vaad decision — recorded in the building log';

  @override
  String incomingDetailsBody(String n, String date) {
    return 'The details will be attached to apartment $n from $date.';
  }

  @override
  String get modeSelfTitle => 'The holder fills in their own details';

  @override
  String get modeSelfBody =>
      'We send a link by SMS. They verify their phone and fill in name, occupants and contract — the apartment is marked \"awaiting details\" until then.';

  @override
  String get modeVaadTitle => 'Filled in by the Vaad';

  @override
  String get modeVaadBody =>
      'Fill in the details here and now. A link can still be sent later.';

  @override
  String get optionalField => 'Optional';

  @override
  String get mobilePhoneLabel => 'Mobile phone';

  @override
  String get holderTypeLabel => 'Holding type';

  @override
  String get startDateLabel => 'Tenancy start date';

  @override
  String get sendSmsOnTransfer =>
      'Send the link by SMS as soon as the transfer is confirmed';

  @override
  String get linkExplainTitle => 'What the holder completes';

  @override
  String get linkStepOtp => 'Phone verification with an SMS code';

  @override
  String get linkStepProfile => 'Full name and number of occupants';

  @override
  String get linkStepContract => 'Uploading a rental contract · not mandatory';

  @override
  String get linkStepConfirm => 'Confirming parking and contact details';

  @override
  String get selfCompleteNote =>
      'The holder will complete their details via the link';

  @override
  String get keptOnCardTitle => 'Kept on the apartment card';

  @override
  String get keptOnCardBody =>
      'Payment history, maintenance tickets, the apartment\'s receipts and assembly protocols';

  @override
  String get movesToNewTitle => 'Moves to the new holder';

  @override
  String get movesToNewBody =>
      'Dues from the effective date, access to the building board, the residents book and votes';

  @override
  String get staysWithOutgoingTitle => 'Stays with the outgoing holder';

  @override
  String get staysWithOutgoingBody =>
      'Their rental contract and personal documents · app access is blocked on the effective date';

  @override
  String get transferLogNote =>
      'The transfer is recorded in the building log with the approver\'s name and the date. All previous holders can be viewed on the apartment card.';

  @override
  String get confirmAndTransfer => 'Confirm & transfer';

  @override
  String get backBtn => 'Back';

  @override
  String get transferDone => 'The holder was replaced successfully';

  @override
  String get auditTenantTransferred => 'Holder replaced';

  @override
  String get pollOptionsLabel => 'Answer options';

  @override
  String optionHint(String n) {
    return 'Option $n';
  }

  @override
  String get addOption => 'Add option';

  @override
  String get allowMultipleAnswers => 'Allow multiple answers';

  @override
  String get multiChoiceChip => 'Multiple answers';

  @override
  String optionsCount(String n) {
    return '$n options';
  }

  @override
  String get submitVote => 'Submit vote';

  @override
  String get allSettled => 'All settled';

  @override
  String monthsPaidOfYear(String paid, String total, String year) {
    return '$paid of $total months paid · $year';
  }

  @override
  String get noChargesForYear => 'No charges for this year';

  @override
  String paidOnDate(String date) {
    return 'Paid on $date';
  }

  @override
  String get receiptShort => 'Receipt';

  @override
  String get receiptAttached => 'Receipt attached';

  @override
  String get attachReceiptOnlyPaid =>
      'A receipt can only be attached to a paid month';

  @override
  String get attachReceiptHint =>
      'Long-press a paid month to attach a receipt. A receipt icon stays clickable even if the month is unpaid.';

  @override
  String get confirmUnmarkPaymentTitle => 'Mark as not paid?';

  @override
  String confirmUnmarkPaymentBody(String who, String month, String year) {
    return 'Mark $who as not paid for $month $year?';
  }

  @override
  String get paymentHasReceiptNote => 'This month has a receipt attached.';

  @override
  String get keepPaymentReceipt => 'Keep the receipt';

  @override
  String get removePaymentReceipt => 'Remove the receipt';

  @override
  String get confirmMarkUnpaid => 'Mark unpaid';

  @override
  String get markPaymentPaid => 'Mark as paid';

  @override
  String get receiptOnUnpaidHint => 'Receipt on file';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get fromGallery => 'Choose from gallery';

  @override
  String get chooseFile => 'Browse files';

  @override
  String get locOther => 'Other';

  @override
  String get locOtherHint => 'Where exactly?';

  @override
  String get uploadDocument => 'Upload document';

  @override
  String get documentsUploaded => 'Documents uploaded';

  @override
  String get addAttachment => 'Add file (camera / gallery)';

  @override
  String get addMoreFiles => 'Add more files';

  @override
  String uploadNFiles(String n) {
    return 'Upload $n files';
  }

  @override
  String get allYear => 'Whole year';
}
