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
