// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'Buildingo';

  @override
  String get retry => 'ניסיון חוזר';

  @override
  String get signOut => 'התנתקות';

  @override
  String get welcome => 'ברוכים הבאים ל-Buildingo';

  @override
  String get signInWithPhone => 'התחברות עם מספר הטלפון שלכם';

  @override
  String enterCodeSentTo(String phone) {
    return 'הזינו את הקוד ששלחנו אל $phone';
  }

  @override
  String enterWhatsAppCodeSentTo(String phone) {
    return 'הזינו את קוד ה-WhatsApp ששלחנו אל $phone';
  }

  @override
  String get sendCodeViaWhatsApp => 'שליחת קוד ב-WhatsApp';

  @override
  String get sendViaSmsInstead => 'שליחה ב-SMS במקום';

  @override
  String get sendViaWhatsAppInstead => 'שליחה ב-WhatsApp במקום';

  @override
  String get phoneNumber => 'מספר טלפון';

  @override
  String get smsCode => 'קוד מה-SMS';

  @override
  String get pleaseWait => 'רק רגע…';

  @override
  String get splashTagline => 'הבניין שלכם, יחד';

  @override
  String get splashLoading => 'מכינים הכל…';

  @override
  String get verifyAndSignIn => 'אימות והתחברות';

  @override
  String get sendCode => 'שליחת קוד';

  @override
  String get useDifferentNumber => 'שימוש במספר אחר';

  @override
  String get verificationFailed => 'האימות נכשל';

  @override
  String get invalidCode => 'קוד שגוי';

  @override
  String get authErrorGeneric => 'משהו השתבש. נסו שוב.';

  @override
  String get authErrorSmsSendFailed =>
      'לא הצלחנו לשלוח את קוד האימות. נסו שוב בעוד רגע.';

  @override
  String get authErrorWhatsAppSendFailed =>
      'לא הצלחנו לשלוח קוד ב-WhatsApp. נסו שוב, או בחרו SMS.';

  @override
  String get authErrorSmsUnavailable =>
      'לא ניתן לשלוח SMS למספר הזה כרגע (ספק או הגבלת ניסיונות). המתינו כמה דקות, נסו מספר אחר, או נסו שוב מאוחר יותר.';

  @override
  String get authErrorInvalidPhone =>
      'מספר הטלפון לא נראה תקין. בדקו את קידומת המדינה ונסו שוב.';

  @override
  String get authErrorTooManyRequests =>
      'יותר מדי ניסיונות. המתינו כמה דקות ונסו שוב.';

  @override
  String get authErrorNetwork => 'אין חיבור לאינטרנט. בדקו את הרשת ונסו שוב.';

  @override
  String get authErrorInvalidCode => 'הקוד אינו תקין. בדקו אותו ונסו שוב.';

  @override
  String get authErrorSessionExpired => 'הקוד פג תוקף. בקשו קוד חדש.';

  @override
  String get authErrorNotEnabled =>
      'התחברות עם טלפון אינה זמינה כרגע. נסו שוב מאוחר יותר.';

  @override
  String get completeProfile => 'השלמת פרופיל';

  @override
  String get myProfile => 'הפרופיל שלי';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get settingsNotificationsSection => 'התראות';

  @override
  String get settingsNotificationsNote =>
      'התראות באנר (Push) עדיין לא פעילות. כשהאפליקציה פתוחה, עדכונים מופיעים בזמן אמת. המתגים כאן שומרים את ההעדפות שלכם לכשיופעלו התראות מערכת.';

  @override
  String get settingsNotifyTickets => 'קריאות ותחזוקה';

  @override
  String get settingsNotifyTicketsHint => 'קריאות חדשות ועדכוני סטטוס';

  @override
  String get settingsNotifyAnnouncements => 'הודעות ועד';

  @override
  String get settingsNotifyAnnouncementsHint => 'הודעות מהוועד לדיירים';

  @override
  String get settingsNotifyPayments => 'תשלומים ודמי ועד';

  @override
  String get settingsNotifyPaymentsHint => 'תזכורות גבייה ועדכוני תשלום';

  @override
  String get settingsNotifyMessages => 'הודעות בניין';

  @override
  String get settingsNotifyMessagesHint => 'עדכונים כלליים מהבניין';

  @override
  String get settingsPrivacySection => 'פרטיות';

  @override
  String get settingsPrivacyBody =>
      'Buildingo בנויה לקהילת הבניין שלכם. אנחנו אוספים רק מה שנדרש לניהול הבניין — בלי פרסומות ובלי מכירת מידע אישי.';

  @override
  String get settingsPrivacyBullets =>
      '• מספר טלפון — להתחברות וליצירת קשר כדייר\n• שם ואימייל (אופציונלי) — מוצגים במדריך הדיירים\n• פרטי דירה ומסמכים שאתם מעלים (למשל ארנונה) — לדמי ועד ולאישור הוועד\n• מיקום — רק אם תבחרו ״שימוש במיקום הנוכחי״ בעת הזנת כתובת\n• שדות רגישים מוצפנים במנוחה בשרתים שלנו';

  @override
  String get settingsPrivacyPolicyLink => 'מדיניות הפרטיות';

  @override
  String get menu => 'תפריט';

  @override
  String get leftToCollect => 'נותר לגבייה';

  @override
  String get profileUpdated => 'הפרופיל נשמר';

  @override
  String get changePhoto => 'החלפת תמונה';

  @override
  String apartmentAndFloor(String apt, String floor) {
    return 'דירה $apt, קומה $floor';
  }

  @override
  String get noInviteFound =>
      'לא נמצאה הזמנה למספר הטלפון שלכם. הדביקו את קוד ההזמנה שקיבלתם מהוועד:';

  @override
  String get inviteCode => 'קוד הזמנה';

  @override
  String get fullName => 'שם מלא';

  @override
  String get numOccupants => 'מספר דיירים בדירה';

  @override
  String get uploadLease => 'העלאת חוזה שכירות (רשות)';

  @override
  String get saving => 'שומר…';

  @override
  String get enterMyBuilding => 'כניסה לבניין שלי';

  @override
  String get navHome => 'בית';

  @override
  String get navPayments => 'תשלומים';

  @override
  String get navResidents => 'דיירים';

  @override
  String get navDocs => 'מסמכים';

  @override
  String get navAgents => 'סוכנים';

  @override
  String get neighbor => 'שכן/ה';

  @override
  String hello(String name) {
    return 'שלום, $name!';
  }

  @override
  String get quickActions => 'פעולות מהירות';

  @override
  String get reportFault => 'דיווח תקלה';

  @override
  String get payDues => 'תשלום ועד';

  @override
  String get assemblies => 'אסיפות';

  @override
  String get myTickets => 'קריאות שירות';

  @override
  String get noOpenTickets => 'אין קריאות פתוחות — הכול שקט בבניין.';

  @override
  String get homeTicketsClearTitle => 'הכול שקט';

  @override
  String get homeTicketsClearBody =>
      'אין קריאות פתוחות כרגע. כל קריאה חדשה תופיע כאן.';

  @override
  String get noTicketsYet => 'אין קריאות עדיין';

  @override
  String get noTicketsHint => 'לחצו על + למטה כדי לדווח על תקלה בבניין.';

  @override
  String get communityBoard => 'לוח הבניין';

  @override
  String get seeDetails => 'לפרטים';

  @override
  String get viewAllCalls => 'לכל הקריאות';

  @override
  String get viewAllBoardMessages => 'כל ההודעות';

  @override
  String get allBoardMessages => 'כל הודעות הלוח';

  @override
  String boardPublishedOn(String date) {
    return 'פורסם ב-$date';
  }

  @override
  String get noCurrentBoardMessages => 'אין הודעות לשבוע הזה';

  @override
  String get paymentsSubtitle => 'כל התשלומים, מסודרים וברורים.';

  @override
  String get buildingBalance => 'יתרת בניין';

  @override
  String balanceAsOf(String date) {
    return 'נכון ל-$date';
  }

  @override
  String get buildingIncome => 'סה״כ הכנסות';

  @override
  String get buildingExpensesTotal => 'סה״כ הוצאות';

  @override
  String get monthlyCommitteeFees => 'דמי ועד חודשיים';

  @override
  String get paymentsAutoUpdated => 'התשלומים מתעדכנים באופן אוטומטי';

  @override
  String get residentsDirectory => 'ספר תושבים';

  @override
  String apartmentsCountN(String n) {
    return '$n דירות';
  }

  @override
  String get vaadTools => 'כלי ועד';

  @override
  String get toolGuests => 'אורחים';

  @override
  String get toolSurveys => 'סקרים';

  @override
  String get toolMessage => 'הודעה';

  @override
  String get ticketCatLeak => 'נזילה';

  @override
  String get ticketCatElevator => 'בעיה במעלית';

  @override
  String get ticketCatCleaning => 'ניקיון';

  @override
  String get ticketCatLights => 'מנורות שרופות';

  @override
  String get ticketCatElectric => 'תקלה בחשמל';

  @override
  String get ticketCatDoor => 'תקלה בדלת';

  @override
  String get ticketCatOther => 'אחר';

  @override
  String get ticketCategoryLabel => 'מה סוג התקלה?';

  @override
  String ticketCreatedOn(String date) {
    return 'נוצרה בתאריך $date';
  }

  @override
  String get ticketUploadingPhoto => 'מעלים תמונה…';

  @override
  String get ticketCreating => 'שולחים דיווח…';

  @override
  String get ticketCreateDone => 'הדיווח נשלח';

  @override
  String get ticketCreateFailed => 'שליחת הדיווח נכשלה';

  @override
  String get ticketRetry => 'נסה שוב';

  @override
  String get ticketDismiss => 'סגור';

  @override
  String get fromTheVaad => 'הודעה חדשה מהוועד';

  @override
  String get nothingOnBoard => 'אין הודעות על הלוח עדיין.';

  @override
  String get configureVendorFirst =>
      'קודם יש להגדיר סוכן ספק (תפריט ← סוכני ספקים).';

  @override
  String get dispatchToWhichVendor => 'לאיזה ספק לשלוח את סוכן ה-AI?';

  @override
  String agentDispatchingTo(String vendor) {
    return 'הסוכן פונה אל $vendor…';
  }

  @override
  String get vendorContacted => 'הספק עודכן.';

  @override
  String dispatchFailed(String message) {
    return 'השליחה נכשלה: $message';
  }

  @override
  String get maintenance => 'תקלות ותיקונים';

  @override
  String get vendorAgents => 'סוכני ספקים';

  @override
  String get newReport => 'דיווח חדש';

  @override
  String get resident => 'דייר/ת';

  @override
  String agentTo(String vendor) {
    return 'סוכן ← $vendor';
  }

  @override
  String get statusOpen => 'חדש';

  @override
  String get statusApproved => 'בטיפול';

  @override
  String get statusInProgress => 'בטיפול';

  @override
  String get statusResolved => 'טופל';

  @override
  String get approveAndDispatch => 'אישור ושליחת סוכן AI';

  @override
  String get markResolved => 'סימון כטופל';

  @override
  String get ticketTapStatusHint => 'לחצו על שלב כדי לעדכן סטטוס';

  @override
  String get ticketRepairCost => 'עלות התיקון';

  @override
  String get ticketRepairCostHint => 'כמה עלה התיקון?';

  @override
  String get ticketAddRepairCost => 'הוספת עלות תיקון';

  @override
  String get ticketEditRepairCost => 'עדכון עלות וקבלה';

  @override
  String get ticketCostSaved => 'עלות התיקון נשמרה';

  @override
  String ticketCostAmount(String amount) {
    return '₪$amount';
  }

  @override
  String get ticketEdit => 'עריכת קריאה';

  @override
  String get ticketEdited => 'הקריאה עודכנה';

  @override
  String get deleteTicket => 'מחיקת קריאה';

  @override
  String get deleteTicketConfirm => 'למחוק את הקריאה לצמיתות? לא ניתן לשחזר.';

  @override
  String get ticketDeleted => 'הקריאה נמחקה';

  @override
  String get auditTicketDeleted => 'קריאה נמחקה';

  @override
  String get editScheduleEvent => 'עריכת אירוע בלוח';

  @override
  String get editMeeting => 'עריכת אסיפה';

  @override
  String get deleteScheduleEvent => 'מחיקה מהלוח';

  @override
  String get deleteScheduleEventConfirm => 'להסיר את הפריט מלוח הבניין?';

  @override
  String get scheduleEventUpdated => 'הלוח עודכן';

  @override
  String get scheduleEventDeleted => 'הוסר מהלוח';

  @override
  String get auditMeetingUpdated => 'אסיפה עודכנה';

  @override
  String get auditMeetingDeleted => 'אסיפה נמחקה';

  @override
  String get ticketUpdateProgress => 'עדכון התקדמות';

  @override
  String get ticketProgressSaved => 'ההתקדמות עודכנה';

  @override
  String get ticketProgressNote => 'מה קורה עכשיו?';

  @override
  String get ticketProgressNoteHint => 'למשל: נפתח אצל הספק, הוזמנו חלקים…';

  @override
  String get ticketFixDateLabel => 'תאריך טיפול צפוי';

  @override
  String ticketFixDate(String date) {
    return 'תאריך טיפול: $date';
  }

  @override
  String ticketExpectedBy(String date) {
    return 'צפוי ל־$date';
  }

  @override
  String get ticketProgressOpenedProvider => 'נפתחה קריאה אצל ספק השירות';

  @override
  String get ticketProgressPartsOrdered => 'הוזמנו חלקים';

  @override
  String get ticketProgressScheduled => 'נקבע מועד לתיקון';

  @override
  String get reportAFault => 'דיווח על תקלה';

  @override
  String get whatHappened => 'מה קרה?';

  @override
  String get faultHint => 'למשל: המעלית תקועה בקומה 3';

  @override
  String get details => 'פרטים (רשות)';

  @override
  String get detailsHint => 'מתי זה התחיל? איפה בדיוק?';

  @override
  String get addMorePhotos => 'הוספת תמונות';

  @override
  String get submitting => 'שולח…';

  @override
  String get submitReport => 'שליחת דיווח';

  @override
  String get newVendorAgent => 'סוכן ספק חדש';

  @override
  String get vendorName => 'שם הספק';

  @override
  String get vendorNameHint => 'שירות מעליות שינדלר';

  @override
  String get serviceType => 'סוג השירות';

  @override
  String get serviceTypeHint => 'מעליות';

  @override
  String get emailOptional => 'אימייל (רשות)';

  @override
  String get phoneOptional => 'טלפון בפורמט ‎+972… (רשות)';

  @override
  String get vendorContactSection => 'איך הסוכן יפתח קריאה אצל הספק?';

  @override
  String get vendorContactHint =>
      'הסוכן ייצור קשר עם הספק רק דרך הערוצים שתבחרו כאן.';

  @override
  String get channelEmail => 'אימייל';

  @override
  String get channelSms => 'SMS';

  @override
  String get channelWhatsapp => 'וואטסאפ';

  @override
  String get vendorEmailLabel => 'אימייל הספק';

  @override
  String get vendorPhoneLabel => 'טלפון הספק';

  @override
  String get errSelectChannel => 'יש לבחור לפחות ערוץ התקשרות אחד';

  @override
  String get errEmailRequired => 'ערוץ האימייל דורש את כתובת האימייל של הספק';

  @override
  String get errPhoneRequired =>
      'ערוצי SMS/וואטסאפ דורשים את מספר הטלפון של הספק';

  @override
  String get contractOptional => 'פרטי החוזה (רשות)';

  @override
  String get aiInstructionsOptional => 'הנחיות נוספות לסוכן ה-AI (רשות)';

  @override
  String get cancel => 'ביטול';

  @override
  String get save => 'שמירה';

  @override
  String get vendorAiAgents => 'סוכני AI לספקים';

  @override
  String generatedDues(String count, String month) {
    return 'נוצרו $count חיובי ועד לחודש $month.';
  }

  @override
  String get recordExpense => 'רישום הוצאה';

  @override
  String get titleLabel => 'כותרת';

  @override
  String get category => 'קטגוריה';

  @override
  String get categoryHint => 'חשמל';

  @override
  String get amount => 'סכום';

  @override
  String get payments => 'תשלומים';

  @override
  String get generateMonthDues => 'יצירת חיובי החודש';

  @override
  String get outstandingDues => 'חובות פתוחים';

  @override
  String get youOwe => 'החוב שלך';

  @override
  String get buildingExpenses => 'הוצאות הבניין';

  @override
  String get paymentMatrix => 'מטריצת תשלומים';

  @override
  String get myDues => 'החיובים שלי';

  @override
  String apartmentShort(String number) {
    return 'דירה $number';
  }

  @override
  String get markPaid => 'סימון כשולם';

  @override
  String get overdue => 'בפיגור';

  @override
  String get pendingPayment => 'ממתין';

  @override
  String get expenseLedger => 'יומן הוצאות הבניין';

  @override
  String inviteResidentTo(String apt) {
    return 'הזמנת דייר/ת לדירה $apt';
  }

  @override
  String get sendInvite => 'שליחת הזמנה';

  @override
  String get inviteSmsSent => 'הזמנה נשלחה ב-SMS.';

  @override
  String inviteCreatedCode(String code) {
    return 'ההזמנה נוצרה — קוד: $code';
  }

  @override
  String get directoryTitle => 'ספר תושבים';

  @override
  String floorN(String n) {
    return 'קומה $n';
  }

  @override
  String get vacant => 'פנויה / לא רשומה';

  @override
  String parkingSpot(String spot) {
    return 'חניה: $spot';
  }

  @override
  String get noParking => 'ללא חניה משויכת';

  @override
  String directoryResidentSince(String date) {
    return 'מאז $date';
  }

  @override
  String get inviteResident => 'הזמנת דייר/ת';

  @override
  String get cantOpenDocument => 'לא ניתן לפתוח את המסמך';

  @override
  String get documents => 'מסמכים';

  @override
  String get noDocuments =>
      'אין מסמכים עדיין. סיכומי אסיפות, קבלות ופרוטוקולים יופיעו כאן.';

  @override
  String get buildingWide => 'כלל-בנייני';

  @override
  String voteRecorded(String option) {
    return 'ההצבעה נקלטה: $option';
  }

  @override
  String get newAssembly => 'אסיפה חדשה';

  @override
  String get activityLog => 'יומן פעילות';

  @override
  String get activityEmptyTitle => 'אין פעילות עדיין';

  @override
  String get activityEmptyBody =>
      'כל פעולה בבניין — הצטרפות דיירים, קריאות, אסיפות, הצבעות ותשלומים — תתועד כאן.';

  @override
  String get auditTenantJoined => 'דייר הצטרף';

  @override
  String get auditJoinRequested => 'בקשת הצטרפות';

  @override
  String get auditJoinRejected => 'בקשה נדחתה';

  @override
  String get auditTicketCreated => 'נפתחה קריאה';

  @override
  String get auditTicketDispatched => 'קריאה שוגרה לספק';

  @override
  String get auditTicketStatus => 'עדכון סטטוס קריאה';

  @override
  String get auditMeetingCreated => 'נקבעה אסיפה';

  @override
  String get auditMeetingClosed => 'אסיפה נסגרה';

  @override
  String get auditVoteCast => 'הצבעה';

  @override
  String get auditPaymentMarked => 'סימון תשלום';

  @override
  String get auditPaymentsBulk => 'סימון תשלומים מרוכז';

  @override
  String get auditExpenseAdded => 'נרשמה הוצאה';

  @override
  String get auditAnnouncement => 'פורסמה הודעה';

  @override
  String get auditVendorAdded => 'נוסף סוכן ספק';

  @override
  String get auditVendorUpdated => 'עודכן סוכן ספק';

  @override
  String get auditVendorDeleted => 'נמחק סוכן ספק';

  @override
  String get auditBuildingCreated => 'הבניין נוצר';

  @override
  String get auditVaadInvited => 'נשלחה הזמנה';

  @override
  String get meetingsEmptyTitle => 'אין אסיפות עדיין';

  @override
  String get meetingsEmptyBody =>
      'כאן מתכננים אסיפות דיירים, מצביעים על החלטות ומפרסמים סיכומים לכל הבניין.';

  @override
  String get residentsAssembly => 'אסיפת דיירים';

  @override
  String get meetingLocationLabel => 'מיקום';

  @override
  String get agendaItems => 'סעיפים לדיון';

  @override
  String get agendaItemsHint =>
      'הוסיפו סעיפים לסדר היום — כל סעיף יכול להיות דיון או הצבעה.';

  @override
  String get newAgendaItem => 'סעיף חדש';

  @override
  String get withVote => 'עם הצבעה';

  @override
  String get addItem => 'הוספה';

  @override
  String get voteChip => 'הצבעה';

  @override
  String get discussionChip => 'דיון';

  @override
  String get createMeetingCta => 'יצירת אסיפה';

  @override
  String get whatToCreate => 'מה תרצו ליצור?';

  @override
  String get ticketLocationLabel => 'מיקום התקלה';

  @override
  String get locLobby => 'לובי';

  @override
  String get locStairwell => 'חדר מדרגות';

  @override
  String get locElevator => 'מעלית';

  @override
  String get locParking => 'חניה';

  @override
  String get locRoof => 'גג';

  @override
  String get locYard => 'חצר';

  @override
  String get addPhoto => 'צירוף תמונה';

  @override
  String get removePhoto => 'הסרת תמונה';

  @override
  String get messageToBuilding => 'הודעה לבניין';

  @override
  String get announcementBody => 'תוכן ההודעה';

  @override
  String get announcementSubtitle => 'תישלח לכל דיירי הבניין';

  @override
  String get announcementCategoryLabel => 'סוג ההודעה';

  @override
  String get boardCatUpdate => 'עדכון חשוב';

  @override
  String get boardCatMeeting => 'אסיפת דיירים';

  @override
  String get boardCatMaintenance => 'תחזוקה';

  @override
  String get boardCatTip => 'טיפ';

  @override
  String get boardCatOther => 'אחר';

  @override
  String get boardActionDetails => 'לפרטים';

  @override
  String get boardActionRead => 'לקריאה';

  @override
  String get boardActionView => 'לצפייה';

  @override
  String get publishAnnouncement => 'פרסום ההודעה';

  @override
  String get announcementPublished => 'ההודעה פורסמה לדיירים';

  @override
  String get editBoardMessage => 'עריכת הודעה';

  @override
  String get deleteBoardMessage => 'מחיקת הודעה';

  @override
  String get deleteBoardMessageConfirm =>
      'להסיר את ההודעה מלוח הבניין? הדיירים לא יראו אותה יותר.';

  @override
  String get announcementUpdated => 'ההודעה עודכנה';

  @override
  String get announcementDeleted => 'ההודעה נמחקה';

  @override
  String get auditAnnouncementUpdated => 'הודעה עודכנה';

  @override
  String get auditAnnouncementDeleted => 'הודעה נמחקה';

  @override
  String get agenda => 'סדר יום';

  @override
  String get voteQuestionOptional => 'שאלת הצבעה בעד/נגד (רשות)';

  @override
  String get create => 'יצירה';

  @override
  String get voteYes => 'בעד';

  @override
  String get voteNo => 'נגד';

  @override
  String get voteAbstain => 'נמנע/ת';

  @override
  String get aiWritingSummary => 'ה-AI כותב את הסיכום…';

  @override
  String get summaryPublished => 'סיכום ה-PDF פורסם בלוח הבניין.';

  @override
  String get assembliesAndVoting => 'אסיפות והצבעות';

  @override
  String get closeAndPublish => 'סגירה ופרסום סיכום';

  @override
  String get stageReported => 'דווח';

  @override
  String get stageApprovedByVaad => 'אושר\nע״י הוועד';

  @override
  String get stageAgentWorking => 'סוכן AI\nמטפל';

  @override
  String get stageResolved => 'טופל';

  @override
  String get vendorContactedShort => 'הספק עודכן';

  @override
  String get language => 'English';

  @override
  String get howToJoinTitle => 'איך מצטרפים?';

  @override
  String get welcomeNoBuilding => 'מספר הטלפון שלכם עדיין לא מקושר לבניין.';

  @override
  String get choiceVaadTitle => 'אני חבר/ת ועד';

  @override
  String get choiceVaadSubtitle =>
      'הבניין שלי עוד לא ב-Buildingo — ניצור אותו ונזמין את הדיירים';

  @override
  String get choiceTenantTitle => 'אני דייר/ת';

  @override
  String get choiceTenantSubtitle =>
      'הבניין שלי כבר ב-Buildingo — נמצא אותו ונבקש להצטרף';

  @override
  String get choiceCodeTitle => 'יש לי קוד';

  @override
  String get choiceCodeSubtitle =>
      'קיבלתם הזמנה או קישור הצטרפות מהוועד? הזינו את הקוד כאן';

  @override
  String get joinCodeTitle => 'הצטרפות עם קוד';

  @override
  String get codeLabel => 'קוד';

  @override
  String get checkCode => 'בדיקת קוד';

  @override
  String joiningBuilding(String name) {
    return 'מצטרפים אל $name';
  }

  @override
  String get yourApartmentNumber => 'מספר הדירה שלכם';

  @override
  String get join => 'הצטרפות';

  @override
  String get createBuildingTitle => 'יצירת הבניין שלכם';

  @override
  String get country => 'מדינה';

  @override
  String get city => 'עיר';

  @override
  String get addressLabel => 'רחוב ומספר';

  @override
  String get postalCodeOptional => 'מיקוד (רשות)';

  @override
  String get findZipCode => 'מצא מיקוד';

  @override
  String get lookingUpZip => 'מחפש מיקוד…';

  @override
  String get zipLookupFailed => 'לא מצאנו מיקוד לכתובת הזו. אפשר להזין ידנית.';

  @override
  String get zipLookupUnavailable =>
      'חיפוש מיקוד לא זמין כרגע (שירות AI). אפשר להזין ידנית.';

  @override
  String get apartmentsCount => 'דירות';

  @override
  String get apartmentsPerFloor => 'בקומה';

  @override
  String get numberOfApartments => 'מספר דירות';

  @override
  String get numberOfFloors => 'מספר קומות';

  @override
  String get typicalFloorLabel => 'בקומה טיפוסית';

  @override
  String get baseFloorLabel => 'הקומה הראשונה';

  @override
  String get firstApartmentShortLabel => 'הדירה הראשונה';

  @override
  String get structureStepSubtitle =>
      'קובעים את הקומה הטיפוסית, ומתקנים רק את הקומות החריגות.';

  @override
  String floorsRangeSummary(
    String from,
    String to,
    String aptFrom,
    String aptTo,
  ) {
    return 'הקומות ירוצו מ־$from עד $to · הדירות ימוספרו מ־$aptFrom עד $aptTo';
  }

  @override
  String get floorDivisionTitle => 'חלוקה לקומות';

  @override
  String resetExceptions(String count) {
    return 'איפוס $count חריגים';
  }

  @override
  String floorBadge(String floor) {
    return 'ק$floor';
  }

  @override
  String get floorBadgeGround => 'קר';

  @override
  String floorAptsCount(String count) {
    return '$count דירות';
  }

  @override
  String floorAptsRange(String from, String to) {
    return 'דירות $from–$to';
  }

  @override
  String get exceptionBadge => 'חריג';

  @override
  String get mappingTotalLabel => 'סה״כ במיפוי';

  @override
  String mappingTotalMeta(String apts, String floors) {
    return '$apts דירות · $floors קומות';
  }

  @override
  String get floorPlanMismatch =>
      'סכום הדירות בקומות חייב להיות שווה למספר הדירות הכולל';

  @override
  String get feeMethodLabel => 'דמי ועד';

  @override
  String get feeFixed => 'קבוע לדירה';

  @override
  String get feePerSqm => 'לפי מ״ר';

  @override
  String get monthlyAmount => 'סכום חודשי (₪)';

  @override
  String get feeFixedMonthlyLabel => 'דמי ועד לדירה · לחודש';

  @override
  String get feePerApartmentUnit => 'לדירה';

  @override
  String get pricePerSqmLabel => 'מחיר למ״ר (₪)';

  @override
  String get updateVaadFee => 'הגדרת דמי ועד';

  @override
  String get buildingSettings => 'הגדרות בניין';

  @override
  String get joinPolicySection => 'מדיניות הצטרפות';

  @override
  String get createBuildingStepYou => 'הפרטים שלכם';

  @override
  String get createBuildingStepPlace => 'כתובת הבניין';

  @override
  String get createBuildingStepEntrances => 'כניסות ומעליות';

  @override
  String get createBuildingStepStructure => 'קומות ודירות';

  @override
  String get createBuildingStepFees => 'דמי ועד';

  @override
  String get createBuildingStepMyApartment => 'הדירה שלכם';

  @override
  String get createBuildingStepServices => 'שירותים קבועים';

  @override
  String get createBuildingStepBalance => 'יתרת חשבון';

  @override
  String get createBuildingStepSummary => 'סיכום ואישור';

  @override
  String get createBuildingYouSubtitle =>
      'הפרטים יוצגו לדיירים כפרטי הקשר של הוועד.';

  @override
  String get createBuildingYouAptLaterNote =>
      'בשלב הדירה תגדירו את הדירה שלכם — מספר, דיירים ומסמכים — כמו כל דייר בבניין.';

  @override
  String get createBuildingMyAptSubtitle =>
      'הזינו את פרטי הדירה שלכם. ניצור את הדירה ונשייך אתכם אליה כחברי ועד.';

  @override
  String get createBuildingPlaceSubtitle =>
      'כתובת אחת לפרוטוקולים, קבלות והזמנות.';

  @override
  String get createBuildingEntrancesSubtitle => 'קודי כניסה ומעליות של הבניין.';

  @override
  String get createBuildingFeesSubtitle => 'איך מחושבים דמי הוועד החודשיים.';

  @override
  String get createBuildingServicesSubtitle =>
      'הגדירו שירותים קבועים ליומן הבניין. אפשר לשנות אחר כך.';

  @override
  String get createBuildingSummarySubtitle =>
      'בדקו שהכול נכון לפני יצירת הבניין.';

  @override
  String get serviceCleaningStairs => 'ניקיון חדרי מדרגות';

  @override
  String get serviceGarbage => 'פינוי אשפה';

  @override
  String get serviceGardening => 'גינון';

  @override
  String get servicePest => 'הדברה';

  @override
  String get serviceWaterTank => 'ניקוי מאגר מים';

  @override
  String get serviceFrequencyWeekly => 'שבועי';

  @override
  String get serviceFrequencyBiweekly => 'דו-שבועי';

  @override
  String get serviceFrequencyMonthly => 'חודשי';

  @override
  String get serviceFrequencyQuarterly => 'רבעוני';

  @override
  String get serviceFrequencyYearly => 'שנתי';

  @override
  String get serviceCostHint => '₪ עלות';

  @override
  String get serviceProviderHint => 'שם ספק';

  @override
  String get serviceAddCustom => 'הוספת שירות מותאם';

  @override
  String get serviceCustomTitle => 'שם השירות';

  @override
  String get serviceSkipLater => 'דלג — אפשר להוסיף אחר כך';

  @override
  String serviceEstimatedMonthly(String amount) {
    return 'הוצאה חודשית משוערת · ₪$amount';
  }

  @override
  String serviceBalanceAfterFees(String amount) {
    return 'נותר מהגבייה · ₪$amount';
  }

  @override
  String get serviceCalendarNote =>
      'שירותים מופעלים יופיעו ביומן הבניין עם תזכורות לוועד.';

  @override
  String get serviceDayOfMonth => 'יום בחודש';

  @override
  String get serviceOffHint => 'כבוי — לחצו להגדרה';

  @override
  String get serviceDaySun => 'א';

  @override
  String get serviceDayMon => 'ב';

  @override
  String get serviceDayTue => 'ג';

  @override
  String get serviceDayWed => 'ד';

  @override
  String get serviceDayThu => 'ה';

  @override
  String get serviceDayFri => 'ו';

  @override
  String get serviceDaySat => 'ש';

  @override
  String get summaryServicesTitle => 'שירותים קבועים';

  @override
  String get summaryServicesNone => 'לא נבחרו';

  @override
  String get verifiedPhoneLabel => 'טלפון מאומת';

  @override
  String get myApartmentNumber => 'מספר דירה';

  @override
  String get committeeApartmentNote =>
      'הדירה תסומן כדירת הוועד במדריך הדיירים.';

  @override
  String get vaadAptClaimTitle => 'הדירה שלכם';

  @override
  String get vaadAptClaimSubtitle =>
      'בחרו את הדירה שלכם מתוך המיפוי. ניצור את כל הדירות בבניין ונשייך אתכם לדירה הזו בוועד.';

  @override
  String vaadAptRangeHint(String from, String to) {
    return 'מספרים במיפוי: $from–$to';
  }

  @override
  String get vaadAptOutOfPlan => 'מספר הדירה לא קיים במיפוי שהגדרתם';

  @override
  String vaadAptSqmHint(String typical) {
    return 'רשות — ברירת מחדל מהבניין: $typical מ\"ר';
  }

  @override
  String get countryIsrael => 'ישראל';

  @override
  String get countryUsa => 'USA';

  @override
  String get countryOther => 'אחר';

  @override
  String get districtOptional => 'מחוז / אזור (רשות)';

  @override
  String get useMyLocation => 'שימוש במיקום הנוכחי';

  @override
  String get locatingAddress => 'מאתרים את הכתובת…';

  @override
  String get locationFilledHint =>
      'מולא לפי המיקום הנוכחי — אפשר לערוך כל שדה.';

  @override
  String get locationOutsideIsrael =>
      'המיקום אינו בישראל. המדינה נשארת ישראל — מלאו ידנית, או החליפו מדינה.';

  @override
  String get locationUnavailable =>
      'לא הצלחנו לקרוא את המיקום. אפשר למלא את הכתובת ידנית.';

  @override
  String addressAlreadyRegistered(String name) {
    return 'כבר קיים בניין בכתובת המדויקת הזו ($name). לא ניתן ליצור בניין נוסף כאן — בקשו להצטרף אליו.';
  }

  @override
  String get addressAlreadyRegisteredTitle => 'הכתובת כבר תפוסה';

  @override
  String get gotIt => 'הבנתי';

  @override
  String get entrancesCountLabel => 'כניסות';

  @override
  String get elevatorsCountLabel => 'מעליות';

  @override
  String get entranceCodesTitle => 'קודי כניסה';

  @override
  String get entranceCodeHint => 'קוד (רשות)';

  @override
  String get entranceCodesPrivacyNote =>
      'קודי הכניסה גלויים לדיירי הבניין בלבד.';

  @override
  String get typicalApartmentSqmLabel => 'גודל דירה טיפוסית (מ״ר)';

  @override
  String feePreviewSize(String sqm) {
    return 'דירה $sqm מ״ר';
  }

  @override
  String feePreviewTypical(String sqm) {
    return 'טיפוסית · $sqm מ״ר';
  }

  @override
  String get feeTemporaryNote =>
      'עד שיוגדר גודל לכל דירה, החיוב מבוסס על הגודל הטיפוסי.';

  @override
  String get billingDayLabel => 'יום חיוב בחודש';

  @override
  String billingDaySummary(String day) {
    return 'יום חיוב: $day';
  }

  @override
  String get expectedMonthlyCollection => 'גבייה חודשית צפויה';

  @override
  String get sqmUnit => 'מ״ר';

  @override
  String get summaryContactTitle => 'פרטי קשר';

  @override
  String get summaryAddressTitle => 'כתובת';

  @override
  String get summaryBuildingTitle => 'הבניין';

  @override
  String get summaryFloorsTitle => 'קומות';

  @override
  String get summaryFeesTitle => 'דמי ועד';

  @override
  String summaryEntrancesLine(String entrances, String elevators) {
    return '$entrances כניסות · $elevators מעליות';
  }

  @override
  String apartmentLabel(String n) {
    return 'דירה $n';
  }

  @override
  String createBuildingNextWithApts(String n) {
    return 'המשך • $n דירות';
  }

  @override
  String get openingBalanceTitle => 'יתרת קופת הבניין';

  @override
  String get openingBalanceBody =>
      'כמה כסף יש כרגע בחשבון הבנק או בקופה של הבניין? זו נקודת ההתחלה ליתרת הבניין באפליקציה — תשלומי דיירים מתווספים, הוצאות יורדות. אפשר להשאיר 0 ולעדכן אחר כך.';

  @override
  String get openingBalanceLabel => 'יתרת קופה נוכחית (₪)';

  @override
  String get openingBalanceHint => 'רשות — אפשר להשאיר ריק.';

  @override
  String get openingBalanceSkip => 'להתחיל מאפס';

  @override
  String get openingBalanceRow => 'יתרת פתיחה';

  @override
  String get createBuildingNext => 'המשך';

  @override
  String get createBuildingBack => 'חזרה';

  @override
  String createBuildingStepOf(String current, String total) {
    return 'שלב $current מתוך $total';
  }

  @override
  String get comingSoonSection => 'הגדרות נוספות';

  @override
  String get shareAppSection => 'שיתוף Buildingo';

  @override
  String get shareAppTitle => 'שיתוף האפליקציה';

  @override
  String get shareAppSubtitle => 'הזמינו ועדים בבניינים אחרים בוואטסאפ';

  @override
  String shareAppMessage(String link) {
    return 'היי! אנחנו מנהלים את הבניין עם Buildingo — תשלומים, דיירים ותקלות במקום אחד. הורידו כאן: $link';
  }

  @override
  String get comingSoon => 'בקרוב';

  @override
  String get entranceCodesSoon => 'קוד כניסה (קדמית / אחורית)';

  @override
  String get garbageScheduleSoon => 'פינוי אשפה';

  @override
  String get cleaningScheduleSoon => 'ניקיון';

  @override
  String get saveFee => 'שמירה והודעה לדיירים';

  @override
  String get vaadFeeSaved => 'דמי הוועד עודכנו — נשלחה הודעה לבניין';

  @override
  String get apartmentSizeSqm => 'גודל הדירה (מ\"ר)';

  @override
  String get apartmentSizeRequired => 'נדרש גודל הדירה מחשבון הארנונה';

  @override
  String monthlyFeePreview(String amount) {
    return 'דמי הוועד החודשיים שלך: $amount';
  }

  @override
  String monthlyFeePreviewPerSqm(String amount, String sqm, String rate) {
    return '$amount לחודש ($sqm מ\"ר × $rate/מ\"ר, מעוגל למעלה)';
  }

  @override
  String existingApartmentSize(String sqm) {
    return 'גודל ידוע: $sqm מ\"ר';
  }

  @override
  String get sqmExtracted => 'הגודל נקרא מחשבון הארנונה';

  @override
  String get sqmEnterManually => 'לא הצלחנו לקרוא את הגודל — הזינו ידנית';

  @override
  String get yourMonthlyVaadFee => 'דמי ועד חודשיים';

  @override
  String get myApartmentOptional => 'מספר הדירה שלי (רשות)';

  @override
  String get createMyBuilding => 'יצירת הבניין';

  @override
  String get buildingCreated => 'הבניין שלכם מוכן!';

  @override
  String get shareJoinLink =>
      'הזמינו את הדיירים בקישור וואטסאפ — הם ממלאים פרטים ואתם מאשרים כל אחד:';

  @override
  String get joinPendingNote => 'ועד הבית יאשר את הבקשה לפני קבלת גישה';

  @override
  String get shareOnWhatsapp => 'שיתוף בוואטסאפ';

  @override
  String get joinLinkCopied => 'קישור ההצטרפות הועתק';

  @override
  String get continueLabel => 'המשך';

  @override
  String shareJoinMessage(String name, String link) {
    return 'היי! הבניין שלנו $name מנוהל עכשיו ב-Buildingo. לחצו להצטרפות: $link';
  }

  @override
  String get findBuildingTitle => 'מציאת הבניין שלכם';

  @override
  String get searchLabel => 'חיפוש';

  @override
  String get noBuildingFound =>
      'הבניין הזה עדיין לא קיים ב-Buildingo. בקשו מוועד הבית להוריד את האפליקציה וליצור אותו — זה לוקח שתי דקות.';

  @override
  String get askToJoin => 'בקשת הצטרפות';

  @override
  String get requestSent => 'הבקשה נשלחה לוועד!';

  @override
  String get waitingApprovalTitle => 'ממתינים לאישור הוועד';

  @override
  String waitingApprovalBody(String name) {
    return 'שלחנו את הבקשה שלכם לוועד של $name. תקבלו גישה ברגע שהיא תאושר.';
  }

  @override
  String get checkAgain => 'בדיקה חוזרת';

  @override
  String get requestRejectedTitle => 'הבקשה נדחתה';

  @override
  String requestRejectedBody(String name) {
    return 'הוועד של $name דחה את הבקשה. אפשר לחפש בניין אחר או לפנות אליו ישירות.';
  }

  @override
  String get searchAnotherBuilding => 'חיפוש מחדש';

  @override
  String get joinRequestsTitle => 'בקשות הצטרפות';

  @override
  String get approve => 'אישור';

  @override
  String get reject => 'דחייה';

  @override
  String wantsApartment(String apt) {
    return 'דירה $apt';
  }

  @override
  String get inviteLinkShare => 'הזמנת דיירים';

  @override
  String aptFloorAddress(String apt, String floor, String address) {
    return 'דירה $apt · קומה $floor · $address';
  }

  @override
  String get openTicketsStat => 'קריאות פתוחות';

  @override
  String withAgentCount(String n) {
    return '$n בטיפול סוכן';
  }

  @override
  String get nextPayment => 'התשלום הבא';

  @override
  String get allPaid => 'הכול שולם';

  @override
  String get vaadBadge => 'ועד הבית';

  @override
  String get unpaidThisMonth => 'לא שילמו החודש';

  @override
  String collectionSummaryLine(String unpaid, String total, String pct) {
    return '$unpaid דירות לא שילמו · מתוך $total · $pct% נגבה';
  }

  @override
  String collectionStatSub(String unpaid, String total, String pct) {
    return '$unpaid מתוך $total · $pct% נגבה';
  }

  @override
  String get collectedThisMonth => 'נגבו החודש';

  @override
  String get remainingThisMonth => 'נותר לגבייה';

  @override
  String collectionHeroSub(String collected, String pct) {
    return 'נגבו $collected · $pct%';
  }

  @override
  String get noTicketsThisMonth => 'אין קריאות חדשות החודש';

  @override
  String ticketsThisMonth(String n) {
    return '$n חדשות החודש';
  }

  @override
  String get ticketsSameAsLastMonth => 'כמו בחודש שעבר';

  @override
  String ticketsUpVsLastMonth(String pct) {
    return '+$pct% לעומת חודש שעבר';
  }

  @override
  String ticketsDownVsLastMonth(String pct) {
    return '-$pct% לעומת חודש שעבר';
  }

  @override
  String ofTotal(String total) {
    return 'מתוך $total';
  }

  @override
  String pendingJoinBanner(String n) {
    return '$n בקשות הצטרפות ממתינות לאישורכם';
  }

  @override
  String get newResidents => 'דיירים חדשים';

  @override
  String get noDuesYet => 'טרם הופקו חיובים לחודש';

  @override
  String get allApartmentsPaid => 'כל הדירות שילמו החודש.';

  @override
  String get viewAll => 'הכל';

  @override
  String get buildingSchedule => 'לוח הבניין';

  @override
  String get whatsappConnect => 'וואטסאפ';

  @override
  String get whatsappConnectBody =>
      'חברו מספר וואטסאפ לבניין ואז בחרו את קבוצת הדיירים. Buildingo יאזין לדיווחי תקלות בקבוצה ויפתח קריאות אוטומטית. אפשר גם לשלוח הודעות לדיירים בוואטסאפ.';

  @override
  String get whatsappNotConfigured => 'וואטסאפ (WAHA) עדיין לא מוגדר בשרת.';

  @override
  String get whatsappConnected => 'וואטסאפ מחובר';

  @override
  String get whatsappNotConnected => 'וואטסאפ לא מחובר';

  @override
  String get whatsappStartSession => 'התחלת חיבור וואטסאפ';

  @override
  String get whatsappScanQr => 'סרקו את ה-QR בוואטסאפ ← מכשירים מקושרים';

  @override
  String get whatsappPickGroup => 'בחרו את קבוצת הוואטסאפ של הבניין';

  @override
  String get whatsappGroupLinked => 'קבוצת הבניין קושרה';

  @override
  String get whatsappLoadGroups => 'טעינת קבוצות';

  @override
  String get comingUp => 'בקרוב';

  @override
  String get viewCalendar => 'לוח מלא';

  @override
  String get scheduleGarbage => 'פינוי אשפה';

  @override
  String get scheduleCleaning => 'ניקוי הבניין';

  @override
  String get scheduleBulkWaste => 'פינוי גזם';

  @override
  String get scheduleOther => 'אחר';

  @override
  String get addScheduleEvent => 'הוספה ללוח';

  @override
  String get scheduleEmptyTitle => 'אין לוח עדיין';

  @override
  String get scheduleEmptyBody =>
      'הוסיפו ימי פינוי אשפה, ניקוי ואירועים חד-פעמיים — כדי שכל הדיירים ידעו מה קורה בבניין.';

  @override
  String get scheduleDayEmptyTitle => 'אין אירועים ביום זה';

  @override
  String get scheduleDayEmptyBody => 'לא נקבעו אירועים ליום שבחרתם.';

  @override
  String get scheduleDayEmptyBodyVaad =>
      'אין אירועים עדיין — לחצו + כדי להוסיף ליום זה.';

  @override
  String get announcementDateOptional => 'תאריך בלוח (רשות)';

  @override
  String get announcementDateHint =>
      'הוסיפו תאריך כדי להציג את ההודעה בלוח הבניין';

  @override
  String get clear => 'ניקוי';

  @override
  String get scheduleWeekly => 'שבועי';

  @override
  String get scheduleBiweekly => 'כל שבועיים';

  @override
  String get scheduleDaily => 'כל יום';

  @override
  String get scheduleMonthly => 'כל חודש';

  @override
  String get scheduleRepeat => 'תדירות';

  @override
  String get scheduleDayOfMonth => 'יום בחודש';

  @override
  String get scheduleOnce => 'חד-פעמי';

  @override
  String get scheduleDay => 'יום בשבוע';

  @override
  String get scheduleDate => 'תאריך';

  @override
  String get scheduleTimeOptional => 'שעה (רשות)';

  @override
  String get scheduleNotesOptional => 'הערות (רשות)';

  @override
  String get scheduleSaved => 'הלוח עודכן';

  @override
  String get scheduleNotReady =>
      'לוח הבניין עדיין לא מוכן. יש להריץ את migration 0018_schedule_events.sql בעורך SQL של Supabase ולנסות שוב.';

  @override
  String get scheduleTomorrow => 'מחר';

  @override
  String get happeningToday => 'קורה היום';

  @override
  String scheduleEventToday(String title) {
    return '$title היום';
  }

  @override
  String get scheduleRecurring => 'חוזר מדי שבוע';

  @override
  String get scheduleEventTitle => 'כותרת';

  @override
  String get scheduleEventType => 'סוג אירוע';

  @override
  String get monday => 'שני';

  @override
  String get tuesday => 'שלישי';

  @override
  String get wednesday => 'רביעי';

  @override
  String get thursday => 'חמישי';

  @override
  String get friday => 'שישי';

  @override
  String get saturday => 'שבת';

  @override
  String get sunday => 'ראשון';

  @override
  String get dateToday => 'היום';

  @override
  String get dateYesterday => 'אתמול';

  @override
  String daysAgo(String n) {
    return 'לפני $n ימים';
  }

  @override
  String get announcementTag => 'הודעה';

  @override
  String get vendorAgentsEmptyTitle => 'אין עדיין סוכני AI';

  @override
  String get vendorAgentsEmptyBody =>
      'סוכן AI יוצר קשר עם הספקים שלכם — במייל, ב-SMS או בוואטסאפ — ופותח קריאת שירות ברגע שאתם מאשרים תקלה.';

  @override
  String get vendorAgentsStep1 => 'מוסיפים ספק עם פרטי ההתקשרות שלו';

  @override
  String get vendorAgentsStep2 => 'מאשרים דיווח תקלה של דייר';

  @override
  String get vendorAgentsStep3 => 'הסוכן פותח את הקריאה אצל הספק ומעדכן אתכם';

  @override
  String get agentsComingSoonBadge => 'בגרסה הבאה';

  @override
  String get agentsComingSoonTitle => 'סוכני AI לספקים שלכם';

  @override
  String get agentsComingSoonBody =>
      'בקרוב בילדינגו ייצור קשר עם ספקי מעליות, אינסטלציה וניקיון בשבילכם — יפתח קריאה, יעקוב אחריה ויעדכן את הדיירים.';

  @override
  String get agentsComingSoonFeature1 => 'פנייה לספק במייל, SMS או וואטסאפ';

  @override
  String get agentsComingSoonFeature2 => 'לחיצה אחת אחרי אישור תקלה מדייר';

  @override
  String get agentsComingSoonFeature3 =>
      'עדכונים אוטומטיים חזרה לוועד ולדיירים';

  @override
  String get agentsComingSoonFootnote =>
      'זמין בגרסת בילדינגו הבאה — המשך יבוא.';

  @override
  String get paymentsComingSoonBadge => 'בקרוב';

  @override
  String get paymentsComingSoonTitle => 'תשלום דמי ועד באפליקציה';

  @override
  String get paymentsComingSoonBody =>
      'פתחתם את בילדינגו מתזכורת התשלום. תשלום מתוך האפליקציה בדרך — בינתיים אפשר לראות חיובים בלשונית תשלומים, או לשלם כרגיל מחוץ לאפליקציה.';

  @override
  String get agentDispatchComingSoon =>
      'שליחת סוכן AI לספק מגיעה בגרסה הבאה. בינתיים העבירו את הקריאה ל״בטיפול״ וטפלו בספק ידנית.';

  @override
  String get addFirstVendor => 'הוספת הספק הראשון';

  @override
  String get edit => 'עריכה';

  @override
  String get delete => 'מחיקה';

  @override
  String get editVendorAgent => 'עריכת סוכן ספק';

  @override
  String get deleteVendorTitle => 'למחוק את סוכן הספק?';

  @override
  String deleteVendorConfirm(String name) {
    return 'הסוכן של $name יוסר ולא ייצור עוד קשר עם הספק. קריאות קיימות יישמרו.';
  }

  @override
  String get vendorDeleted => 'סוכן הספק נמחק';

  @override
  String get inviteViaLink => 'הזמנת דיירים בקישור';

  @override
  String get inviteResidents => 'הזמנת דיירים';

  @override
  String get inviteLinkExplain =>
      'כל מי שפותח את הקישור יכול לבקש להצטרף לבניין — האישור אצלכם.';

  @override
  String get copyLink => 'העתקת קישור';

  @override
  String get invitePending => 'הוזמן · ממתין לחיבור';

  @override
  String get findBuildingHint =>
      'חפשו לפי עיר וכתובת — בחרו מההשלמות כדי שנמצא התאמה מדויקת.';

  @override
  String get pickCityFirst => 'בחרו קודם עיר';

  @override
  String get pickStreetFirst => 'בחרו קודם רחוב';

  @override
  String get streetLabel => 'רחוב';

  @override
  String get houseNumberLabel => 'מספר בית';

  @override
  String get pickFromGovList => 'בחרו מהרשימה הרשמית';

  @override
  String get govAddressHint =>
      'עיר ורחוב נבחרים ממאגר ממשלתי כדי שכל הבניינים יישמרו באותו כתיב.';

  @override
  String get askVaadInviteHint =>
      'לא מוצאים את הבניין? בקשו מוועד הבית לשלוח לכם הזמנה אישית או את קישור ההצטרפות של הבניין.';

  @override
  String get tenantProfileTitle => 'הפרטים שלך';

  @override
  String get tenantProfileHint =>
      'הפרטים נשלחים לוועד הבית, שמאשר את הבקשה שלך.';

  @override
  String get floorLabel => 'קומה';

  @override
  String get numOccupantsLabel => 'מס׳ דיירים';

  @override
  String get parkingOptional => 'חניה (לא חובה)';

  @override
  String get parkingSpotsLabel => 'חניות (לא חובה)';

  @override
  String get parkingSpotHint => 'למשל ב-12';

  @override
  String get addParkingSpot => 'הוסיפו חניה נוספת';

  @override
  String get attachDocOptional => 'צירוף מסמך (לא חובה)';

  @override
  String get sendJoinRequest => 'שליחת בקשת הצטרפות';

  @override
  String occupantsN(String n) {
    return '$n דיירים בדירה';
  }

  @override
  String get viewAttachedDoc => 'צפייה במסמך המצורף';

  @override
  String get docsSection => 'מסמכים מומלצים';

  @override
  String get docsSectionRequired => 'מסמכים חובה';

  @override
  String get docsExplain =>
      'חשבון הארנונה מציג את גודל הדירה (מ\"ר) — הוא משפיע על גובה דמי הוועד. ההסכם מאשר שאתם גרים בדירה.';

  @override
  String get attachArnona => 'חשבון ארנונה';

  @override
  String get arnonaHint => 'מציג את גודל הדירה במ\"ר';

  @override
  String get attachResidence => 'אישור מגורים';

  @override
  String get residenceHint => 'חוזה שכירות או הסכם רכישה';

  @override
  String get optional => 'אופציונלי';

  @override
  String get requireDocsTitle => 'לדרוש מסמכים בהצטרפות';

  @override
  String get requireDocsSubtitle =>
      'דיירים חדשים יחויבו לצרף חשבון ארנונה ואישור מגורים';

  @override
  String get joinRequestPending => 'בקשת הצטרפות ממתינה לאישור';

  @override
  String get financesTitle => 'תשלומים';

  @override
  String get expensesTab => 'הוצאות';

  @override
  String collectionSummary(String count, String pct, String amount) {
    return '$count דירות · $pct% נגבו · חוב $amount';
  }

  @override
  String get allApartments => 'כל הדירות';

  @override
  String get onlyWithDebt => 'רק עם חוב';

  @override
  String get searchPayments => 'חיפוש לפי דירה, שם או טלפון';

  @override
  String get noPaymentSearchResults => 'אין דירות שתואמות לחיפוש';

  @override
  String get collapseAll => 'כיווץ הכל';

  @override
  String get apartmentColumn => 'דירה';

  @override
  String get debtColumn => 'חוב';

  @override
  String aptTiny(String n) {
    return 'ד׳ $n';
  }

  @override
  String debtAmount(String amount) {
    return 'חוב $amount';
  }

  @override
  String get noDebt => 'ללא חוב';

  @override
  String get markFloorPaid => 'סימון הקומה כשולמה';

  @override
  String get residentsSection => 'דיירים';

  @override
  String occupiedOfTotal(String occupied, String total) {
    return '$occupied/$total מאוכלסות';
  }

  @override
  String get searchResidents => 'חיפוש לפי שם, טלפון או דירה';

  @override
  String get pendingInvitesSection => 'הזמנות ממתינות';

  @override
  String get noDocsForApartment => 'לא צורפו מסמכים';

  @override
  String sqmShort(String n) {
    return '$n מ״ר';
  }

  @override
  String get currentPeriod => 'תקופה נוכחית';

  @override
  String get statusPaid => 'שולם';

  @override
  String get statusUnpaid => 'לא שולם';

  @override
  String get statusPending => 'ממתין';

  @override
  String get statusOverdue => 'בפיגור';

  @override
  String get noApartmentsYet => 'עוד לא הוגדרו דירות';

  @override
  String get noExpensesYet => 'עוד לא נרשמו הוצאות';

  @override
  String get providerOptional => 'ספק (אופציונלי)';

  @override
  String get descriptionOptional => 'תיאור (אופציונלי)';

  @override
  String get attachReceipt => 'צירוף קבלה (אופציונלי)';

  @override
  String get viewReceipt => 'צפייה בקבלה';

  @override
  String paymentReceiptTitle(String month, String year) {
    return 'קבלה על תשלום · $month $year';
  }

  @override
  String get paymentReceiptsSection => 'קבלות תשלום';

  @override
  String get expenseSaved => 'ההוצאה נשמרה';

  @override
  String joinApprovedSnack(String name) {
    return '$name אושר/ה והצטרף/ה לבניין';
  }

  @override
  String joinRejectedSnack(String name) {
    return 'הבקשה של $name נדחתה';
  }

  @override
  String newJoinRequestSnack(String name) {
    return 'בקשת הצטרפות חדשה מ־$name';
  }

  @override
  String get newJoinRequestSnackGeneric => 'בקשת הצטרפות חדשה ממתינה לאישור';

  @override
  String get viewArnonaDoc => 'צפייה בחשבון הארנונה';

  @override
  String get viewResidenceDoc => 'צפייה באישור המגורים';

  @override
  String get myBuilding => 'הבניין שלי';

  @override
  String get trialNotice =>
      '14 ימי ניסיון חינם: גישה מלאה לכל הבניין. לאחר מכן רק ₪4.90 לדירה לחודש — צרו קשר להפעלת מנוי.';

  @override
  String get trialEndedTitle => 'תקופת הניסיון הסתיימה';

  @override
  String get trialEndedBody =>
      '14 ימי הניסיון של הבניין הסתיימו. כל המידע שלכם שמור ומחכה לכם.';

  @override
  String get accessBlockedTitle => 'הגישה מושהית';

  @override
  String get accessBlockedBody =>
      'הגישה של הבניין הושהתה. צרו קשר כדי לשחזר אותה — כל המידע נשמר.';

  @override
  String get pricingLine => '₪4.90 לדירה / לחודש';

  @override
  String get likeItContactUs =>
      'אהבתם את Buildingo? צרו איתנו קשר ונפעיל את המנוי לבניין — בלי תשלום בתוך האפליקציה.';

  @override
  String get contactUs => 'צרו קשר';

  @override
  String get contactFormHint => 'השאירו פרטים ונחזור אליכם בהקדם.';

  @override
  String get contactMessage => 'הודעה';

  @override
  String get contactSend => 'שליחה';

  @override
  String get invalidPhone => 'מספר טלפון לא תקין';

  @override
  String get contactSentTitle => 'ההודעה נשלחה!';

  @override
  String get contactSentBody => 'תודה! קיבלנו את ההודעה ונחזור אליכם בקרוב.';

  @override
  String get transferHolder => 'החלפת מחזיק';

  @override
  String get holdersHistory => 'היסטוריית מחזיקים';

  @override
  String get currentHolder => 'מחזיק נוכחי';

  @override
  String get pendingHolder => 'ממתין להשלמת פרטים';

  @override
  String get holderOwner => 'בעלים';

  @override
  String get holderRenter => 'שוכר/ת';

  @override
  String get noPreviousHolders => 'ללא מחזיקים קודמים';

  @override
  String previousHoldersN(String n) {
    return '$n מחזיקים קודמים';
  }

  @override
  String periodSince(String date) {
    return 'מאז $date';
  }

  @override
  String get newHolderFallback => 'מחזיק חדש';

  @override
  String get noPhone => 'ללא טלפון';

  @override
  String apartmentCardTitle(String n) {
    return 'כרטיס דירה $n';
  }

  @override
  String get stepEndTenancy => 'סיום החזקה';

  @override
  String get stepIncomingHolder => 'המחזיק הנכנס';

  @override
  String get stepConfirmTransfer => 'אישור והעברה';

  @override
  String endTenancyTitle(String name) {
    return 'סיום החזקה — $name';
  }

  @override
  String get endTenancyBody =>
      'הכרטיס של הדירה נשמר במלואו. המחזיק היוצא עובר לארכיון עם התקופה שלו, וההיסטוריה נשארת מקושרת לדירה.';

  @override
  String get endDateLabel => 'תאריך קובע לסיום';

  @override
  String get debtQuestion => 'מה קורה לחיובים הפתוחים';

  @override
  String get debtKeepTitle => 'החוב נשאר על השוכר היוצא';

  @override
  String get debtKeepBody =>
      'החיובים הפתוחים נרשמים על שמו וממשיכים במעקב הגבייה';

  @override
  String get debtOwnerTitle => 'החוב מועבר לבעל הדירה';

  @override
  String get debtOwnerBody => 'הוועד יגבה מהבעלים לפי סעיף החוזה';

  @override
  String get debtCloseTitle => 'סגירת החוב';

  @override
  String get debtCloseBody => 'החוב נמחק בהחלטת ועד — יירשם ביומן הבניין';

  @override
  String incomingDetailsBody(String n, String date) {
    return 'הפרטים ישויכו לדירה $n מהתאריך $date.';
  }

  @override
  String get modeSelfTitle => 'המחזיק ימלא בעצמו';

  @override
  String get modeSelfBody =>
      'שולחים קישור ב-SMS. הוא מאמת טלפון וממלא שם, נפשות וחוזה — הדירה מסומנת \"ממתין להשלמת פרטים\" עד אז.';

  @override
  String get modeVaadTitle => 'מילוי ידני ע\"י הוועד';

  @override
  String get modeVaadBody =>
      'ממלאים את הפרטים כאן ועכשיו. אפשר לשלוח קישור בהמשך.';

  @override
  String get optionalField => 'לא חובה';

  @override
  String get mobilePhoneLabel => 'טלפון נייד';

  @override
  String get holderTypeLabel => 'סוג החזקה';

  @override
  String get startDateLabel => 'תאריך תחילת החזקה';

  @override
  String get sendSmsOnTransfer => 'שליחת הקישור ב-SMS מיד עם אישור ההעברה';

  @override
  String get linkExplainTitle => 'מה המחזיק ימלא';

  @override
  String get linkStepOtp => 'אימות מספר טלפון בקוד SMS';

  @override
  String get linkStepProfile => 'שם מלא ומספר נפשות';

  @override
  String get linkStepContract => 'העלאת חוזה שכירות · לא חובה';

  @override
  String get linkStepConfirm => 'אישור פרטי חניה ותקשורת';

  @override
  String get selfCompleteNote => 'המחזיק ימלא את פרטיו דרך הקישור';

  @override
  String get keptOnCardTitle => 'נשמר בכרטיס הדירה';

  @override
  String get keptOnCardBody =>
      'היסטוריית תשלומים, קריאות תחזוקה, קבלות הדירה ופרוטוקולי אסיפות';

  @override
  String get movesToNewTitle => 'עובר למחזיק החדש';

  @override
  String get movesToNewBody =>
      'החיובים מהתאריך הקובע, גישה ללוח הבניין, ספר הדיירים והצבעות';

  @override
  String get staysWithOutgoingTitle => 'נשאר אצל המחזיק היוצא';

  @override
  String get staysWithOutgoingBody =>
      'חוזה השכירות והמסמכים האישיים שלו · הגישה לאפליקציה נחסמת בתאריך הקובע';

  @override
  String get transferLogNote =>
      'ההעברה תירשם ביומן הבניין עם שם המאשר והתאריך. ניתן לצפות בכל המחזיקים הקודמים בכרטיס הדירה.';

  @override
  String get confirmAndTransfer => 'אישור והעברת הדירה';

  @override
  String get backBtn => 'חזרה';

  @override
  String get transferDone => 'המחזיק הוחלף בהצלחה';

  @override
  String get auditTenantTransferred => 'החלפת מחזיק';

  @override
  String get pollOptionsLabel => 'אפשרויות תשובה';

  @override
  String optionHint(String n) {
    return 'אפשרות $n';
  }

  @override
  String get addOption => 'הוספת אפשרות';

  @override
  String get allowMultipleAnswers => 'אפשר לבחור כמה תשובות';

  @override
  String get multiChoiceChip => 'בחירה מרובה';

  @override
  String optionsCount(String n) {
    return '$n אפשרויות';
  }

  @override
  String get submitVote => 'שליחת הצבעה';

  @override
  String get allSettled => 'הכול משולם';

  @override
  String monthsPaidOfYear(String paid, String total, String year) {
    return '$paid מתוך $total חודשים שולמו · $year';
  }

  @override
  String get noChargesForYear => 'אין חיובים לשנה זו';

  @override
  String paidOnDate(String date) {
    return 'שולם ב-$date';
  }

  @override
  String get receiptShort => 'קבלה';

  @override
  String get receiptAttached => 'הקבלה צורפה';

  @override
  String get attachReceiptOnlyPaid => 'אפשר לצרף קבלה רק לחודש ששולם';

  @override
  String get attachReceiptHint =>
      'לחיצה ארוכה על חודש ששולם — צירוף קבלה. אייקון קבלה נשאר לחיץ גם אם החודש מסומן כלא שולם.';

  @override
  String get confirmUnmarkPaymentTitle => 'לסמן כלא שולם?';

  @override
  String confirmUnmarkPaymentBody(String who, String month, String year) {
    return 'לסמן את $who כלא שולם עבור $month $year?';
  }

  @override
  String get paymentHasReceiptNote => 'לחודש זה מצורפת קבלה.';

  @override
  String get keepPaymentReceipt => 'להשאיר את הקבלה';

  @override
  String get removePaymentReceipt => 'להסיר את הקבלה';

  @override
  String get confirmMarkUnpaid => 'סמן כלא שולם';

  @override
  String get markPaymentPaid => 'סמן כשולם';

  @override
  String get receiptOnUnpaidHint => 'יש קבלה בתיק';

  @override
  String get takePhoto => 'צילום במצלמה';

  @override
  String get fromGallery => 'בחירה מהגלריה';

  @override
  String get chooseFile => 'עיון בקבצים';

  @override
  String get locOther => 'אחר';

  @override
  String get locOtherHint => 'איפה בדיוק?';

  @override
  String get uploadDocument => 'העלאת מסמך';

  @override
  String get documentsUploaded => 'המסמכים הועלו';

  @override
  String get addAttachment => 'הוספת קובץ (מצלמה / גלריה)';

  @override
  String get addMoreFiles => 'הוספת קבצים נוספים';

  @override
  String uploadNFiles(String n) {
    return 'העלאת $n קבצים';
  }

  @override
  String get allYear => 'כל השנה';
}
