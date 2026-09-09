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

  /// No description provided for @enterWhatsAppCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the WhatsApp code we sent to {phone}'**
  String enterWhatsAppCodeSentTo(String phone);

  /// No description provided for @sendCodeViaWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Send code via WhatsApp'**
  String get sendCodeViaWhatsApp;

  /// No description provided for @sendViaSmsInstead.
  ///
  /// In en, this message translates to:
  /// **'Send via SMS instead'**
  String get sendViaSmsInstead;

  /// No description provided for @sendViaWhatsAppInstead.
  ///
  /// In en, this message translates to:
  /// **'Send via WhatsApp instead'**
  String get sendViaWhatsAppInstead;

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

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your building, together'**
  String get splashTagline;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting things ready…'**
  String get splashLoading;

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

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @authErrorSmsSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the verification code. Please try again in a moment.'**
  String get authErrorSmsSendFailed;

  /// No description provided for @authErrorWhatsAppSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the WhatsApp code. Please try again, or use SMS instead.'**
  String get authErrorWhatsAppSendFailed;

  /// No description provided for @authErrorSmsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'SMS to this number isn\'t available right now (carrier or rate limit). Wait a few minutes, try another Israeli number, or try again later.'**
  String get authErrorSmsUnavailable;

  /// No description provided for @authErrorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'That phone number doesn\'t look right. Check the country code and try again.'**
  String get authErrorInvalidPhone;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes and try again.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t valid. Please check it and try again.'**
  String get authErrorInvalidCode;

  /// No description provided for @authErrorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'This code expired. Request a new one.'**
  String get authErrorSessionExpired;

  /// No description provided for @authErrorNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Phone sign-in is temporarily unavailable. Please try again later.'**
  String get authErrorNotEnabled;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsSection;

  /// No description provided for @settingsNotificationsNote.
  ///
  /// In en, this message translates to:
  /// **'Choose which building updates you want as push alerts. iOS will ask for permission the first time you enable notifications.'**
  String get settingsNotificationsNote;

  /// No description provided for @pushPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay updated on your building'**
  String get pushPermissionTitle;

  /// No description provided for @pushPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Buildingo can send notifications about tickets, announcements, and payments. You can change this anytime in Settings.'**
  String get pushPermissionBody;

  /// No description provided for @pushPermissionAllow.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get pushPermissionAllow;

  /// No description provided for @pushPermissionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get pushPermissionNotNow;

  /// No description provided for @settingsNotifyTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets & maintenance'**
  String get settingsNotifyTickets;

  /// No description provided for @settingsNotifyTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'New tickets and status updates'**
  String get settingsNotifyTicketsHint;

  /// No description provided for @settingsNotifyAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Board announcements'**
  String get settingsNotifyAnnouncements;

  /// No description provided for @settingsNotifyAnnouncementsHint.
  ///
  /// In en, this message translates to:
  /// **'Messages from the committee'**
  String get settingsNotifyAnnouncementsHint;

  /// No description provided for @settingsNotifyPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments & fees'**
  String get settingsNotifyPayments;

  /// No description provided for @settingsNotifyPaymentsHint.
  ///
  /// In en, this message translates to:
  /// **'Dues reminders and payment updates'**
  String get settingsNotifyPaymentsHint;

  /// No description provided for @settingsNotifyMessages.
  ///
  /// In en, this message translates to:
  /// **'Building messages'**
  String get settingsNotifyMessages;

  /// No description provided for @settingsNotifyMessagesHint.
  ///
  /// In en, this message translates to:
  /// **'General building chat and alerts'**
  String get settingsNotifyMessagesHint;

  /// No description provided for @settingsPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacySection;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Buildingo is built for your building community. We collect only what is needed to run the building — not ads, not selling personal data.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsPrivacyBullets.
  ///
  /// In en, this message translates to:
  /// **'• Phone number — to sign in and reach you as a resident\n• Name and optional email — shown to your building directory\n• Apartment details and documents you upload (e.g. Arnona) — for fees and Vaad review\n• Location — only if you choose “use current location” when setting an address\n• Sensitive fields are encrypted at rest on our servers'**
  String get settingsPrivacyBullets;

  /// No description provided for @settingsPrivacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'Open privacy policy'**
  String get settingsPrivacyPolicyLink;

  /// No description provided for @settingsAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSection;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Your account will be permanently deleted and you will not be able to restore it. Your profile data will be removed from the app.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountConfirmAction;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account. Please try again.'**
  String get deleteAccountFailed;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get deletingAccount;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @leftToCollect.
  ///
  /// In en, this message translates to:
  /// **'Left to collect'**
  String get leftToCollect;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileUpdated;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

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

  /// No description provided for @navAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get navAgents;

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
  /// **'Service calls'**
  String get myTickets;

  /// No description provided for @noOpenTickets.
  ///
  /// In en, this message translates to:
  /// **'No open tickets — all quiet in the building.'**
  String get noOpenTickets;

  /// No description provided for @homeTicketsClearTitle.
  ///
  /// In en, this message translates to:
  /// **'All quiet'**
  String get homeTicketsClearTitle;

  /// No description provided for @homeTicketsClearBody.
  ///
  /// In en, this message translates to:
  /// **'No open service calls right now. Anything new will show up here.'**
  String get homeTicketsClearBody;

  /// No description provided for @noTicketsYet.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get noTicketsYet;

  /// No description provided for @noTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + below to report a fault in the building.'**
  String get noTicketsHint;

  /// No description provided for @communityBoard.
  ///
  /// In en, this message translates to:
  /// **'Building board'**
  String get communityBoard;

  /// No description provided for @seeDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get seeDetails;

  /// No description provided for @viewAllCalls.
  ///
  /// In en, this message translates to:
  /// **'All service calls'**
  String get viewAllCalls;

  /// No description provided for @viewAllBoardMessages.
  ///
  /// In en, this message translates to:
  /// **'All messages'**
  String get viewAllBoardMessages;

  /// No description provided for @allBoardMessages.
  ///
  /// In en, this message translates to:
  /// **'All board messages'**
  String get allBoardMessages;

  /// No description provided for @boardPublishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published {date}'**
  String boardPublishedOn(String date);

  /// No description provided for @noCurrentBoardMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages for this week'**
  String get noCurrentBoardMessages;

  /// No description provided for @paymentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All payments, clear and organized.'**
  String get paymentsSubtitle;

  /// No description provided for @buildingBalance.
  ///
  /// In en, this message translates to:
  /// **'Building balance'**
  String get buildingBalance;

  /// No description provided for @balanceAsOf.
  ///
  /// In en, this message translates to:
  /// **'As of {date}'**
  String balanceAsOf(String date);

  /// No description provided for @buildingIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get buildingIncome;

  /// No description provided for @buildingExpensesTotal.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get buildingExpensesTotal;

  /// No description provided for @monthlyCommitteeFees.
  ///
  /// In en, this message translates to:
  /// **'Monthly committee fees'**
  String get monthlyCommitteeFees;

  /// No description provided for @paymentsAutoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Payments update automatically'**
  String get paymentsAutoUpdated;

  /// No description provided for @residentsDirectory.
  ///
  /// In en, this message translates to:
  /// **'Residents directory'**
  String get residentsDirectory;

  /// No description provided for @apartmentsCountN.
  ///
  /// In en, this message translates to:
  /// **'{n} apartments'**
  String apartmentsCountN(String n);

  /// No description provided for @vaadTools.
  ///
  /// In en, this message translates to:
  /// **'Committee tools'**
  String get vaadTools;

  /// No description provided for @toolGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get toolGuests;

  /// No description provided for @toolSurveys.
  ///
  /// In en, this message translates to:
  /// **'Surveys'**
  String get toolSurveys;

  /// No description provided for @toolMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get toolMessage;

  /// No description provided for @ticketCatLeak.
  ///
  /// In en, this message translates to:
  /// **'Leak'**
  String get ticketCatLeak;

  /// No description provided for @ticketCatElevator.
  ///
  /// In en, this message translates to:
  /// **'Elevator'**
  String get ticketCatElevator;

  /// No description provided for @ticketCatCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get ticketCatCleaning;

  /// No description provided for @ticketCatLights.
  ///
  /// In en, this message translates to:
  /// **'Lights'**
  String get ticketCatLights;

  /// No description provided for @ticketCatElectric.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get ticketCatElectric;

  /// No description provided for @ticketCatDoor.
  ///
  /// In en, this message translates to:
  /// **'Door / intercom'**
  String get ticketCatDoor;

  /// No description provided for @ticketCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get ticketCatOther;

  /// No description provided for @ticketCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'What kind of fault?'**
  String get ticketCategoryLabel;

  /// No description provided for @ticketCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Created on {date}'**
  String ticketCreatedOn(String date);

  /// No description provided for @ticketUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get ticketUploadingPhoto;

  /// No description provided for @ticketCreating.
  ///
  /// In en, this message translates to:
  /// **'Sending report…'**
  String get ticketCreating;

  /// No description provided for @ticketCreateDone.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get ticketCreateDone;

  /// No description provided for @ticketCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t send report'**
  String get ticketCreateFailed;

  /// No description provided for @ticketRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ticketRetry;

  /// No description provided for @ticketDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get ticketDismiss;

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
  /// **'Faults & Repairs'**
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
  /// **'New'**
  String get statusOpen;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusApproved;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusResolved;

  /// No description provided for @approveAndDispatch.
  ///
  /// In en, this message translates to:
  /// **'Approve & Dispatch Agent'**
  String get approveAndDispatch;

  /// No description provided for @markResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark Done'**
  String get markResolved;

  /// No description provided for @ticketTapStatusHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a stage to update status'**
  String get ticketTapStatusHint;

  /// No description provided for @ticketRepairCost.
  ///
  /// In en, this message translates to:
  /// **'Repair cost'**
  String get ticketRepairCost;

  /// No description provided for @ticketRepairCostHint.
  ///
  /// In en, this message translates to:
  /// **'How much did this fix cost?'**
  String get ticketRepairCostHint;

  /// No description provided for @ticketAddRepairCost.
  ///
  /// In en, this message translates to:
  /// **'Add repair cost'**
  String get ticketAddRepairCost;

  /// No description provided for @ticketEditRepairCost.
  ///
  /// In en, this message translates to:
  /// **'Update cost & receipt'**
  String get ticketEditRepairCost;

  /// No description provided for @ticketCostSaved.
  ///
  /// In en, this message translates to:
  /// **'Repair cost saved'**
  String get ticketCostSaved;

  /// No description provided for @ticketCostAmount.
  ///
  /// In en, this message translates to:
  /// **'₪{amount}'**
  String ticketCostAmount(String amount);

  /// No description provided for @ticketEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit ticket'**
  String get ticketEdit;

  /// No description provided for @ticketEdited.
  ///
  /// In en, this message translates to:
  /// **'Ticket updated'**
  String get ticketEdited;

  /// No description provided for @deleteTicket.
  ///
  /// In en, this message translates to:
  /// **'Delete ticket'**
  String get deleteTicket;

  /// No description provided for @deleteTicketConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this ticket permanently? This cannot be undone.'**
  String get deleteTicketConfirm;

  /// No description provided for @ticketDeleted.
  ///
  /// In en, this message translates to:
  /// **'Ticket deleted'**
  String get ticketDeleted;

  /// No description provided for @auditTicketDeleted.
  ///
  /// In en, this message translates to:
  /// **'Ticket deleted'**
  String get auditTicketDeleted;

  /// No description provided for @editScheduleEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit schedule event'**
  String get editScheduleEvent;

  /// No description provided for @editMeeting.
  ///
  /// In en, this message translates to:
  /// **'Edit assembly'**
  String get editMeeting;

  /// No description provided for @deleteScheduleEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete from schedule'**
  String get deleteScheduleEvent;

  /// No description provided for @deleteScheduleEventConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this item from the building schedule?'**
  String get deleteScheduleEventConfirm;

  /// No description provided for @scheduleEventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated'**
  String get scheduleEventUpdated;

  /// No description provided for @scheduleEventDeleted.
  ///
  /// In en, this message translates to:
  /// **'Removed from schedule'**
  String get scheduleEventDeleted;

  /// No description provided for @auditMeetingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Assembly updated'**
  String get auditMeetingUpdated;

  /// No description provided for @auditMeetingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Assembly deleted'**
  String get auditMeetingDeleted;

  /// No description provided for @ticketUpdateProgress.
  ///
  /// In en, this message translates to:
  /// **'Update progress'**
  String get ticketUpdateProgress;

  /// No description provided for @ticketProgressSaved.
  ///
  /// In en, this message translates to:
  /// **'Progress updated'**
  String get ticketProgressSaved;

  /// No description provided for @ticketProgressNote.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening?'**
  String get ticketProgressNote;

  /// No description provided for @ticketProgressNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Opened with provider, parts ordered…'**
  String get ticketProgressNoteHint;

  /// No description provided for @ticketFixDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected fix date'**
  String get ticketFixDateLabel;

  /// No description provided for @ticketFixDate.
  ///
  /// In en, this message translates to:
  /// **'Fix date: {date}'**
  String ticketFixDate(String date);

  /// No description provided for @ticketExpectedBy.
  ///
  /// In en, this message translates to:
  /// **'Expected {date}'**
  String ticketExpectedBy(String date);

  /// No description provided for @ticketProgressOpenedProvider.
  ///
  /// In en, this message translates to:
  /// **'Opened with provider'**
  String get ticketProgressOpenedProvider;

  /// No description provided for @ticketProgressPartsOrdered.
  ///
  /// In en, this message translates to:
  /// **'Parts ordered'**
  String get ticketProgressPartsOrdered;

  /// No description provided for @ticketProgressScheduled.
  ///
  /// In en, this message translates to:
  /// **'Fix scheduled'**
  String get ticketProgressScheduled;

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
  /// **'Details (optional)'**
  String get details;

  /// No description provided for @detailsHint.
  ///
  /// In en, this message translates to:
  /// **'When did it start? Where exactly?'**
  String get detailsHint;

  /// No description provided for @addMorePhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addMorePhotos;

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
  /// **'Residents directory'**
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

  /// No description provided for @directoryResidentSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String directoryResidentSince(String date);

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

  /// No description provided for @announcementCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Message type'**
  String get announcementCategoryLabel;

  /// No description provided for @boardCatUpdate.
  ///
  /// In en, this message translates to:
  /// **'Important update'**
  String get boardCatUpdate;

  /// No description provided for @boardCatMeeting.
  ///
  /// In en, this message translates to:
  /// **'Residents meeting'**
  String get boardCatMeeting;

  /// No description provided for @boardCatMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get boardCatMaintenance;

  /// No description provided for @boardCatTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get boardCatTip;

  /// No description provided for @boardCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get boardCatOther;

  /// No description provided for @boardActionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get boardActionDetails;

  /// No description provided for @boardActionRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get boardActionRead;

  /// No description provided for @boardActionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get boardActionView;

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

  /// No description provided for @editBoardMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit board message'**
  String get editBoardMessage;

  /// No description provided for @deleteBoardMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteBoardMessage;

  /// No description provided for @deleteBoardMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this message from the building board? Residents will no longer see it.'**
  String get deleteBoardMessageConfirm;

  /// No description provided for @announcementUpdated.
  ///
  /// In en, this message translates to:
  /// **'Message updated'**
  String get announcementUpdated;

  /// No description provided for @announcementDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get announcementDeleted;

  /// No description provided for @auditAnnouncementUpdated.
  ///
  /// In en, this message translates to:
  /// **'Announcement updated'**
  String get auditAnnouncementUpdated;

  /// No description provided for @auditAnnouncementDeleted.
  ///
  /// In en, this message translates to:
  /// **'Announcement deleted'**
  String get auditAnnouncementDeleted;

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

  /// No description provided for @findZipCode.
  ///
  /// In en, this message translates to:
  /// **'Find postal code'**
  String get findZipCode;

  /// No description provided for @lookingUpZip.
  ///
  /// In en, this message translates to:
  /// **'Looking up postal code…'**
  String get lookingUpZip;

  /// No description provided for @zipLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t find a postal code for this address. You can enter it manually.'**
  String get zipLookupFailed;

  /// No description provided for @zipLookupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Postal-code lookup is unavailable right now (AI service). You can enter it manually.'**
  String get zipLookupUnavailable;

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

  /// No description provided for @numberOfApartments.
  ///
  /// In en, this message translates to:
  /// **'Number of apartments'**
  String get numberOfApartments;

  /// No description provided for @numberOfFloors.
  ///
  /// In en, this message translates to:
  /// **'Number of floors'**
  String get numberOfFloors;

  /// No description provided for @typicalFloorLabel.
  ///
  /// In en, this message translates to:
  /// **'On a typical floor'**
  String get typicalFloorLabel;

  /// No description provided for @baseFloorLabel.
  ///
  /// In en, this message translates to:
  /// **'First floor'**
  String get baseFloorLabel;

  /// No description provided for @firstApartmentShortLabel.
  ///
  /// In en, this message translates to:
  /// **'First apartment'**
  String get firstApartmentShortLabel;

  /// No description provided for @structureStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the typical floor, then fix only the exceptions.'**
  String get structureStepSubtitle;

  /// No description provided for @floorsRangeSummary.
  ///
  /// In en, this message translates to:
  /// **'Floors will run from {from} to {to} · apartments numbered {aptFrom}–{aptTo}'**
  String floorsRangeSummary(
    String from,
    String to,
    String aptFrom,
    String aptTo,
  );

  /// No description provided for @floorDivisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Floor breakdown'**
  String get floorDivisionTitle;

  /// No description provided for @resetExceptions.
  ///
  /// In en, this message translates to:
  /// **'Reset {count} exceptions'**
  String resetExceptions(String count);

  /// No description provided for @floorBadge.
  ///
  /// In en, this message translates to:
  /// **'fl.{floor}'**
  String floorBadge(String floor);

  /// No description provided for @floorBadgeGround.
  ///
  /// In en, this message translates to:
  /// **'G'**
  String get floorBadgeGround;

  /// No description provided for @floorAptsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} apartments'**
  String floorAptsCount(String count);

  /// No description provided for @floorAptsRange.
  ///
  /// In en, this message translates to:
  /// **'Apts {from}–{to}'**
  String floorAptsRange(String from, String to);

  /// No description provided for @exceptionBadge.
  ///
  /// In en, this message translates to:
  /// **'Exception'**
  String get exceptionBadge;

  /// No description provided for @mappingTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total in mapping'**
  String get mappingTotalLabel;

  /// No description provided for @mappingTotalMeta.
  ///
  /// In en, this message translates to:
  /// **'{apts} apartments · {floors} floors'**
  String mappingTotalMeta(String apts, String floors);

  /// No description provided for @floorPlanMismatch.
  ///
  /// In en, this message translates to:
  /// **'Floor counts must add up to the total apartments'**
  String get floorPlanMismatch;

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

  /// No description provided for @feeFixedMonthlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Apartment fee · monthly'**
  String get feeFixedMonthlyLabel;

  /// No description provided for @feePerApartmentUnit.
  ///
  /// In en, this message translates to:
  /// **'per apt'**
  String get feePerApartmentUnit;

  /// No description provided for @pricePerSqmLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per m² (₪)'**
  String get pricePerSqmLabel;

  /// No description provided for @updateVaadFee.
  ///
  /// In en, this message translates to:
  /// **'Vaad fee settings'**
  String get updateVaadFee;

  /// No description provided for @buildingSettings.
  ///
  /// In en, this message translates to:
  /// **'Building settings'**
  String get buildingSettings;

  /// No description provided for @joinPolicySection.
  ///
  /// In en, this message translates to:
  /// **'Join policy'**
  String get joinPolicySection;

  /// No description provided for @createBuildingStepYou.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get createBuildingStepYou;

  /// No description provided for @createBuildingStepPlace.
  ///
  /// In en, this message translates to:
  /// **'Building address'**
  String get createBuildingStepPlace;

  /// No description provided for @createBuildingStepEntrances.
  ///
  /// In en, this message translates to:
  /// **'Entrances & elevators'**
  String get createBuildingStepEntrances;

  /// No description provided for @createBuildingStepStructure.
  ///
  /// In en, this message translates to:
  /// **'Floors & apartments'**
  String get createBuildingStepStructure;

  /// No description provided for @createBuildingStepFees.
  ///
  /// In en, this message translates to:
  /// **'Committee fees'**
  String get createBuildingStepFees;

  /// No description provided for @createBuildingStepMyApartment.
  ///
  /// In en, this message translates to:
  /// **'Your apartment'**
  String get createBuildingStepMyApartment;

  /// No description provided for @createBuildingStepServices.
  ///
  /// In en, this message translates to:
  /// **'Regular services'**
  String get createBuildingStepServices;

  /// No description provided for @createBuildingStepBalance.
  ///
  /// In en, this message translates to:
  /// **'Bank balance'**
  String get createBuildingStepBalance;

  /// No description provided for @createBuildingStepSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary & confirm'**
  String get createBuildingStepSummary;

  /// No description provided for @createBuildingYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These details are shown to residents as the committee contact.'**
  String get createBuildingYouSubtitle;

  /// No description provided for @createBuildingYouAptLaterNote.
  ///
  /// In en, this message translates to:
  /// **'On the apartment step you’ll set your unit — number, occupants, and documents — like any resident.'**
  String get createBuildingYouAptLaterNote;

  /// No description provided for @createBuildingMyAptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your unit details. We’ll create the apartment and assign you to it as Vaad.'**
  String get createBuildingMyAptSubtitle;

  /// No description provided for @createBuildingPlaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One address for protocols, receipts, and invites.'**
  String get createBuildingPlaceSubtitle;

  /// No description provided for @createBuildingEntrancesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Entrance codes and elevators for your building.'**
  String get createBuildingEntrancesSubtitle;

  /// No description provided for @createBuildingFeesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set how monthly committee fees are calculated.'**
  String get createBuildingFeesSubtitle;

  /// No description provided for @createBuildingServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set recurring services for the building calendar. You can change these later.'**
  String get createBuildingServicesSubtitle;

  /// No description provided for @createBuildingSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review everything before creating the building.'**
  String get createBuildingSummarySubtitle;

  /// No description provided for @serviceCleaningStairs.
  ///
  /// In en, this message translates to:
  /// **'Stairwell cleaning'**
  String get serviceCleaningStairs;

  /// No description provided for @serviceGarbage.
  ///
  /// In en, this message translates to:
  /// **'Trash removal'**
  String get serviceGarbage;

  /// No description provided for @serviceGardening.
  ///
  /// In en, this message translates to:
  /// **'Gardening'**
  String get serviceGardening;

  /// No description provided for @servicePest.
  ///
  /// In en, this message translates to:
  /// **'Pest control'**
  String get servicePest;

  /// No description provided for @serviceWaterTank.
  ///
  /// In en, this message translates to:
  /// **'Water tank cleaning'**
  String get serviceWaterTank;

  /// No description provided for @serviceFrequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get serviceFrequencyWeekly;

  /// No description provided for @serviceFrequencyBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Biweekly'**
  String get serviceFrequencyBiweekly;

  /// No description provided for @serviceFrequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get serviceFrequencyMonthly;

  /// No description provided for @serviceFrequencyQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get serviceFrequencyQuarterly;

  /// No description provided for @serviceFrequencyYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get serviceFrequencyYearly;

  /// No description provided for @serviceCostHint.
  ///
  /// In en, this message translates to:
  /// **'₪ Cost'**
  String get serviceCostHint;

  /// No description provided for @serviceProviderHint.
  ///
  /// In en, this message translates to:
  /// **'Provider name'**
  String get serviceProviderHint;

  /// No description provided for @serviceAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add custom service'**
  String get serviceAddCustom;

  /// No description provided for @serviceCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Service name'**
  String get serviceCustomTitle;

  /// No description provided for @serviceSkipLater.
  ///
  /// In en, this message translates to:
  /// **'Skip — you can add later'**
  String get serviceSkipLater;

  /// No description provided for @serviceEstimatedMonthly.
  ///
  /// In en, this message translates to:
  /// **'Estimated monthly expense · ₪{amount}'**
  String serviceEstimatedMonthly(String amount);

  /// No description provided for @serviceBalanceAfterFees.
  ///
  /// In en, this message translates to:
  /// **'Remaining after collection · ₪{amount}'**
  String serviceBalanceAfterFees(String amount);

  /// No description provided for @serviceCalendarNote.
  ///
  /// In en, this message translates to:
  /// **'Enabled services appear on the building calendar with reminders for the committee.'**
  String get serviceCalendarNote;

  /// No description provided for @serviceDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get serviceDayOfMonth;

  /// No description provided for @serviceOffHint.
  ///
  /// In en, this message translates to:
  /// **'Off — tap to set schedule'**
  String get serviceOffHint;

  /// No description provided for @serviceDaySun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get serviceDaySun;

  /// No description provided for @serviceDayMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get serviceDayMon;

  /// No description provided for @serviceDayTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get serviceDayTue;

  /// No description provided for @serviceDayWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get serviceDayWed;

  /// No description provided for @serviceDayThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get serviceDayThu;

  /// No description provided for @serviceDayFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get serviceDayFri;

  /// No description provided for @serviceDaySat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get serviceDaySat;

  /// No description provided for @summaryServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Regular services'**
  String get summaryServicesTitle;

  /// No description provided for @summaryServicesNone.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get summaryServicesNone;

  /// No description provided for @verifiedPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified phone'**
  String get verifiedPhoneLabel;

  /// No description provided for @myApartmentNumber.
  ///
  /// In en, this message translates to:
  /// **'Apartment number'**
  String get myApartmentNumber;

  /// No description provided for @committeeApartmentNote.
  ///
  /// In en, this message translates to:
  /// **'This apartment will be marked as the committee apartment in the directory.'**
  String get committeeApartmentNote;

  /// No description provided for @vaadAptClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Your apartment'**
  String get vaadAptClaimTitle;

  /// No description provided for @vaadAptClaimSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your unit from the mapped apartments. We’ll create every unit in the building and assign you to this one as Vaad.'**
  String get vaadAptClaimSubtitle;

  /// No description provided for @vaadAptRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Numbers in this plan: {from}–{to}'**
  String vaadAptRangeHint(String from, String to);

  /// No description provided for @vaadAptOutOfPlan.
  ///
  /// In en, this message translates to:
  /// **'That apartment number is not in the floor plan you set'**
  String get vaadAptOutOfPlan;

  /// No description provided for @vaadAptSqmHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — building typical is {typical} m²'**
  String vaadAptSqmHint(String typical);

  /// No description provided for @countryIsrael.
  ///
  /// In en, this message translates to:
  /// **'Israel'**
  String get countryIsrael;

  /// No description provided for @countryUsa.
  ///
  /// In en, this message translates to:
  /// **'USA'**
  String get countryUsa;

  /// No description provided for @countryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get countryOther;

  /// No description provided for @districtOptional.
  ///
  /// In en, this message translates to:
  /// **'District / region (optional)'**
  String get districtOptional;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @locatingAddress.
  ///
  /// In en, this message translates to:
  /// **'Finding your address…'**
  String get locatingAddress;

  /// No description provided for @locationFilledHint.
  ///
  /// In en, this message translates to:
  /// **'Filled from your location — you can edit any field.'**
  String get locationFilledHint;

  /// No description provided for @locationOutsideIsrael.
  ///
  /// In en, this message translates to:
  /// **'Location isn’t in Israel. Country stays Israel — fill the address manually, or switch country.'**
  String get locationOutsideIsrael;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read your location. You can fill the address manually.'**
  String get locationUnavailable;

  /// No description provided for @addressAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'A building already exists at this exact address ({name}). You can’t create another one here — ask to join it instead.'**
  String addressAlreadyRegistered(String name);

  /// No description provided for @addressAlreadyRegisteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Address already taken'**
  String get addressAlreadyRegisteredTitle;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @entrancesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Entrances'**
  String get entrancesCountLabel;

  /// No description provided for @elevatorsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Elevators'**
  String get elevatorsCountLabel;

  /// No description provided for @entranceCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Entrance codes'**
  String get entranceCodesTitle;

  /// No description provided for @entranceCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Code (optional)'**
  String get entranceCodeHint;

  /// No description provided for @entranceCodesPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Entrance codes are visible only to residents of this building.'**
  String get entranceCodesPrivacyNote;

  /// No description provided for @typicalApartmentSqmLabel.
  ///
  /// In en, this message translates to:
  /// **'Typical apartment size (m²)'**
  String get typicalApartmentSqmLabel;

  /// No description provided for @feePreviewSize.
  ///
  /// In en, this message translates to:
  /// **'{sqm} m² apartment'**
  String feePreviewSize(String sqm);

  /// No description provided for @feePreviewTypical.
  ///
  /// In en, this message translates to:
  /// **'Typical · {sqm} m²'**
  String feePreviewTypical(String sqm);

  /// No description provided for @feeTemporaryNote.
  ///
  /// In en, this message translates to:
  /// **'Until each apartment has its size set, billing uses the typical size.'**
  String get feeTemporaryNote;

  /// No description provided for @billingDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing day of month'**
  String get billingDayLabel;

  /// No description provided for @billingDaySummary.
  ///
  /// In en, this message translates to:
  /// **'Billing day: {day}'**
  String billingDaySummary(String day);

  /// No description provided for @expectedMonthlyCollection.
  ///
  /// In en, this message translates to:
  /// **'Expected monthly collection'**
  String get expectedMonthlyCollection;

  /// No description provided for @sqmUnit.
  ///
  /// In en, this message translates to:
  /// **'m²'**
  String get sqmUnit;

  /// No description provided for @summaryContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get summaryContactTitle;

  /// No description provided for @summaryAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get summaryAddressTitle;

  /// No description provided for @summaryBuildingTitle.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get summaryBuildingTitle;

  /// No description provided for @summaryFloorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Floors'**
  String get summaryFloorsTitle;

  /// No description provided for @summaryFeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get summaryFeesTitle;

  /// No description provided for @summaryEntrancesLine.
  ///
  /// In en, this message translates to:
  /// **'{entrances} entrances · {elevators} elevators'**
  String summaryEntrancesLine(String entrances, String elevators);

  /// No description provided for @apartmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Apt {n}'**
  String apartmentLabel(String n);

  /// No description provided for @createBuildingNextWithApts.
  ///
  /// In en, this message translates to:
  /// **'Continue · {n} apartments'**
  String createBuildingNextWithApts(String n);

  /// No description provided for @openingBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Building cash balance'**
  String get openingBalanceTitle;

  /// No description provided for @openingBalanceBody.
  ///
  /// In en, this message translates to:
  /// **'How much money is currently in the building bank account or cash box? This is the starting balance in the app — paid dues add up, expenses subtract. You can leave 0 and update later.'**
  String get openingBalanceBody;

  /// No description provided for @openingBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current cash balance (₪)'**
  String get openingBalanceLabel;

  /// No description provided for @openingBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — leave empty for now.'**
  String get openingBalanceHint;

  /// No description provided for @openingBalanceSkip.
  ///
  /// In en, this message translates to:
  /// **'Start from zero'**
  String get openingBalanceSkip;

  /// No description provided for @openingBalanceRow.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalanceRow;

  /// No description provided for @createBuildingNext.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get createBuildingNext;

  /// No description provided for @createBuildingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get createBuildingBack;

  /// No description provided for @createBuildingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String createBuildingStepOf(String current, String total);

  /// No description provided for @comingSoonSection.
  ///
  /// In en, this message translates to:
  /// **'More configuration'**
  String get comingSoonSection;

  /// No description provided for @shareAppSection.
  ///
  /// In en, this message translates to:
  /// **'Share Buildingo'**
  String get shareAppSection;

  /// No description provided for @shareAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Share the app'**
  String get shareAppTitle;

  /// No description provided for @shareAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite other buildings via WhatsApp'**
  String get shareAppSubtitle;

  /// No description provided for @shareAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Hey! We run our building with Buildingo — dues, residents, and maintenance in one app. Download here: {link}'**
  String shareAppMessage(String link);

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get comingSoon;

  /// No description provided for @entranceCodesSoon.
  ///
  /// In en, this message translates to:
  /// **'Entrance codes (front / back)'**
  String get entranceCodesSoon;

  /// No description provided for @garbageScheduleSoon.
  ///
  /// In en, this message translates to:
  /// **'Garbage collection schedule'**
  String get garbageScheduleSoon;

  /// No description provided for @cleaningScheduleSoon.
  ///
  /// In en, this message translates to:
  /// **'Cleaning schedule'**
  String get cleaningScheduleSoon;

  /// No description provided for @saveFee.
  ///
  /// In en, this message translates to:
  /// **'Save & notify residents'**
  String get saveFee;

  /// No description provided for @vaadFeeSaved.
  ///
  /// In en, this message translates to:
  /// **'Fee updated — residents were notified'**
  String get vaadFeeSaved;

  /// No description provided for @apartmentSizeSqm.
  ///
  /// In en, this message translates to:
  /// **'Apartment size (m²)'**
  String get apartmentSizeSqm;

  /// No description provided for @apartmentSizeRequired.
  ///
  /// In en, this message translates to:
  /// **'Apartment size from Arnona bill is required'**
  String get apartmentSizeRequired;

  /// No description provided for @monthlyFeePreview.
  ///
  /// In en, this message translates to:
  /// **'Your monthly Vaad fee: {amount}'**
  String monthlyFeePreview(String amount);

  /// No description provided for @monthlyFeePreviewPerSqm.
  ///
  /// In en, this message translates to:
  /// **'{amount}/mo ({sqm} m² × {rate}/m², rounded up)'**
  String monthlyFeePreviewPerSqm(String amount, String sqm, String rate);

  /// No description provided for @existingApartmentSize.
  ///
  /// In en, this message translates to:
  /// **'Known apartment size: {sqm} m²'**
  String existingApartmentSize(String sqm);

  /// No description provided for @sqmExtracted.
  ///
  /// In en, this message translates to:
  /// **'Size read from your Arnona bill'**
  String get sqmExtracted;

  /// No description provided for @sqmEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Could not read size — enter it manually below'**
  String get sqmEnterManually;

  /// No description provided for @yourMonthlyVaadFee.
  ///
  /// In en, this message translates to:
  /// **'Monthly Vaad fee'**
  String get yourMonthlyVaadFee;

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

  /// No description provided for @collectionSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{unpaid} apartments unpaid · of {total} · {pct}% collected'**
  String collectionSummaryLine(String unpaid, String total, String pct);

  /// No description provided for @collectionStatSub.
  ///
  /// In en, this message translates to:
  /// **'{unpaid} of {total} · {pct}% collected'**
  String collectionStatSub(String unpaid, String total, String pct);

  /// No description provided for @collectedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Collected this month'**
  String get collectedThisMonth;

  /// No description provided for @remainingThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Still to collect'**
  String get remainingThisMonth;

  /// No description provided for @collectionHeroSub.
  ///
  /// In en, this message translates to:
  /// **'{collected} collected · {pct}%'**
  String collectionHeroSub(String collected, String pct);

  /// No description provided for @noTicketsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No new tickets this month'**
  String get noTicketsThisMonth;

  /// No description provided for @ticketsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{n} new this month'**
  String ticketsThisMonth(String n);

  /// No description provided for @ticketsSameAsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Same as last month'**
  String get ticketsSameAsLastMonth;

  /// No description provided for @ticketsUpVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'+{pct}% vs last month'**
  String ticketsUpVsLastMonth(String pct);

  /// No description provided for @ticketsDownVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'-{pct}% vs last month'**
  String ticketsDownVsLastMonth(String pct);

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

  /// No description provided for @buildingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Building schedule'**
  String get buildingSchedule;

  /// No description provided for @whatsappConnect.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappConnect;

  /// No description provided for @whatsappConnectBody.
  ///
  /// In en, this message translates to:
  /// **'Connect a WhatsApp number for this building, then link the residents group. Buildingo will listen for fault reports in that group and open tickets automatically. You can also message tenants over WhatsApp.'**
  String get whatsappConnectBody;

  /// No description provided for @whatsappNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp (WAHA) is not configured on the server yet.'**
  String get whatsappNotConfigured;

  /// No description provided for @whatsappConnected.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp connected'**
  String get whatsappConnected;

  /// No description provided for @whatsappNotConnected.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp not connected'**
  String get whatsappNotConnected;

  /// No description provided for @whatsappStartSession.
  ///
  /// In en, this message translates to:
  /// **'Start WhatsApp connection'**
  String get whatsappStartSession;

  /// No description provided for @whatsappScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR with WhatsApp → Linked devices'**
  String get whatsappScanQr;

  /// No description provided for @whatsappPickGroup.
  ///
  /// In en, this message translates to:
  /// **'Choose the building WhatsApp group'**
  String get whatsappPickGroup;

  /// No description provided for @whatsappGroupLinked.
  ///
  /// In en, this message translates to:
  /// **'Building group linked'**
  String get whatsappGroupLinked;

  /// No description provided for @whatsappLoadGroups.
  ///
  /// In en, this message translates to:
  /// **'Load groups'**
  String get whatsappLoadGroups;

  /// No description provided for @comingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get comingUp;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Full schedule'**
  String get viewCalendar;

  /// No description provided for @scheduleGarbage.
  ///
  /// In en, this message translates to:
  /// **'Garbage collection'**
  String get scheduleGarbage;

  /// No description provided for @scheduleCleaning.
  ///
  /// In en, this message translates to:
  /// **'Building cleaning'**
  String get scheduleCleaning;

  /// No description provided for @scheduleBulkWaste.
  ///
  /// In en, this message translates to:
  /// **'Bulk waste pickup'**
  String get scheduleBulkWaste;

  /// No description provided for @scheduleOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get scheduleOther;

  /// No description provided for @addScheduleEvent.
  ///
  /// In en, this message translates to:
  /// **'Add to schedule'**
  String get addScheduleEvent;

  /// No description provided for @scheduleEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No schedule yet'**
  String get scheduleEmptyTitle;

  /// No description provided for @scheduleEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add garbage collection days, cleaning times and one-off pickups so everyone in the building knows what\'s coming.'**
  String get scheduleEmptyBody;

  /// No description provided for @scheduleDayEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get scheduleDayEmptyTitle;

  /// No description provided for @scheduleDayEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No building events scheduled for this day.'**
  String get scheduleDayEmptyBody;

  /// No description provided for @scheduleDayEmptyBodyVaad.
  ///
  /// In en, this message translates to:
  /// **'No events yet — tap + to add something for this day.'**
  String get scheduleDayEmptyBodyVaad;

  /// No description provided for @announcementDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Date on calendar (optional)'**
  String get announcementDateOptional;

  /// No description provided for @announcementDateHint.
  ///
  /// In en, this message translates to:
  /// **'Add a date to show this on the building calendar'**
  String get announcementDateHint;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @scheduleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get scheduleWeekly;

  /// No description provided for @scheduleBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get scheduleBiweekly;

  /// No description provided for @scheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get scheduleDaily;

  /// No description provided for @scheduleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get scheduleMonthly;

  /// No description provided for @scheduleRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get scheduleRepeat;

  /// No description provided for @scheduleDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get scheduleDayOfMonth;

  /// No description provided for @scheduleOnce.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get scheduleOnce;

  /// No description provided for @scheduleDay.
  ///
  /// In en, this message translates to:
  /// **'Day of week'**
  String get scheduleDay;

  /// No description provided for @scheduleDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get scheduleDate;

  /// No description provided for @scheduleTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'Time (optional)'**
  String get scheduleTimeOptional;

  /// No description provided for @scheduleNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get scheduleNotesOptional;

  /// No description provided for @scheduleSaved.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated'**
  String get scheduleSaved;

  /// No description provided for @scheduleNotReady.
  ///
  /// In en, this message translates to:
  /// **'Building schedule is not ready yet. Run migration 0018_schedule_events.sql in the Supabase SQL editor, then try again.'**
  String get scheduleNotReady;

  /// No description provided for @scheduleTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get scheduleTomorrow;

  /// No description provided for @happeningToday.
  ///
  /// In en, this message translates to:
  /// **'Happening today'**
  String get happeningToday;

  /// No description provided for @scheduleEventToday.
  ///
  /// In en, this message translates to:
  /// **'{title} today'**
  String scheduleEventToday(String title);

  /// No description provided for @scheduleRecurring.
  ///
  /// In en, this message translates to:
  /// **'Repeats weekly'**
  String get scheduleRecurring;

  /// No description provided for @scheduleEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get scheduleEventTitle;

  /// No description provided for @scheduleEventType.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get scheduleEventType;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

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

  /// No description provided for @agentsComingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Coming in the next version'**
  String get agentsComingSoonBadge;

  /// No description provided for @agentsComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'AI agents for your vendors'**
  String get agentsComingSoonTitle;

  /// No description provided for @agentsComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Soon, Buildingo will contact elevator, plumbing, and cleaning vendors for you — open the service call, follow up, and keep residents in the loop.'**
  String get agentsComingSoonBody;

  /// No description provided for @agentsComingSoonFeature1.
  ///
  /// In en, this message translates to:
  /// **'Reach vendors by email, SMS, or WhatsApp'**
  String get agentsComingSoonFeature1;

  /// No description provided for @agentsComingSoonFeature2.
  ///
  /// In en, this message translates to:
  /// **'One tap after you approve a resident fault'**
  String get agentsComingSoonFeature2;

  /// No description provided for @agentsComingSoonFeature3.
  ///
  /// In en, this message translates to:
  /// **'Automatic updates back to the building board'**
  String get agentsComingSoonFeature3;

  /// No description provided for @agentsComingSoonFootnote.
  ///
  /// In en, this message translates to:
  /// **'Available in the next Buildingo release — stay tuned.'**
  String get agentsComingSoonFootnote;

  /// No description provided for @paymentsComingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get paymentsComingSoonBadge;

  /// No description provided for @paymentsComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay building dues in the app'**
  String get paymentsComingSoonTitle;

  /// No description provided for @paymentsComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'You opened Buildingo from your payment reminder. In-app payment is on the way — for now you can review dues in the Payments tab, or pay as usual outside the app.'**
  String get paymentsComingSoonBody;

  /// No description provided for @agentDispatchComingSoon.
  ///
  /// In en, this message translates to:
  /// **'AI vendor dispatch arrives in the next version. For now, move the ticket to In progress and handle the vendor yourself.'**
  String get agentDispatchComingSoon;

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

  /// No description provided for @pickStreetFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a street first'**
  String get pickStreetFirst;

  /// No description provided for @streetLabel.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get streetLabel;

  /// No description provided for @houseNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'House number'**
  String get houseNumberLabel;

  /// No description provided for @pickFromGovList.
  ///
  /// In en, this message translates to:
  /// **'Pick from the official list'**
  String get pickFromGovList;

  /// No description provided for @govAddressHint.
  ///
  /// In en, this message translates to:
  /// **'City and street come from the Israel government registry so every building uses the same spelling.'**
  String get govAddressHint;

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

  /// No description provided for @parkingSpotsLabel.
  ///
  /// In en, this message translates to:
  /// **'Parking spots (optional)'**
  String get parkingSpotsLabel;

  /// No description provided for @parkingSpotHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. B-12'**
  String get parkingSpotHint;

  /// No description provided for @addParkingSpot.
  ///
  /// In en, this message translates to:
  /// **'Add another parking spot'**
  String get addParkingSpot;

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
  /// **'Payments'**
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

  /// No description provided for @searchPayments.
  ///
  /// In en, this message translates to:
  /// **'Search by apartment, name or phone'**
  String get searchPayments;

  /// No description provided for @noPaymentSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No apartments match your search'**
  String get noPaymentSearchResults;

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

  /// No description provided for @paymentReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt · {month} {year}'**
  String paymentReceiptTitle(String month, String year);

  /// No description provided for @paymentReceiptsSection.
  ///
  /// In en, this message translates to:
  /// **'Payment receipts'**
  String get paymentReceiptsSection;

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

  /// No description provided for @newJoinRequestSnack.
  ///
  /// In en, this message translates to:
  /// **'New join request from {name}'**
  String newJoinRequestSnack(String name);

  /// No description provided for @newJoinRequestSnackGeneric.
  ///
  /// In en, this message translates to:
  /// **'New join request awaiting approval'**
  String get newJoinRequestSnackGeneric;

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

  /// No description provided for @accountSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account suspended'**
  String get accountSuspendedTitle;

  /// No description provided for @accountSuspendedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended. Contact support if you believe this is a mistake.'**
  String get accountSuspendedBody;

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
  /// **'Long-press a paid month to attach a receipt. A receipt icon stays clickable even if the month is unpaid.'**
  String get attachReceiptHint;

  /// No description provided for @confirmUnmarkPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as not paid?'**
  String get confirmUnmarkPaymentTitle;

  /// No description provided for @confirmUnmarkPaymentBody.
  ///
  /// In en, this message translates to:
  /// **'Mark {who} as not paid for {month} {year}?'**
  String confirmUnmarkPaymentBody(String who, String month, String year);

  /// No description provided for @paymentHasReceiptNote.
  ///
  /// In en, this message translates to:
  /// **'This month has a receipt attached.'**
  String get paymentHasReceiptNote;

  /// No description provided for @keepPaymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Keep the receipt'**
  String get keepPaymentReceipt;

  /// No description provided for @removePaymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Remove the receipt'**
  String get removePaymentReceipt;

  /// No description provided for @confirmMarkUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark unpaid'**
  String get confirmMarkUnpaid;

  /// No description provided for @markPaymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markPaymentPaid;

  /// No description provided for @receiptOnUnpaidHint.
  ///
  /// In en, this message translates to:
  /// **'Receipt on file'**
  String get receiptOnUnpaidHint;

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
