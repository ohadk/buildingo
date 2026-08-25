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
  String get navMaintenance => 'תחזוקה';

  @override
  String get navResidents => 'דיירים';

  @override
  String get navDocs => 'מסמכים';

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
  String get maintenance => 'תחזוקה';

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
  String get collectedThisMonth => 'נגבו החודש';

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
}
