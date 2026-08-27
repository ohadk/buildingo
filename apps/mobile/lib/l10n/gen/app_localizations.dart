import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Buildingo'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Buildingo'**
  String get welcome;

  /// No description provided for @signInWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your phone number'**
  String get signInWithPhone;

  /// No description provided for @enterCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent to {phone}'**
  String enterCodeSentTo(String phone);

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @smsCode.
  ///
  /// In en, this message translates to:
  /// **'SMS code'**
  String get smsCode;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWait;

  /// No description provided for @verifyAndSignIn.
  ///
  /// In en, this message translates to:
  /// **'Verify & sign in'**
  String get verifyAndSignIn;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @useDifferentNumber.
  ///
  /// In en, this message translates to:
  /// **'Use a different number'**
  String get useDifferentNumber;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfile;

  /// No description provided for @apartmentAndFloor.
  ///
  /// In en, this message translates to:
  /// **'Apartment {apt}, floor {floor}'**
  String apartmentAndFloor(String apt, String floor);

  /// No description provided for @noInviteFound.
  ///
  /// In en, this message translates to:
  /// **'No invitation matched your phone number. Paste the invite code your Vaad sent you:'**
  String get noInviteFound;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @numOccupants.
  ///
  /// In en, this message translates to:
  /// **'Number of occupants'**
  String get numOccupants;

  /// No description provided for @uploadLease.
  ///
  /// In en, this message translates to:
  /// **'Upload lease (optional)'**
  String get uploadLease;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @enterMyBuilding.
  ///
  /// In en, this message translates to:
  /// **'Enter my building'**
  String get enterMyBuilding;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get navPayments;

  /// No description provided for @navMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get navMaintenance;

  /// No description provided for @navResidents.
  ///
  /// In en, this message translates to:
  /// **'Residents'**
  String get navResidents;

  /// No description provided for @navDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get navDocs;

  /// No description provided for @neighbor.
  ///
  /// In en, this message translates to:
  /// **'neighbor'**
  String get neighbor;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String hello(String name);

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @reportFault.
  ///
  /// In en, this message translates to:
  /// **'Report Fault'**
  String get reportFault;

  /// No description provided for @payDues.
  ///
  /// In en, this message translates to:
  /// **'Pay Dues'**
  String get payDues;

  /// No description provided for @assemblies.
  ///
  /// In en, this message translates to:
  /// **'Assemblies'**
  String get assemblies;

  /// No description provided for @myTickets.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get myTickets;

  /// No description provided for @noOpenTickets.
  ///
  /// In en, this message translates to:
  /// **'No open tickets — all quiet in the building.'**
  String get noOpenTickets;

  /// No description provided for @communityBoard.
  ///
  /// In en, this message translates to:
  /// **'Community Board'**
  String get communityBoard;

  /// No description provided for @fromTheVaad.
  ///
  /// In en, this message translates to:
  /// **'New message from the Vaad'**
  String get fromTheVaad;

  /// No description provided for @nothingOnBoard.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the board yet.'**
  String get nothingOnBoard;

  /// No description provided for @configureVendorFirst.
  ///
  /// In en, this message translates to:
  /// **'Configure a vendor agent first (menu → Vendor Agents).'**
  String get configureVendorFirst;

  /// No description provided for @dispatchToWhichVendor.
  ///
  /// In en, this message translates to:
  /// **'Dispatch AI agent to which vendor?'**
  String get dispatchToWhichVendor;

  /// No description provided for @agentDispatchingTo.
  ///
  /// In en, this message translates to:
  /// **'Agent dispatching to {vendor}…'**
  String agentDispatchingTo(String vendor);

  /// No description provided for @vendorContacted.
  ///
  /// In en, this message translates to:
  /// **'Vendor contacted.'**
  String get vendorContacted;

  /// No description provided for @dispatchFailed.
  ///
  /// In en, this message translates to:
  /// **'Dispatch failed: {message}'**
  String dispatchFailed(String message);

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @vendorAgents.
  ///
  /// In en, this message translates to:
  /// **'Vendor Agents'**
  String get vendorAgents;

  /// No description provided for @newReport.
  ///
  /// In en, this message translates to:
  /// **'New Report'**
  String get newReport;

  /// No description provided for @resident.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get resident;

  /// No description provided for @agentTo.
  ///
  /// In en, this message translates to:
  /// **'Agent → {vendor}'**
  String agentTo(String vendor);

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @approveAndDispatch.
  ///
  /// In en, this message translates to:
  /// **'Approve & Dispatch Agent'**
  String get approveAndDispatch;

  /// No description provided for @markResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark Resolved'**
  String get markResolved;

  /// No description provided for @reportAFault.
  ///
  /// In en, this message translates to:
  /// **'Report a Fault'**
  String get reportAFault;

  /// No description provided for @whatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get whatHappened;

  /// No description provided for @faultHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Elevator stuck on floor 3'**
  String get faultHint;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @detailsHint.
  ///
  /// In en, this message translates to:
  /// **'When did it start? Where exactly?'**
  String get detailsHint;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submitting;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @newVendorAgent.
  ///
  /// In en, this message translates to:
  /// **'New Vendor Agent'**
  String get newVendorAgent;

  /// No description provided for @vendorName.
  ///
  /// In en, this message translates to:
  /// **'Vendor name'**
  String get vendorName;

  /// No description provided for @vendorNameHint.
  ///
  /// In en, this message translates to:
  /// **'Schindler Elevator Service'**
  String get vendorNameHint;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Service type'**
  String get serviceType;

  /// No description provided for @serviceTypeHint.
  ///
  /// In en, this message translates to:
  /// **'elevator'**
  String get serviceTypeHint;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone +972… (optional)'**
  String get phoneOptional;

  /// No description provided for @vendorContactSection.
  ///
  /// In en, this message translates to:
  /// **'How should the agent open a ticket with the vendor?'**
  String get vendorContactSection;

  /// No description provided for @vendorContactHint.
  ///
  /// In en, this message translates to:
  /// **'The agent will contact the vendor only through the channels you pick here.'**
  String get vendorContactHint;

  /// No description provided for @channelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get channelEmail;

  /// No description provided for @channelSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get channelSms;

  /// No description provided for @channelWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get channelWhatsapp;

  /// No description provided for @vendorEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Vendor email'**
  String get vendorEmailLabel;

  /// No description provided for @vendorPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Vendor phone'**
  String get vendorPhoneLabel;

  /// No description provided for @errSelectChannel.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one contact channel'**
  String get errSelectChannel;

  /// No description provided for @errEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'The email channel needs the vendor\'s email address'**
  String get errEmailRequired;

  /// No description provided for @errPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'SMS/WhatsApp need the vendor\'s phone number'**
  String get errPhoneRequired;

  /// No description provided for @contractOptional.
  ///
  /// In en, this message translates to:
  /// **'Contract details (optional)'**
  String get contractOptional;

  /// No description provided for @aiInstructionsOptional.
  ///
  /// In en, this message translates to:
  /// **'Extra AI instructions (optional)'**
  String get aiInstructionsOptional;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @vendorAiAgents.
  ///
  /// In en, this message translates to:
  /// **'Vendor AI Agents'**
  String get vendorAiAgents;

  /// No description provided for @generatedDues.
  ///
  /// In en, this message translates to:
  /// **'Generated {count} dues rows for {month}.'**
  String generatedDues(String count, String month);

  /// No description provided for @recordExpense.
  ///
  /// In en, this message translates to:
  /// **'Record expense'**
  String get recordExpense;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'electricity'**
  String get categoryHint;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @generateMonthDues.
  ///
  /// In en, this message translates to:
  /// **'Generate this month\'s dues'**
  String get generateMonthDues;

  /// No description provided for @outstandingDues.
  ///
  /// In en, this message translates to:
  /// **'Outstanding dues'**
  String get outstandingDues;

  /// No description provided for @youOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get youOwe;

  /// No description provided for @buildingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Building expenses'**
  String get buildingExpenses;

  /// No description provided for @paymentMatrix.
  ///
  /// In en, this message translates to:
  /// **'Payment matrix'**
  String get paymentMatrix;

  /// No description provided for @myDues.
  ///
  /// In en, this message translates to:
  /// **'My dues'**
  String get myDues;

  /// No description provided for @apartmentShort.
  ///
  /// In en, this message translates to:
  /// **'Apt {number}'**
  String apartmentShort(String number);

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get markPaid;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get overdue;

  /// No description provided for @pendingPayment.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pendingPayment;

  /// No description provided for @expenseLedger.
  ///
  /// In en, this message translates to:
  /// **'Building expense ledger'**
  String get expenseLedger;

  /// No description provided for @inviteResidentTo.
  ///
  /// In en, this message translates to:
  /// **'Invite resident to Apt {apt}'**
  String inviteResidentTo(String apt);

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get sendInvite;

  /// No description provided for @inviteSmsSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation SMS sent.'**
  String get inviteSmsSent;

  /// No description provided for @inviteCreatedCode.
  ///
  /// In en, this message translates to:
  /// **'Invite created — code: {code}'**
  String inviteCreatedCode(String code);

  /// No description provided for @directoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Directory & Parking'**
  String get directoryTitle;

  /// No description provided for @floorN.
  ///
  /// In en, this message translates to:
  /// **'Floor {n}'**
  String floorN(String n);

  /// No description provided for @vacant.
  ///
  /// In en, this message translates to:
  /// **'Vacant / not registered'**
  String get vacant;

  /// No description provided for @parkingSpot.
  ///
  /// In en, this message translates to:
  /// **'Parking: {spot}'**
  String parkingSpot(String spot);

  /// No description provided for @noParking.
  ///
  /// In en, this message translates to:
  /// **'No parking assigned'**
  String get noParking;

  /// No description provided for @inviteResident.
  ///
  /// In en, this message translates to:
  /// **'Invite resident'**
  String get inviteResident;

  /// No description provided for @cantOpenDocument.
  ///
  /// In en, this message translates to:
  /// **'Could not open document'**
  String get cantOpenDocument;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents yet. Meeting summaries, receipts and protocols will appear here.'**
  String get noDocuments;

  /// No description provided for @buildingWide.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get buildingWide;

  /// No description provided for @voteRecorded.
  ///
  /// In en, this message translates to:
  /// **'Vote recorded: {option}'**
  String voteRecorded(String option);

  /// No description provided for @newAssembly.
  ///
  /// In en, this message translates to:
  /// **'New assembly'**
  String get newAssembly;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get activityLog;

  /// No description provided for @activityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get activityEmptyTitle;

  /// No description provided for @activityEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Every action in the building — tenants joining, tickets, assemblies, votes and payments — will be recorded here.'**
  String get activityEmptyBody;

  /// No description provided for @auditTenantJoined.
  ///
  /// In en, this message translates to:
  /// **'Tenant joined'**
  String get auditTenantJoined;

  /// No description provided for @auditJoinRequested.
  ///
  /// In en, this message translates to:
  /// **'Join request'**
  String get auditJoinRequested;

  /// No description provided for @auditJoinRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get auditJoinRejected;

  /// No description provided for @auditTicketCreated.
  ///
  /// In en, this message translates to:
  /// **'Ticket opened'**
  String get auditTicketCreated;

  /// No description provided for @auditTicketDispatched.
  ///
  /// In en, this message translates to:
  /// **'Ticket sent to vendor'**
  String get auditTicketDispatched;

  /// No description provided for @auditTicketStatus.
  ///
  /// In en, this message translates to:
  /// **'Ticket status updated'**
  String get auditTicketStatus;

  /// No description provided for @auditMeetingCreated.
  ///
  /// In en, this message translates to:
  /// **'Assembly scheduled'**
  String get auditMeetingCreated;

  /// No description provided for @auditMeetingClosed.
  ///
  /// In en, this message translates to:
  /// **'Assembly closed'**
  String get auditMeetingClosed;

  /// No description provided for @auditVoteCast.
  ///
  /// In en, this message translates to:
  /// **'Vote cast'**
  String get auditVoteCast;

  /// No description provided for @auditPaymentMarked.
  ///
  /// In en, this message translates to:
  /// **'Payment marked'**
  String get auditPaymentMarked;

  /// No description provided for @auditPaymentsBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk payments marked'**
  String get auditPaymentsBulk;

  /// No description provided for @auditExpenseAdded.
  ///
  /// In en, this message translates to:
  /// **'Expense recorded'**
  String get auditExpenseAdded;

  /// No description provided for @auditAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Announcement published'**
  String get auditAnnouncement;

  /// No description provided for @auditVendorAdded.
  ///
  /// In en, this message translates to:
  /// **'Vendor agent added'**
  String get auditVendorAdded;

  /// No description provided for @auditVendorUpdated.
  ///
  /// In en, this message translates to:
  /// **'Vendor agent updated'**
  String get auditVendorUpdated;

  /// No description provided for @auditVendorDeleted.
  ///
  /// In en, this message translates to:
  /// **'Vendor agent deleted'**
  String get auditVendorDeleted;

  /// No description provided for @auditBuildingCreated.
  ///
  /// In en, this message translates to:
  /// **'Building created'**
  String get auditBuildingCreated;

  /// No description provided for @auditVaadInvited.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get auditVaadInvited;

  /// No description provided for @meetingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No assemblies yet'**
  String get meetingsEmptyTitle;

  /// No description provided for @meetingsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Plan resident assemblies, vote on decisions and publish summaries for the whole building.'**
  String get meetingsEmptyBody;

  /// No description provided for @residentsAssembly.
  ///
  /// In en, this message translates to:
  /// **'Residents assembly'**
  String get residentsAssembly;

  /// No description provided for @meetingLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get meetingLocationLabel;

  /// No description provided for @agendaItems.
  ///
  /// In en, this message translates to:
  /// **'Agenda items'**
  String get agendaItems;

  /// No description provided for @agendaItemsHint.
  ///
  /// In en, this message translates to:
  /// **'Add agenda items — each one can be a discussion or a vote.'**
  String get agendaItemsHint;

  /// No description provided for @newAgendaItem.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get newAgendaItem;

  /// No description provided for @withVote.
  ///
  /// In en, this message translates to:
  /// **'With a vote'**
  String get withVote;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addItem;

  /// No description provided for @voteChip.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get voteChip;

  /// No description provided for @discussionChip.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get discussionChip;

  /// No description provided for @createMeetingCta.
  ///
  /// In en, this message translates to:
  /// **'Create assembly'**
  String get createMeetingCta;

  /// No description provided for @whatToCreate.
  ///
  /// In en, this message translates to:
  /// **'What would you like to create?'**
  String get whatToCreate;

  /// No description provided for @ticketLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Fault location'**
  String get ticketLocationLabel;

  /// No description provided for @locLobby.
  ///
  /// In en, this message translates to:
  /// **'Lobby'**
  String get locLobby;

  /// No description provided for @locStairwell.
  ///
  /// In en, this message translates to:
  /// **'Stairwell'**
  String get locStairwell;

  /// No description provided for @locElevator.
  ///
  /// In en, this message translates to:
  /// **'Elevator'**
  String get locElevator;

  /// No description provided for @locParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get locParking;

  /// No description provided for @locRoof.
  ///
  /// In en, this message translates to:
  /// **'Roof'**
  String get locRoof;

  /// No description provided for @locYard.
  ///
  /// In en, this message translates to:
  /// **'Yard'**
  String get locYard;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @messageToBuilding.
  ///
  /// In en, this message translates to:
  /// **'Message to the building'**
  String get messageToBuilding;

  /// No description provided for @announcementBody.
  ///
  /// In en, this message translates to:
  /// **'Message body'**
  String get announcementBody;

  /// No description provided for @announcementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Will be sent to all building residents'**
  String get announcementSubtitle;

  /// No description provided for @publishAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Publish message'**
  String get publishAnnouncement;

  /// No description provided for @announcementPublished.
  ///
  /// In en, this message translates to:
  /// **'The message was published to residents'**
  String get announcementPublished;

  /// No description provided for @agenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get agenda;

  /// No description provided for @voteQuestionOptional.
  ///
  /// In en, this message translates to:
  /// **'Yes/No vote question (optional)'**
  String get voteQuestionOptional;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @voteYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get voteYes;

  /// No description provided for @voteNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get voteNo;

  /// No description provided for @voteAbstain.
  ///
  /// In en, this message translates to:
  /// **'Abstain'**
  String get voteAbstain;

  /// No description provided for @aiWritingSummary.
  ///
  /// In en, this message translates to:
  /// **'The AI is writing the summary…'**
  String get aiWritingSummary;

  /// No description provided for @summaryPublished.
  ///
  /// In en, this message translates to:
  /// **'Summary PDF published to the building bulletin.'**
  String get summaryPublished;

  /// No description provided for @assembliesAndVoting.
  ///
  /// In en, this message translates to:
  /// **'Assemblies & Voting'**
  String get assembliesAndVoting;

  /// No description provided for @closeAndPublish.
  ///
  /// In en, this message translates to:
  /// **'Close & publish summary'**
  String get closeAndPublish;

  /// No description provided for @stageReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get stageReported;

  /// No description provided for @stageApprovedByVaad.
  ///
  /// In en, this message translates to:
  /// **'Approved\nby Vaad'**
  String get stageApprovedByVaad;

  /// No description provided for @stageAgentWorking.
  ///
  /// In en, this message translates to:
  /// **'AI Agent\nDispatching'**
  String get stageAgentWorking;

  /// No description provided for @stageResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get stageResolved;

  /// No description provided for @vendorContactedShort.
  ///
  /// In en, this message translates to:
  /// **'Vendor contacted'**
  String get vendorContactedShort;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get language;

  /// No description provided for @howToJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to join?'**
  String get howToJoinTitle;

  /// No description provided for @welcomeNoBuilding.
  ///
  /// In en, this message translates to:
  /// **'Your phone number isn\'t linked to a building yet.'**
  String get welcomeNoBuilding;

  /// No description provided for @choiceVaadTitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Vaad member'**
  String get choiceVaadTitle;

  /// No description provided for @choiceVaadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'My building isn\'t on Buildingo yet — create it and invite the residents'**
  String get choiceVaadSubtitle;

  /// No description provided for @choiceTenantTitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m a tenant'**
  String get choiceTenantTitle;

  /// No description provided for @choiceTenantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'My building is already on Buildingo — find it and ask to join'**
  String get choiceTenantSubtitle;

  /// No description provided for @choiceCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'I have a code'**
  String get choiceCodeTitle;

  /// No description provided for @choiceCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Got an invite or a join link from the Vaad? Enter the code here'**
  String get choiceCodeSubtitle;

  /// No description provided for @joinCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get joinCodeTitle;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeLabel;

  /// No description provided for @checkCode.
  ///
  /// In en, this message translates to:
  /// **'Check code'**
  String get checkCode;

  /// No description provided for @joiningBuilding.
  ///
  /// In en, this message translates to:
  /// **'Joining {name}'**
  String joiningBuilding(String name);

  /// No description provided for @yourApartmentNumber.
  ///
  /// In en, this message translates to:
  /// **'Your apartment number'**
  String get yourApartmentNumber;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @createBuildingTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your building'**
  String get createBuildingTitle;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Street & number'**
  String get addressLabel;

  /// No description provided for @postalCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Postal code (optional)'**
  String get postalCodeOptional;

  /// No description provided for @apartmentsCount.
  ///
  /// In en, this message translates to:
  /// **'Apartments'**
  String get apartmentsCount;

  /// No description provided for @apartmentsPerFloor.
  ///
  /// In en, this message translates to:
  /// **'Per floor'**
  String get apartmentsPerFloor;

  /// No description provided for @feeMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Vaad fee'**
  String get feeMethodLabel;

  /// No description provided for @feeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed per apartment'**
  String get feeFixed;

  /// No description provided for @feePerSqm.
  ///
  /// In en, this message translates to:
  /// **'Per square meter'**
  String get feePerSqm;

  /// No description provided for @monthlyAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly amount (₪)'**
  String get monthlyAmount;

  /// No description provided for @pricePerSqmLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per m² (₪)'**
  String get pricePerSqmLabel;

  /// No description provided for @myApartmentOptional.
  ///
  /// In en, this message translates to:
  /// **'My apartment number (optional)'**
  String get myApartmentOptional;

  /// No description provided for @createMyBuilding.
  ///
  /// In en, this message translates to:
  /// **'Create building'**
  String get createMyBuilding;

  /// No description provided for @buildingCreated.
  ///
  /// In en, this message translates to:
  /// **'Your building is ready!'**
  String get buildingCreated;

  /// No description provided for @shareJoinLink.
  ///
  /// In en, this message translates to:
  /// **'Invite the residents with a WhatsApp link — they submit their details and you approve each one:'**
  String get shareJoinLink;

  /// No description provided for @joinPendingNote.
  ///
  /// In en, this message translates to:
  /// **'The Vaad approves your request before you get access'**
  String get joinPendingNote;

  /// No description provided for @shareOnWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get shareOnWhatsapp;

  /// No description provided for @joinLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Join link copied'**
  String get joinLinkCopied;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @shareJoinMessage.
  ///
  /// In en, this message translates to:
  /// **'Hi! Our building {name} is now managed on Buildingo. Tap to join: {link}'**
  String shareJoinMessage(String name, String link);

  /// No description provided for @findBuildingTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your building'**
  String get findBuildingTitle;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @noBuildingFound.
  ///
  /// In en, this message translates to:
  /// **'This building isn\'t on Buildingo yet. Ask your Vaad to download the app and create it — it takes two minutes.'**
  String get noBuildingFound;

  /// No description provided for @askToJoin.
  ///
  /// In en, this message translates to:
  /// **'Ask to join'**
  String get askToJoin;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to the Vaad!'**
  String get requestSent;

  /// No description provided for @waitingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Vaad approval'**
  String get waitingApprovalTitle;

  /// No description provided for @waitingApprovalBody.
  ///
  /// In en, this message translates to:
  /// **'We sent your request to the Vaad of {name}. You\'ll get access as soon as they approve it.'**
  String waitingApprovalBody(String name);

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @requestRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get requestRejectedTitle;

  /// No description provided for @requestRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'The Vaad of {name} declined your request. You can search for a different building or contact them directly.'**
  String requestRejectedBody(String name);

  /// No description provided for @searchAnotherBuilding.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get searchAnotherBuilding;

  /// No description provided for @joinRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Join requests'**
  String get joinRequestsTitle;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get reject;

  /// No description provided for @wantsApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment {apt}'**
  String wantsApartment(String apt);

  /// No description provided for @inviteLinkShare.
  ///
  /// In en, this message translates to:
  /// **'Invite residents'**
  String get inviteLinkShare;

  /// No description provided for @aptFloorAddress.
  ///
  /// In en, this message translates to:
  /// **'Apt {apt} · Floor {floor} · {address}'**
  String aptFloorAddress(String apt, String floor, String address);

  /// No description provided for @openTicketsStat.
  ///
  /// In en, this message translates to:
  /// **'Open tickets'**
  String get openTicketsStat;

  /// No description provided for @withAgentCount.
  ///
  /// In en, this message translates to:
  /// **'{n} with the AI agent'**
  String withAgentCount(String n);

  /// No description provided for @nextPayment.
  ///
  /// In en, this message translates to:
  /// **'Next payment'**
  String get nextPayment;

  /// No description provided for @allPaid.
  ///
  /// In en, this message translates to:
  /// **'All paid'**
  String get allPaid;

  /// No description provided for @vaadBadge.
  ///
  /// In en, this message translates to:
  /// **'Vaad'**
  String get vaadBadge;

  /// No description provided for @unpaidThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Unpaid this month'**
  String get unpaidThisMonth;

  /// No description provided for @collectedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Collected this month'**
  String get collectedThisMonth;

  /// No description provided for @ofTotal.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String ofTotal(String total);

  /// No description provided for @pendingJoinBanner.
  ///
  /// In en, this message translates to:
  /// **'{n} join requests await your approval'**
  String pendingJoinBanner(String n);

  /// No description provided for @newResidents.
  ///
  /// In en, this message translates to:
  /// **'New residents'**
  String get newResidents;

  /// No description provided for @noDuesYet.
  ///
  /// In en, this message translates to:
  /// **'Dues not generated yet'**
  String get noDuesYet;

  /// No description provided for @allApartmentsPaid.
  ///
  /// In en, this message translates to:
  /// **'All apartments are paid up this month.'**
  String get allApartmentsPaid;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} days ago'**
  String daysAgo(String n);

  /// No description provided for @announcementTag.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get announcementTag;

  /// No description provided for @vendorAgentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No AI agents yet'**
  String get vendorAgentsEmptyTitle;

  /// No description provided for @vendorAgentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'An AI agent contacts your vendors for you — by email, SMS or WhatsApp — and opens a service ticket the moment you approve a fault.'**
  String get vendorAgentsEmptyBody;

  /// No description provided for @vendorAgentsStep1.
  ///
  /// In en, this message translates to:
  /// **'Add a vendor with their contact details'**
  String get vendorAgentsStep1;

  /// No description provided for @vendorAgentsStep2.
  ///
  /// In en, this message translates to:
  /// **'Approve a resident\'s fault report'**
  String get vendorAgentsStep2;

  /// No description provided for @vendorAgentsStep3.
  ///
  /// In en, this message translates to:
  /// **'The agent opens the ticket with the vendor and keeps you posted'**
  String get vendorAgentsStep3;

  /// No description provided for @addFirstVendor.
  ///
  /// In en, this message translates to:
  /// **'Add your first vendor'**
  String get addFirstVendor;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @editVendorAgent.
  ///
  /// In en, this message translates to:
  /// **'Edit vendor agent'**
  String get editVendorAgent;

  /// No description provided for @deleteVendorTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete vendor agent?'**
  String get deleteVendorTitle;

  /// No description provided for @deleteVendorConfirm.
  ///
  /// In en, this message translates to:
  /// **'The agent for {name} will be removed and will no longer contact this vendor. Existing tickets are kept.'**
  String deleteVendorConfirm(String name);

  /// No description provided for @vendorDeleted.
  ///
  /// In en, this message translates to:
  /// **'Vendor agent deleted'**
  String get vendorDeleted;

  /// No description provided for @inviteViaLink.
  ///
  /// In en, this message translates to:
  /// **'Invite residents via link'**
  String get inviteViaLink;

  /// No description provided for @inviteResidents.
  ///
  /// In en, this message translates to:
  /// **'Invite residents'**
  String get inviteResidents;

  /// No description provided for @inviteLinkExplain.
  ///
  /// In en, this message translates to:
  /// **'Anyone who opens this link can ask to join the building — you approve them here.'**
  String get inviteLinkExplain;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @invitePending.
  ///
  /// In en, this message translates to:
  /// **'Invited · waiting to connect'**
  String get invitePending;

  /// No description provided for @findBuildingHint.
  ///
  /// In en, this message translates to:
  /// **'Search by city and address — pick from the suggestions so we find an exact match.'**
  String get findBuildingHint;

  /// No description provided for @pickCityFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a city first'**
  String get pickCityFirst;

  /// No description provided for @askVaadInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your building? Ask your Vaad to send you a personal invite or the building\'s join link.'**
  String get askVaadInviteHint;

  /// No description provided for @tenantProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get tenantProfileTitle;

  /// No description provided for @tenantProfileHint.
  ///
  /// In en, this message translates to:
  /// **'These details are sent to the building\'s Vaad, who approves your request.'**
  String get tenantProfileHint;

  /// No description provided for @floorLabel.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floorLabel;

  /// No description provided for @numOccupantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Occupants'**
  String get numOccupantsLabel;

  /// No description provided for @parkingOptional.
  ///
  /// In en, this message translates to:
  /// **'Parking (optional)'**
  String get parkingOptional;

  /// No description provided for @attachDocOptional.
  ///
  /// In en, this message translates to:
  /// **'Attach a document (optional)'**
  String get attachDocOptional;

  /// No description provided for @sendJoinRequest.
  ///
  /// In en, this message translates to:
  /// **'Send join request'**
  String get sendJoinRequest;

  /// No description provided for @occupantsN.
  ///
  /// In en, this message translates to:
  /// **'{n} occupants'**
  String occupantsN(String n);

  /// No description provided for @viewAttachedDoc.
  ///
  /// In en, this message translates to:
  /// **'View attached document'**
  String get viewAttachedDoc;

  /// No description provided for @docsSection.
  ///
  /// In en, this message translates to:
  /// **'Recommended documents'**
  String get docsSection;

  /// No description provided for @docsSectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Required documents'**
  String get docsSectionRequired;

  /// No description provided for @docsExplain.
  ///
  /// In en, this message translates to:
  /// **'The Arnona bill shows the apartment\'s size (sqm), which affects the Vaad fee. The agreement confirms you live in this apartment.'**
  String get docsExplain;

  /// No description provided for @attachArnona.
  ///
  /// In en, this message translates to:
  /// **'Arnona bill'**
  String get attachArnona;

  /// No description provided for @arnonaHint.
  ///
  /// In en, this message translates to:
  /// **'Shows the apartment size in sqm'**
  String get arnonaHint;

  /// No description provided for @attachResidence.
  ///
  /// In en, this message translates to:
  /// **'Proof of residence'**
  String get attachResidence;

  /// No description provided for @residenceHint.
  ///
  /// In en, this message translates to:
  /// **'Rent or purchase agreement'**
  String get residenceHint;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @requireDocsTitle.
  ///
  /// In en, this message translates to:
  /// **'Require documents to join'**
  String get requireDocsTitle;

  /// No description provided for @requireDocsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New residents must attach an Arnona bill and proof of residence'**
  String get requireDocsSubtitle;

  /// No description provided for @joinRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Join request awaiting approval'**
  String get joinRequestPending;

  /// No description provided for @financesTitle.
  ///
  /// In en, this message translates to:
  /// **'Finances'**
  String get financesTitle;

  /// No description provided for @expensesTab.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTab;

  /// No description provided for @collectionSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} apartments · {pct}% collected · {amount} debt'**
  String collectionSummary(String count, String pct, String amount);

  /// No description provided for @allApartments.
  ///
  /// In en, this message translates to:
  /// **'All apartments'**
  String get allApartments;

  /// No description provided for @onlyWithDebt.
  ///
  /// In en, this message translates to:
  /// **'With debt only'**
  String get onlyWithDebt;

  /// No description provided for @collapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get collapseAll;

  /// No description provided for @apartmentColumn.
  ///
  /// In en, this message translates to:
  /// **'Apt'**
  String get apartmentColumn;

  /// No description provided for @debtColumn.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debtColumn;

  /// No description provided for @aptTiny.
  ///
  /// In en, this message translates to:
  /// **'Apt {n}'**
  String aptTiny(String n);

  /// No description provided for @debtAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} debt'**
  String debtAmount(String amount);

  /// No description provided for @noDebt.
  ///
  /// In en, this message translates to:
  /// **'No debt'**
  String get noDebt;

  /// No description provided for @markFloorPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark floor as paid'**
  String get markFloorPaid;

  /// No description provided for @residentsSection.
  ///
  /// In en, this message translates to:
  /// **'Residents'**
  String get residentsSection;

  /// No description provided for @occupiedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{occupied}/{total} occupied'**
  String occupiedOfTotal(String occupied, String total);

  /// No description provided for @searchResidents.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone or apartment'**
  String get searchResidents;

  /// No description provided for @pendingInvitesSection.
  ///
  /// In en, this message translates to:
  /// **'Pending invitations'**
  String get pendingInvitesSection;

  /// No description provided for @noDocsForApartment.
  ///
  /// In en, this message translates to:
  /// **'No documents attached'**
  String get noDocsForApartment;

  /// No description provided for @sqmShort.
  ///
  /// In en, this message translates to:
  /// **'{n} sqm'**
  String sqmShort(String n);

  /// No description provided for @currentPeriod.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentPeriod;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Not paid'**
  String get statusUnpaid;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @noApartmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No apartments defined yet'**
  String get noApartmentsYet;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded yet'**
  String get noExpensesYet;

  /// No description provided for @providerOptional.
  ///
  /// In en, this message translates to:
  /// **'Provider (optional)'**
  String get providerOptional;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @attachReceipt.
  ///
  /// In en, this message translates to:
  /// **'Attach a receipt (optional)'**
  String get attachReceipt;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get viewReceipt;

  /// No description provided for @expenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense recorded'**
  String get expenseSaved;

  /// No description provided for @joinApprovedSnack.
  ///
  /// In en, this message translates to:
  /// **'{name} was approved and joined the building'**
  String joinApprovedSnack(String name);

  /// No description provided for @joinRejectedSnack.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s request was rejected'**
  String joinRejectedSnack(String name);

  /// No description provided for @viewArnonaDoc.
  ///
  /// In en, this message translates to:
  /// **'View Arnona bill'**
  String get viewArnonaDoc;

  /// No description provided for @viewResidenceDoc.
  ///
  /// In en, this message translates to:
  /// **'View proof of residence'**
  String get viewResidenceDoc;

  /// No description provided for @myBuilding.
  ///
  /// In en, this message translates to:
  /// **'My building'**
  String get myBuilding;

  /// No description provided for @trialNotice.
  ///
  /// In en, this message translates to:
  /// **'14-day free trial: full access for the whole building. Afterwards it\'s just ₪4.90 per apartment per month — contact us to subscribe.'**
  String get trialNotice;

  /// No description provided for @trialEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'The free trial has ended'**
  String get trialEndedTitle;

  /// No description provided for @trialEndedBody.
  ///
  /// In en, this message translates to:
  /// **'Your building\'s 14-day trial is over. All your data is safe and waiting for you.'**
  String get trialEndedBody;

  /// No description provided for @accessBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access is suspended'**
  String get accessBlockedTitle;

  /// No description provided for @accessBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Access for this building has been suspended. Contact us to restore it — all data is kept.'**
  String get accessBlockedBody;

  /// No description provided for @pricingLine.
  ///
  /// In en, this message translates to:
  /// **'₪4.90 per apartment / month'**
  String get pricingLine;

  /// No description provided for @likeItContactUs.
  ///
  /// In en, this message translates to:
  /// **'Like Buildingo? Contact us and we\'ll activate your building\'s subscription — no in-app payment needed.'**
  String get likeItContactUs;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @contactFormHint.
  ///
  /// In en, this message translates to:
  /// **'Leave your details and we\'ll get back to you shortly.'**
  String get contactFormHint;

  /// No description provided for @contactMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contactMessage;

  /// No description provided for @contactSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get contactSend;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhone;

  /// No description provided for @contactSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Message sent!'**
  String get contactSentTitle;

  /// No description provided for @contactSentBody.
  ///
  /// In en, this message translates to:
  /// **'Thanks! We received your message and will get back to you soon.'**
  String get contactSentBody;

  /// No description provided for @transferHolder.
  ///
  /// In en, this message translates to:
  /// **'Replace holder'**
  String get transferHolder;

  /// No description provided for @holdersHistory.
  ///
  /// In en, this message translates to:
  /// **'Holders history'**
  String get holdersHistory;

  /// No description provided for @currentHolder.
  ///
  /// In en, this message translates to:
  /// **'Current holder'**
  String get currentHolder;

  /// No description provided for @pendingHolder.
  ///
  /// In en, this message translates to:
  /// **'Awaiting details'**
  String get pendingHolder;

  /// No description provided for @holderOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get holderOwner;

  /// No description provided for @holderRenter.
  ///
  /// In en, this message translates to:
  /// **'Renter'**
  String get holderRenter;

  /// No description provided for @noPreviousHolders.
  ///
  /// In en, this message translates to:
  /// **'No previous holders'**
  String get noPreviousHolders;

  /// No description provided for @previousHoldersN.
  ///
  /// In en, this message translates to:
  /// **'{n} previous holders'**
  String previousHoldersN(String n);

  /// No description provided for @periodSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String periodSince(String date);

  /// No description provided for @newHolderFallback.
  ///
  /// In en, this message translates to:
  /// **'New holder'**
  String get newHolderFallback;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'no phone'**
  String get noPhone;

  /// No description provided for @apartmentCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Apartment {n} card'**
  String apartmentCardTitle(String n);

  /// No description provided for @stepEndTenancy.
  ///
  /// In en, this message translates to:
  /// **'End tenancy'**
  String get stepEndTenancy;

  /// No description provided for @stepIncomingHolder.
  ///
  /// In en, this message translates to:
  /// **'Incoming holder'**
  String get stepIncomingHolder;

  /// No description provided for @stepConfirmTransfer.
  ///
  /// In en, this message translates to:
  /// **'Confirm & transfer'**
  String get stepConfirmTransfer;

  /// No description provided for @endTenancyTitle.
  ///
  /// In en, this message translates to:
  /// **'End tenancy — {name}'**
  String endTenancyTitle(String name);

  /// No description provided for @endTenancyBody.
  ///
  /// In en, this message translates to:
  /// **'The apartment card is fully preserved. The outgoing holder is archived with their period, and the history stays attached to the apartment.'**
  String get endTenancyBody;

  /// No description provided for @endDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective end date'**
  String get endDateLabel;

  /// No description provided for @debtQuestion.
  ///
  /// In en, this message translates to:
  /// **'What happens to open dues'**
  String get debtQuestion;

  /// No description provided for @debtKeepTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt stays with the outgoing renter'**
  String get debtKeepTitle;

  /// No description provided for @debtKeepBody.
  ///
  /// In en, this message translates to:
  /// **'Open dues remain in their name and stay in collection tracking'**
  String get debtKeepBody;

  /// No description provided for @debtOwnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt is transferred to the owner'**
  String get debtOwnerTitle;

  /// No description provided for @debtOwnerBody.
  ///
  /// In en, this message translates to:
  /// **'The Vaad will collect from the owner per the contract clause'**
  String get debtOwnerBody;

  /// No description provided for @debtCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close the debt'**
  String get debtCloseTitle;

  /// No description provided for @debtCloseBody.
  ///
  /// In en, this message translates to:
  /// **'The debt is cleared by Vaad decision — recorded in the building log'**
  String get debtCloseBody;

  /// No description provided for @incomingDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'The details will be attached to apartment {n} from {date}.'**
  String incomingDetailsBody(String n, String date);

  /// No description provided for @modeSelfTitle.
  ///
  /// In en, this message translates to:
  /// **'The holder fills in their own details'**
  String get modeSelfTitle;

  /// No description provided for @modeSelfBody.
  ///
  /// In en, this message translates to:
  /// **'We send a link by SMS. They verify their phone and fill in name, occupants and contract — the apartment is marked \"awaiting details\" until then.'**
  String get modeSelfBody;

  /// No description provided for @modeVaadTitle.
  ///
  /// In en, this message translates to:
  /// **'Filled in by the Vaad'**
  String get modeVaadTitle;

  /// No description provided for @modeVaadBody.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details here and now. A link can still be sent later.'**
  String get modeVaadBody;

  /// No description provided for @optionalField.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalField;

  /// No description provided for @mobilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile phone'**
  String get mobilePhoneLabel;

  /// No description provided for @holderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Holding type'**
  String get holderTypeLabel;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Tenancy start date'**
  String get startDateLabel;

  /// No description provided for @sendSmsOnTransfer.
  ///
  /// In en, this message translates to:
  /// **'Send the link by SMS as soon as the transfer is confirmed'**
  String get sendSmsOnTransfer;

  /// No description provided for @linkExplainTitle.
  ///
  /// In en, this message translates to:
  /// **'What the holder completes'**
  String get linkExplainTitle;

  /// No description provided for @linkStepOtp.
  ///
  /// In en, this message translates to:
  /// **'Phone verification with an SMS code'**
  String get linkStepOtp;

  /// No description provided for @linkStepProfile.
  ///
  /// In en, this message translates to:
  /// **'Full name and number of occupants'**
  String get linkStepProfile;

  /// No description provided for @linkStepContract.
  ///
  /// In en, this message translates to:
  /// **'Uploading a rental contract · not mandatory'**
  String get linkStepContract;

  /// No description provided for @linkStepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirming parking and contact details'**
  String get linkStepConfirm;

  /// No description provided for @selfCompleteNote.
  ///
  /// In en, this message translates to:
  /// **'The holder will complete their details via the link'**
  String get selfCompleteNote;

  /// No description provided for @keptOnCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Kept on the apartment card'**
  String get keptOnCardTitle;

  /// No description provided for @keptOnCardBody.
  ///
  /// In en, this message translates to:
  /// **'Payment history, maintenance tickets, the apartment\'s receipts and assembly protocols'**
  String get keptOnCardBody;

  /// No description provided for @movesToNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Moves to the new holder'**
  String get movesToNewTitle;

  /// No description provided for @movesToNewBody.
  ///
  /// In en, this message translates to:
  /// **'Dues from the effective date, access to the building board, the residents book and votes'**
  String get movesToNewBody;

  /// No description provided for @staysWithOutgoingTitle.
  ///
  /// In en, this message translates to:
  /// **'Stays with the outgoing holder'**
  String get staysWithOutgoingTitle;

  /// No description provided for @staysWithOutgoingBody.
  ///
  /// In en, this message translates to:
  /// **'Their rental contract and personal documents · app access is blocked on the effective date'**
  String get staysWithOutgoingBody;

  /// No description provided for @transferLogNote.
  ///
  /// In en, this message translates to:
  /// **'The transfer is recorded in the building log with the approver\'s name and the date. All previous holders can be viewed on the apartment card.'**
  String get transferLogNote;

  /// No description provided for @confirmAndTransfer.
  ///
  /// In en, this message translates to:
  /// **'Confirm & transfer'**
  String get confirmAndTransfer;

  /// No description provided for @backBtn.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backBtn;

  /// No description provided for @transferDone.
  ///
  /// In en, this message translates to:
  /// **'The holder was replaced successfully'**
  String get transferDone;

  /// No description provided for @auditTenantTransferred.
  ///
  /// In en, this message translates to:
  /// **'Holder replaced'**
  String get auditTenantTransferred;

  /// No description provided for @pollOptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Answer options'**
  String get pollOptionsLabel;

  /// No description provided for @optionHint.
  ///
  /// In en, this message translates to:
  /// **'Option {n}'**
  String optionHint(String n);

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get addOption;

  /// No description provided for @allowMultipleAnswers.
  ///
  /// In en, this message translates to:
  /// **'Allow multiple answers'**
  String get allowMultipleAnswers;

  /// No description provided for @multiChoiceChip.
  ///
  /// In en, this message translates to:
  /// **'Multiple answers'**
  String get multiChoiceChip;

  /// No description provided for @optionsCount.
  ///
  /// In en, this message translates to:
  /// **'{n} options'**
  String optionsCount(String n);

  /// No description provided for @submitVote.
  ///
  /// In en, this message translates to:
  /// **'Submit vote'**
  String get submitVote;

  /// No description provided for @allSettled.
  ///
  /// In en, this message translates to:
  /// **'All settled'**
  String get allSettled;

  /// No description provided for @monthsPaidOfYear.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} months paid · {year}'**
  String monthsPaidOfYear(String paid, String total, String year);

  /// No description provided for @noChargesForYear.
  ///
  /// In en, this message translates to:
  /// **'No charges for this year'**
  String get noChargesForYear;

  /// No description provided for @paidOnDate.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String paidOnDate(String date);

  /// No description provided for @receiptShort.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptShort;

  /// No description provided for @receiptAttached.
  ///
  /// In en, this message translates to:
  /// **'Receipt attached'**
  String get receiptAttached;

  /// No description provided for @attachReceiptOnlyPaid.
  ///
  /// In en, this message translates to:
  /// **'A receipt can only be attached to a paid month'**
  String get attachReceiptOnlyPaid;

  /// No description provided for @attachReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press a paid month to attach a receipt'**
  String get attachReceiptHint;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get fromGallery;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Browse files'**
  String get chooseFile;

  /// No description provided for @locOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get locOther;

  /// No description provided for @locOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Where exactly?'**
  String get locOtherHint;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get uploadDocument;

  /// No description provided for @documentsUploaded.
  ///
  /// In en, this message translates to:
  /// **'Documents uploaded'**
  String get documentsUploaded;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add file (camera / gallery)'**
  String get addAttachment;

  /// No description provided for @addMoreFiles.
  ///
  /// In en, this message translates to:
  /// **'Add more files'**
  String get addMoreFiles;

  /// No description provided for @uploadNFiles.
  ///
  /// In en, this message translates to:
  /// **'Upload {n} files'**
  String uploadNFiles(String n);

  /// No description provided for @allYear.
  ///
  /// In en, this message translates to:
  /// **'Whole year'**
  String get allYear;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
