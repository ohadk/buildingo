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
  String get phoneNumber => 'מספר טלפון';

  @override
  String get smsCode => 'קוד מה-SMS';

  @override
  String get pleaseWait => 'רק רגע…';

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
  String get completeProfile => 'השלמת פרופיל';

  @override
  String get myProfile => 'הפרופיל שלי';

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
  String get myTickets => 'הקריאות שלי';

  @override
  String get noOpenTickets => 'אין קריאות פתוחות — הכול שקט בבניין.';

  @override
  String get noTicketsYet => 'אין קריאות עדיין';

  @override
  String get noTicketsHint => 'לחצו על + למטה כדי לדווח על תקלה בבניין.';

  @override
  String get communityBoard => 'לוח הקהילה';

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
  String get statusOpen => 'פתוחה';

  @override
  String get statusApproved => 'אושרה';

  @override
  String get statusInProgress => 'בטיפול';

  @override
  String get statusResolved => 'טופלה';

  @override
  String get approveAndDispatch => 'אישור ושליחת סוכן AI';

  @override
  String get markResolved => 'סימון כטופל';

  @override
  String get reportAFault => 'דיווח על תקלה';

  @override
  String get whatHappened => 'מה קרה?';

  @override
  String get faultHint => 'למשל: המעלית תקועה בקומה 3';

  @override
  String get details => 'פרטים';

  @override
  String get detailsHint => 'מתי זה התחיל? איפה בדיוק?';

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
  String get directoryTitle => 'דיירים וחניות';

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
  String get publishAnnouncement => 'פרסום ההודעה';

  @override
  String get announcementPublished => 'ההודעה פורסמה לדיירים';

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
  String get apartmentsCount => 'דירות';

  @override
  String get apartmentsPerFloor => 'בקומה';

  @override
  String get feeMethodLabel => 'דמי ועד';

  @override
  String get feeFixed => 'קבוע לדירה';

  @override
  String get feePerSqm => 'לפי מ״ר';

  @override
  String get monthlyAmount => 'סכום חודשי (₪)';

  @override
  String get pricePerSqmLabel => 'מחיר למ״ר (₪)';

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
  String collectionHeroSub(String total, String pct) {
    return 'מתוך $total · $pct% נגבה';
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
  String get financesTitle => 'כספים';

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
  String get attachReceiptHint => 'לחיצה ארוכה על חודש ששולם — צירוף קבלה';

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
