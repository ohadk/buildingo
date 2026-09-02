import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/building_floor_plan.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/israel_gov_address_fields.dart';
import '../widgets/parking_spots_field.dart';
import '../widgets/phone_field.dart';

/// Self-service building creation: 8-step Vaad onboarding.
class CreateBuildingScreen extends StatefulWidget {
  const CreateBuildingScreen({super.key});

  @override
  State<CreateBuildingScreen> createState() => _CreateBuildingScreenState();
}

class _CreateBuildingScreenState extends State<CreateBuildingScreen> {
  static const _stepCount = 8;
  static const _hebrewLetters = [
    'א',
    'ב',
    'ג',
    'ד',
    'ה',
    'ו',
    'ז',
    'ח',
    'ט',
    'י',
  ];

  final _page = PageController();
  int _step = 0;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _myApt = TextEditingController();
  final _occupants = TextEditingController(text: '1');
  final _mySqm = TextEditingController();
  List<String> _parkingSpots = [];
  final _country = TextEditingController(text: IsraelGovAddressFields.israel);
  final _city = TextEditingController();
  final _street = TextEditingController();
  final _houseNumber = TextEditingController();
  final _postal = TextEditingController();
  final _district = TextEditingController();
  final _openingBalance = TextEditingController(text: '0');

  PlatformFile? _arnonaDoc;
  PlatformFile? _residenceDoc;

  String _feeMethod = 'per_sqm';
  double _pricePerSqm = 6.0;
  double _typicalSqm = 78;
  double _fixedFee = 390;
  int _billingDay = 1;

  int _entranceCount = 1;
  int _elevatorCount = 0;
  final List<TextEditingController> _entranceCodes = [
    TextEditingController(),
  ];

  late final List<_ServiceDraft> _services = _ServiceDraft.presets();

  bool _busy = false;
  String? _error;
  bool _placeValid = false;
  bool _structureValid = false;
  BuildingFloorPlan? _floorPlan;

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    _email.dispose();
    _myApt.dispose();
    _occupants.dispose();
    _mySqm.dispose();
    _country.dispose();
    _city.dispose();
    _street.dispose();
    _houseNumber.dispose();
    _postal.dispose();
    _district.dispose();
    _openingBalance.dispose();
    for (final c in _entranceCodes) {
      c.dispose();
    }
    for (final s in _services) {
      s.dispose();
    }
    super.dispose();
  }

  double get _expectedCollection {
    final aptCount = _floorPlan?.totalApartments ?? 0;
    if (aptCount < 1) return 0;
    if (_feeMethod == 'fixed') return _fixedFee * aptCount;
    return _pricePerSqm * _typicalSqm * aptCount;
  }

  List<Map<String, dynamic>> _recurringServicesPayload(AppLocalizations l10n) {
    final out = <Map<String, dynamic>>[];
    for (final s in _services) {
      if (!s.enabled) continue;
      final title = s.resolvedTitle(l10n).trim();
      if (title.length < 2) continue;
      final cost = double.tryParse(
        s.costCtrl.text.trim().replaceAll(',', '.').replaceAll('₪', ''),
      );
      final provider = s.providerCtrl.text.trim();
      final weekly = s.recurrence == 'weekly' || s.recurrence == 'biweekly';
      out.add({
        'eventType': s.eventType,
        'title': title,
        'recurrence': s.recurrence,
        if (weekly && s.daysOfWeek.isNotEmpty) 'daysOfWeek': [...s.daysOfWeek],
        if (!weekly) 'dayOfMonth': s.dayOfMonth,
        if (cost != null && cost > 0) 'monthlyCost': cost,
        if (provider.isNotEmpty) 'providerName': provider,
      });
    }
    return out;
  }

  void _syncEntranceControllers(int count) {
    while (_entranceCodes.length < count) {
      _entranceCodes.add(TextEditingController());
    }
    while (_entranceCodes.length > count) {
      _entranceCodes.removeLast().dispose();
    }
  }

  bool get _myApartmentValid {
    final plan = _floorPlan;
    if (plan == null) return false;
    final apt = int.tryParse(_myApt.text.trim());
    final occupants = int.tryParse(_occupants.text.trim());
    if (apt == null || !plan.containsApartment(apt)) return false;
    if (occupants == null || occupants < 1) return false;
    if (_feeMethod == 'per_sqm') {
      final sqm = double.tryParse(_mySqm.text.trim().replaceAll(',', '.'));
      // Empty = use building typical later; if typed must be valid.
      if (_mySqm.text.trim().isNotEmpty && (sqm == null || sqm <= 0)) {
        return false;
      }
    }
    return true;
  }

  bool get _stepValid {
    switch (_step) {
      case 0:
        return _name.text.trim().length >= 2;
      case 1:
        return _placeValid;
      case 2:
        return _entranceCount >= 1;
      case 3:
        return _structureValid &&
            _floorPlan != null &&
            _floorPlan!.totalApartments > 0;
      case 4:
        if (_feeMethod == 'fixed') return _fixedFee > 0;
        return _pricePerSqm > 0 && _typicalSqm > 0;
      case 5:
        return _myApartmentValid;
      case 6:
        return true; // services step is skippable
      case 7:
        return true;
      default:
        return false;
    }
  }

  String _stepTitle(AppLocalizations l10n) => switch (_step) {
        0 => l10n.createBuildingStepYou,
        1 => l10n.createBuildingStepPlace,
        2 => l10n.createBuildingStepEntrances,
        3 => l10n.createBuildingStepStructure,
        4 => l10n.createBuildingStepFees,
        5 => l10n.createBuildingStepMyApartment,
        6 => l10n.createBuildingStepServices,
        _ => l10n.createBuildingStepSummary,
      };

  String _ctaLabel(AppLocalizations l10n) {
    if (_busy) return l10n.pleaseWait;
    if (_step == _stepCount - 1) return l10n.createMyBuilding;
    if (_step == 3) {
      final n = _floorPlan?.totalApartments ?? 0;
      return l10n.createBuildingNextWithApts('$n');
    }
    return l10n.createBuildingNext;
  }

  Future<void> _goNext() async {
    if (_step < _stepCount - 1) {
      setState(() {
        _step++;
        _error = null;
      });
      await _page.animateToPage(
        _step,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _submit();
  }

  Future<void> _goBack() async {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _step--;
      _error = null;
    });
    await _page.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goToStep(int index) async {
    if (index < 0 || index >= _stepCount) return;
    setState(() {
      _step = index;
      _error = null;
    });
    await _page.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<String?> _uploadDoc(PlatformFile? doc) async {
    if (doc == null) return null;
    final res = await api.uploadFile(
      '/api/join-requests/upload',
      bytes: await doc.readAsBytes(),
      filename: doc.name,
    );
    return res['docPath'] as String?;
  }

  Future<void> _submit() async {
    final session = context.read<SessionController>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final opening = double.tryParse(_openingBalance.text.trim()) ?? 0;
      final address = IsraelGovAddressFields.composeAddress(
        _street.text,
        _houseNumber.text,
      );
      final plan = _floorPlan;
      if (plan == null || plan.totalApartments < 1) {
        setState(() => _error = context.l10n.floorPlanMismatch);
        return;
      }
      final myAptNum = int.tryParse(_myApt.text.trim());
      if (myAptNum == null || !plan.containsApartment(myAptNum)) {
        setState(() => _error = context.l10n.vaadAptOutOfPlan);
        return;
      }
      final occupants = int.tryParse(_occupants.text.trim()) ?? 1;
      final mySqm = double.tryParse(
        _mySqm.text.trim().replaceAll(',', '.'),
      );
      final arnonaDocPath = await _uploadDoc(_arnonaDoc);
      final residenceDocPath = await _uploadDoc(_residenceDoc);
      final aptCount = plan.totalApartments;
      final entrances = [
        for (var i = 0; i < _entranceCount; i++)
          {
            'name': _hebrewLetters[i],
            'code': _entranceCodes[i].text.trim(),
          },
      ];
      final recurring = _recurringServicesPayload(context.l10n);
      final joinLink = await session.createBuilding({
        'address': address,
        'city': _city.text.trim(),
        'country': _country.text.trim(),
        if (_postal.text.trim().isNotEmpty) 'postalCode': _postal.text.trim(),
        if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
        'apartmentCount': aptCount,
        ...plan.toJson(),
        'elevatorCount': _elevatorCount,
        'entrances': entrances,
        'feeMethod': _feeMethod,
        if (_feeMethod == 'fixed') 'fixedMonthlyFee': _fixedFee,
        if (_feeMethod == 'per_sqm') 'pricePerSqm': _pricePerSqm,
        'typicalApartmentSqm': _typicalSqm,
        'billingDay': _billingDay,
        'openingBalance': opening,
        'myApartmentNumber': myAptNum,
        'fullName': _name.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        'numOccupants': occupants,
        if (_parkingSpots.isNotEmpty) 'parkingSpots': _parkingSpots,
        if (mySqm != null && mySqm > 0) 'mySizeSqm': mySqm,
        if (arnonaDocPath != null) 'arnonaDocPath': arnonaDocPath,
        if (residenceDocPath != null) 'residenceDocPath': residenceDocPath,
        if (recurring.isNotEmpty) 'recurringServices': recurring,
      });
      if (!mounted) return;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'success',
        barrierColor: Colors.black.withValues(alpha: 0.45),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => _SuccessDialog(
          joinLink: joinLink,
          buildingName: session.building?.name ?? '',
        ),
        transitionBuilder: (context, anim, _, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      );
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: DiraColors.cream,
      appBar: AppBar(
        centerTitle: true,
        title: Text(l10n.createBuildingTitle),
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: Center(
            child: Material(
              color: DiraColors.creamCard,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _busy ? null : _goBack,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_rounded, size: 20),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(
              l10n.save,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.createBuildingStepOf('${_step + 1}', '$_stepCount'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: DiraColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (_step + 1) / _stepCount),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: DiraColors.sageLight,
                      color: DiraColors.brick,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    _stepTitle(l10n),
                    key: ValueKey(_step),
                    style: heading(fontSize: 22),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepScroll(
                  child: _YouStep(
                    name: _name,
                    email: _email,
                    onChanged: () => setState(() {}),
                  ),
                ),
                _StepScroll(
                  child: IsraelGovAddressFields(
                    country: _country,
                    city: _city,
                    street: _street,
                    houseNumber: _houseNumber,
                    postal: _postal,
                    district: _district,
                    subtitle: l10n.createBuildingPlaceSubtitle,
                    onChanged: () => setState(() {}),
                    onValidityChanged: (ok) {
                      if (_placeValid == ok) return;
                      setState(() => _placeValid = ok);
                    },
                  ),
                ),
                _StepScroll(
                  child: _EntrancesStep(
                    entranceCount: _entranceCount,
                    elevatorCount: _elevatorCount,
                    codes: _entranceCodes,
                    letters: _hebrewLetters,
                    onEntrances: (n) {
                      setState(() {
                        _entranceCount = n;
                        _syncEntranceControllers(n);
                      });
                    },
                    onElevators: (n) => setState(() => _elevatorCount = n),
                    onChanged: () => setState(() {}),
                  ),
                ),
                _StepScroll(
                  child: _StructureStep(
                    onChanged: () => setState(() {}),
                    onPlanChanged: (plan) => setState(() => _floorPlan = plan),
                    onValidChanged: (ok) {
                      if (_structureValid == ok) return;
                      setState(() => _structureValid = ok);
                    },
                  ),
                ),
                _StepScroll(
                  child: _FeesStep(
                    feeMethod: _feeMethod,
                    pricePerSqm: _pricePerSqm,
                    typicalSqm: _typicalSqm,
                    fixedFee: _fixedFee,
                    billingDay: _billingDay,
                    apartmentCount: _floorPlan?.totalApartments ?? 0,
                    onMethod: (m) => setState(() => _feeMethod = m),
                    onPrice: (v) => setState(() => _pricePerSqm = v),
                    onTypical: (v) => setState(() => _typicalSqm = v),
                    onFixed: (v) => setState(() => _fixedFee = v),
                    onBillingDay: (d) => setState(() => _billingDay = d),
                  ),
                ),
                _StepScroll(
                  child: _MyApartmentStep(
                    plan: _floorPlan,
                    myApt: _myApt,
                    occupants: _occupants,
                    mySqm: _mySqm,
                    feeMethod: _feeMethod,
                    typicalSqm: _typicalSqm,
                    parkingSpots: _parkingSpots,
                    arnonaDoc: _arnonaDoc,
                    residenceDoc: _residenceDoc,
                    onParkingSpots: (spots) =>
                        setState(() => _parkingSpots = spots),
                    onArnona: (f) => setState(() => _arnonaDoc = f),
                    onResidence: (f) => setState(() => _residenceDoc = f),
                    onChanged: () => setState(() {}),
                  ),
                ),
                _StepScroll(
                  child: _ServicesStep(
                    services: _services,
                    expectedCollection: _expectedCollection,
                    onChanged: () => setState(() {}),
                    onSkip: _goNext,
                  ),
                ),
                _StepScroll(
                  child: _SummaryStep(
                    name: _name.text.trim(),
                    email: _email.text.trim(),
                    myApt: _myApt.text.trim(),
                    occupants: _occupants.text.trim(),
                    phone: context.read<SessionController>().user?.phoneNumber,
                    address: IsraelGovAddressFields.composeFullAddress(
                      street: _street.text,
                      houseNumber: _houseNumber.text,
                      city: _city.text,
                      district: _district.text,
                      country: _country.text,
                      postal: _postal.text,
                    ),
                    entranceCount: _entranceCount,
                    elevatorCount: _elevatorCount,
                    entrances: [
                      for (var i = 0; i < _entranceCount; i++)
                        (
                          name: _hebrewLetters[i],
                          code: _entranceCodes[i].text.trim(),
                        ),
                    ],
                    floorPlan: _floorPlan,
                    feeMethod: _feeMethod,
                    pricePerSqm: _pricePerSqm,
                    typicalSqm: _typicalSqm,
                    fixedFee: _fixedFee,
                    billingDay: _billingDay,
                    openingBalance: _openingBalance,
                    services: _services,
                    onEdit: _goToStep,
                    onBalanceChanged: () => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottom),
            decoration: BoxDecoration(
              color: DiraColors.creamCard,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: DiraColors.brick),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _busy || !_stepValid ? null : _goNext,
                  child: Text(_ctaLabel(l10n)),
                ),
                if (_step == 6) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _busy ? null : _goNext,
                    child: Text(
                      l10n.serviceSkipLater,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: DiraColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScroll extends StatelessWidget {
  final Widget child;
  const _StepScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [child],
    );
  }
}

// ─── Shared chrome ───────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final String text;

  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DiraColors.goldLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: DiraColors.goldDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: DiraColors.ink,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: DiraColors.inkSoft,
        ),
      ),
    );
  }
}

String _floorLabel(AppLocalizations l10n, int floor) {
  if (floor == 0) return l10n.floorBadgeGround;
  return l10n.floorBadge('$floor');
}

// ─── Step 0: You ─────────────────────────────────────────────────────────────

class _YouStep extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController email;
  final VoidCallback onChanged;

  const _YouStep({
    required this.name,
    required this.email,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phone = context.read<SessionController>().user?.phoneNumber;
    final phoneDisplay =
        phone == null || phone.isEmpty ? '—' : PhoneField.formatDisplay(phone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.createBuildingYouSubtitle,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: DiraColors.sagePale,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DiraColors.sageLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: DiraColors.sage),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.verifiedPhoneLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DiraColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phoneDisplay,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DiraColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _FieldLabel(l10n.fullName),
        TextField(
          controller: name,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(hintText: '…'),
        ),
        const SizedBox(height: 14),
        _FieldLabel(l10n.emailOptional),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(hintText: 'name@email.com'),
        ),
        const SizedBox(height: 16),
        _InfoBox(text: l10n.createBuildingYouAptLaterNote),
      ],
    );
  }
}

// ─── Step 2: Entrances & elevators ───────────────────────────────────────────

class _EntrancesStep extends StatelessWidget {
  final int entranceCount;
  final int elevatorCount;
  final List<TextEditingController> codes;
  final List<String> letters;
  final ValueChanged<int> onEntrances;
  final ValueChanged<int> onElevators;
  final VoidCallback onChanged;

  const _EntrancesStep({
    required this.entranceCount,
    required this.elevatorCount,
    required this.codes,
    required this.letters,
    required this.onEntrances,
    required this.onElevators,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.createBuildingEntrancesSubtitle,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StepperCard(
                label: l10n.entrancesCountLabel,
                value: entranceCount,
                onMinus: () => onEntrances((entranceCount - 1).clamp(1, 10)),
                onPlus: () => onEntrances((entranceCount + 1).clamp(1, 10)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StepperCard(
                label: l10n.elevatorsCountLabel,
                value: elevatorCount,
                highlighted: true,
                onMinus: () => onElevators((elevatorCount - 1).clamp(0, 20)),
                onPlus: () => onElevators((elevatorCount + 1).clamp(0, 20)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.entranceCodesTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: DiraColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < entranceCount; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: DiraColors.creamCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DiraColors.sagePale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    letters[i],
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: DiraColors.sageDeep,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: codes[i],
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      hintText: l10n.entranceCodeHint,
                      filled: true,
                      fillColor: DiraColors.creamDeep,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                          color: DiraColors.brick,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _InfoBox(text: l10n.entranceCodesPrivacyNote),
      ],
    );
  }
}

// ─── Step 3: Floors & apartments ─────────────────────────────────────────────

class _StructureStep extends StatefulWidget {
  final VoidCallback onChanged;
  final ValueChanged<BuildingFloorPlan?> onPlanChanged;
  final ValueChanged<bool> onValidChanged;

  const _StructureStep({
    required this.onChanged,
    required this.onPlanChanged,
    required this.onValidChanged,
  });

  @override
  State<_StructureStep> createState() => _StructureStepState();
}

class _StructureStepState extends State<_StructureStep>
    with AutomaticKeepAliveClientMixin {
  static const _maxFloors = 50;
  static const _maxTypical = 40;
  static const _maxPerFloor = 80;

  int _floorCount = 4;
  int _typical = 4;
  int _baseFloor = 1;
  int _firstApt = 1;
  final Map<int, int> _overrides = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  List<int> get _floors => BuildingFloorPlan.floorsFromBase(
        baseFloor: _baseFloor,
        floorCount: _floorCount,
      );

  int _countFor(int floor) => _overrides[floor] ?? _typical;

  int get _exceptionCount =>
      _floors.where((f) => _overrides.containsKey(f)).length;

  BuildingFloorPlan? _computePlan() {
    if (_floorCount < 1 || _typical < 1 || _baseFloor < 0 || _firstApt < 1) {
      return null;
    }
    final plan = BuildingFloorPlan.fromTypical(
      baseFloor: _baseFloor,
      floorCount: _floorCount,
      typical: _typical,
      overrides: Map.unmodifiable(_overrides),
      firstApartmentNumber: _firstApt,
    );
    return plan.buckets.isEmpty ? null : plan;
  }

  bool _isValid(BuildingFloorPlan? plan) {
    return plan != null && plan.totalApartments > 0;
  }

  void _emit() {
    _overrides.removeWhere(
      (f, c) => !_floors.contains(f) || c == _typical,
    );
    final plan = _computePlan();
    widget.onPlanChanged(plan);
    widget.onValidChanged(_isValid(plan));
    widget.onChanged();
    if (mounted) setState(() {});
  }

  void _setFloorCount(int v) {
    _floorCount = v.clamp(1, _maxFloors);
    _emit();
  }

  void _setTypical(int v) {
    _typical = v.clamp(1, _maxTypical);
    _emit();
  }

  void _setBaseFloor(int v) {
    _baseFloor = v.clamp(0, 100);
    _emit();
  }

  void _setFirstApt(int v) {
    _firstApt = v.clamp(1, 9999);
    _emit();
  }

  void _bumpFloor(int floor, int delta) {
    final next = (_countFor(floor) + delta).clamp(0, _maxPerFloor);
    if (next == _typical) {
      _overrides.remove(floor);
    } else {
      _overrides[floor] = next;
    }
    _emit();
  }

  void _resetFloor(int floor) {
    _overrides.remove(floor);
    _emit();
  }

  void _resetAllExceptions() {
    _overrides.clear();
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final plan = _computePlan();
    final total = plan?.totalApartments ?? 0;
    final lastFloor = _floors.isEmpty ? _baseFloor : _floors.last;
    final aptTo = total < 1 ? _firstApt : _firstApt + total - 1;
    final rows = <({int floor, int apartments, int from, int to})>[];
    var next = _firstApt;
    for (final f in _floors) {
      final c = _countFor(f);
      if (c <= 0) {
        rows.add((floor: f, apartments: 0, from: next, to: next));
      } else {
        rows.add((floor: f, apartments: c, from: next, to: next + c - 1));
        next += c;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.structureStepSubtitle,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StepperCard(
                label: l10n.numberOfFloors,
                value: _floorCount,
                onMinus: () => _setFloorCount(_floorCount - 1),
                onPlus: () => _setFloorCount(_floorCount + 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StepperCard(
                label: l10n.typicalFloorLabel,
                value: _typical,
                highlighted: true,
                onMinus: () => _setTypical(_typical - 1),
                onPlus: () => _setTypical(_typical + 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StepperCard(
                label: l10n.baseFloorLabel,
                value: _baseFloor,
                displayValue: _floorLabel(l10n, _baseFloor),
                onMinus: () => _setBaseFloor(_baseFloor - 1),
                onPlus: () => _setBaseFloor(_baseFloor + 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StepperCard(
                label: l10n.firstApartmentShortLabel,
                value: _firstApt,
                onMinus: () => _setFirstApt(_firstApt - 1),
                onPlus: () => _setFirstApt(_firstApt + 1),
              ),
            ),
          ],
        ),
        if (_floors.isNotEmpty && total > 0) ...[
          const SizedBox(height: 12),
          Text(
            l10n.floorsRangeSummary(
              _floorLabel(l10n, _baseFloor),
              _floorLabel(l10n, lastFloor),
              '$_firstApt',
              '$aptTo',
            ),
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: DiraColors.inkSoft,
            ),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.floorDivisionTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: DiraColors.ink,
                ),
              ),
            ),
            if (_exceptionCount > 0)
              TextButton(
                onPressed: _resetAllExceptions,
                style: TextButton.styleFrom(
                  foregroundColor: DiraColors.brick,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.resetExceptions('$_exceptionCount'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final row in rows) ...[
          _FloorMapCard(
            floor: row.floor,
            apartments: row.apartments,
            from: row.from,
            to: row.to,
            isException: _overrides.containsKey(row.floor),
            onMinus: () => _bumpFloor(row.floor, -1),
            onPlus: () => _bumpFloor(row.floor, 1),
            onReset: _overrides.containsKey(row.floor)
                ? () => _resetFloor(row.floor)
                : null,
          ),
          const SizedBox(height: 8),
        ],
        if (plan != null && total > 0) ...[
          const SizedBox(height: 8),
          _MappingSummaryCard(
            total: total,
            floors: _floorCount,
          ),
        ],
      ],
    );
  }
}

class _StepperCard extends StatelessWidget {
  final String label;
  final int value;
  final String? displayValue;
  final bool highlighted;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _StepperCard({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.displayValue,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: highlighted ? DiraColors.terracottaSoft : DiraColors.creamCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? DiraColors.terracottaBlush
              : DiraColors.creamDeep,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DiraColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundIconButton(
                icon: Icons.remove_rounded,
                onPressed: onMinus,
              ),
              Text(
                displayValue ?? '$value',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: DiraColors.ink,
                  height: 1,
                ),
              ),
              _RoundIconButton(
                icon: Icons.add_rounded,
                onPressed: onPlus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? foreground;

  const _RoundIconButton({
    required this.icon,
    this.onPressed,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? DiraColors.creamDeep,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: foreground ?? DiraColors.brickDark,
          ),
        ),
      ),
    );
  }
}

class _FloorMapCard extends StatelessWidget {
  final int floor;
  final int apartments;
  final int from;
  final int to;
  final bool isException;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback? onReset;

  const _FloorMapCard({
    required this.floor,
    required this.apartments,
    required this.from,
    required this.to,
    required this.isException,
    required this.onMinus,
    required this.onPlus,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isException ? const Color(0xFFF3E8D8) : DiraColors.creamCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DiraColors.creamDeep,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _floorLabel(l10n, floor),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: DiraColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.floorAptsCount('$apartments'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: DiraColors.ink,
                        ),
                      ),
                    ),
                    if (isException) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: DiraColors.goldLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.exceptionBadge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: DiraColors.goldDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  apartments > 0 ? l10n.floorAptsRange('$from', '$to') : '—',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: DiraColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (onReset != null) ...[
            _RoundIconButton(
              icon: Icons.refresh_rounded,
              onPressed: onReset,
              background: DiraColors.creamCard,
            ),
            const SizedBox(width: 6),
          ],
          _RoundIconButton(
            icon: Icons.remove_rounded,
            onPressed: onMinus,
            background: DiraColors.creamCard,
          ),
          const SizedBox(width: 6),
          _RoundIconButton(
            icon: Icons.add_rounded,
            onPressed: onPlus,
            background: DiraColors.creamCard,
          ),
        ],
      ),
    );
  }
}

class _MappingSummaryCard extends StatelessWidget {
  final int total;
  final int floors;

  const _MappingSummaryCard({
    required this.total,
    required this.floors,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mappingTotalLabel,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: DiraColors.inkSoft,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$total',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: DiraColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.mappingTotalMeta('$total', '$floors'),
            style: const TextStyle(
              fontSize: 12.5,
              color: DiraColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dedicated step: Vaad sets their unit like a tenant (number, occupants, docs).
class _MyApartmentStep extends StatelessWidget {
  final BuildingFloorPlan? plan;
  final TextEditingController myApt;
  final TextEditingController occupants;
  final TextEditingController mySqm;
  final String feeMethod;
  final double typicalSqm;
  final List<String> parkingSpots;
  final PlatformFile? arnonaDoc;
  final PlatformFile? residenceDoc;
  final ValueChanged<List<String>> onParkingSpots;
  final ValueChanged<PlatformFile?> onArnona;
  final ValueChanged<PlatformFile?> onResidence;
  final VoidCallback onChanged;

  const _MyApartmentStep({
    required this.plan,
    required this.myApt,
    required this.occupants,
    required this.mySqm,
    required this.feeMethod,
    required this.typicalSqm,
    required this.parkingSpots,
    required this.arnonaDoc,
    required this.residenceDoc,
    required this.onParkingSpots,
    required this.onArnona,
    required this.onResidence,
    required this.onChanged,
  });

  bool get _perSqm => feeMethod == 'per_sqm';

  Future<void> _pickDoc(ValueChanged<PlatformFile?> assign) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final file = result.firstOrNull;
    if (file != null) assign(file);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final from = plan?.firstNumber;
    final to = plan?.lastNumber;
    final apt = int.tryParse(myApt.text.trim());
    final ok = plan != null && apt != null && plan!.containsApartment(apt);
    final floor = apt != null ? plan?.floorForApartment(apt) : null;
    final rangeHint = (from != null && to != null)
        ? l10n.vaadAptRangeHint('$from', '$to')
        : null;
    final typicalHint = typicalSqm == typicalSqm.roundToDouble()
        ? '${typicalSqm.toInt()}'
        : typicalSqm.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.createBuildingMyAptSubtitle,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 16),
        _FieldLabel(l10n.yourApartmentNumber),
        TextField(
          controller: myApt,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: from != null ? '$from' : '…',
            helperText: rangeHint,
            errorText: myApt.text.trim().isEmpty
                ? null
                : (ok ? null : l10n.vaadAptOutOfPlan),
            suffixIcon: ok
                ? const Icon(Icons.check_circle, color: DiraColors.sage)
                : null,
          ),
        ),
        if (floor != null) ...[
          const SizedBox(height: 8),
          Text(
            '${l10n.floorLabel}: $floor',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DiraColors.inkSoft,
            ),
          ),
        ],
        const SizedBox(height: 14),
        _FieldLabel(l10n.numOccupantsLabel),
        TextField(
          controller: occupants,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(hintText: '1'),
        ),
        const SizedBox(height: 14),
        ParkingSpotsField(
          initialSpots: parkingSpots,
          onChanged: onParkingSpots,
        ),
        if (_perSqm) ...[
          const SizedBox(height: 14),
          _FieldLabel(l10n.apartmentSizeSqm),
          TextField(
            controller: mySqm,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: typicalHint,
              helperText: l10n.vaadAptSqmHint(typicalHint),
              suffixText: l10n.sqmUnit,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          l10n.docsSection,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: DiraColors.brickDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.docsExplain,
          style: const TextStyle(
            color: DiraColors.inkSoft,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _OnboardingDocButton(
          file: arnonaDoc,
          label: l10n.attachArnona,
          hint: l10n.arnonaHint,
          onPick: () => _pickDoc(onArnona),
        ),
        const SizedBox(height: 10),
        _OnboardingDocButton(
          file: residenceDoc,
          label: l10n.attachResidence,
          hint: l10n.residenceHint,
          onPick: () => _pickDoc(onResidence),
        ),
      ],
    );
  }
}

class _OnboardingDocButton extends StatelessWidget {
  final PlatformFile? file;
  final String label;
  final String hint;
  final VoidCallback onPick;

  const _OnboardingDocButton({
    required this.file,
    required this.label,
    required this.hint,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final picked = file != null;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: picked ? DiraColors.sagePale : DiraColors.creamCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: picked ? DiraColors.sageDark : DiraColors.brick,
            width: picked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              picked ? Icons.check_circle : Icons.upload_file_rounded,
              color: picked ? DiraColors.sageDark : DiraColors.brick,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label (${context.l10n.optional})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: picked ? DiraColors.sageDark : DiraColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    picked ? file!.name : hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DiraColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 4: Fees ────────────────────────────────────────────────────────────

class _FeesStep extends StatefulWidget {
  final String feeMethod;
  final double pricePerSqm;
  final double typicalSqm;
  final double fixedFee;
  final int billingDay;
  final int apartmentCount;
  final ValueChanged<String> onMethod;
  final ValueChanged<double> onPrice;
  final ValueChanged<double> onTypical;
  final ValueChanged<double> onFixed;
  final ValueChanged<int> onBillingDay;

  const _FeesStep({
    required this.feeMethod,
    required this.pricePerSqm,
    required this.typicalSqm,
    required this.fixedFee,
    required this.billingDay,
    required this.apartmentCount,
    required this.onMethod,
    required this.onPrice,
    required this.onTypical,
    required this.onFixed,
    required this.onBillingDay,
  });

  @override
  State<_FeesStep> createState() => _FeesStepState();
}

class _FeesStepState extends State<_FeesStep> {
  static const _priceChips = [6.0, 7.5, 8.5, 11.0];
  static const _fixedChips = [350.0, 480.0, 620.0, 850.0];
  static const _previewSizes = [62.0, null, 124.0]; // null = typical
  static const _billingDays = [1, 5, 10, 15];

  late final TextEditingController _priceCtrl;
  late final TextEditingController _typicalCtrl;
  late final TextEditingController _fixedCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: _fmtEditable(widget.pricePerSqm));
    _typicalCtrl = TextEditingController(text: _fmtEditable(widget.typicalSqm));
    _fixedCtrl = TextEditingController(text: _fmtEditable(widget.fixedFee));
  }

  @override
  void didUpdateWidget(covariant _FeesStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCtrl(_priceCtrl, widget.pricePerSqm, oldWidget.pricePerSqm);
    _syncCtrl(_typicalCtrl, widget.typicalSqm, oldWidget.typicalSqm);
    _syncCtrl(_fixedCtrl, widget.fixedFee, oldWidget.fixedFee);
  }

  void _syncCtrl(TextEditingController c, double next, double prev) {
    if ((next - prev).abs() < 0.001) return;
    final parsed = double.tryParse(c.text.replaceAll(',', '.'));
    if (parsed != null && (parsed - next).abs() < 0.001) return;
    c.text = _fmtEditable(next);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _typicalCtrl.dispose();
    _fixedCtrl.dispose();
    super.dispose();
  }

  String _fmtEditable(double v) {
    if (v == v.roundToDouble()) return '${v.toInt()}';
    return v.toStringAsFixed(1);
  }

  String _fmtMoney(double v) {
    if (v == v.roundToDouble()) return '₪${v.toInt()}';
    return '₪${v.toStringAsFixed(1)}';
  }

  double? _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.').replaceAll('₪', ''));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final feeMethod = widget.feeMethod;
    final pricePerSqm = widget.pricePerSqm;
    final typicalSqm = widget.typicalSqm;
    final fixedFee = widget.fixedFee;
    final expected = feeMethod == 'fixed'
        ? fixedFee * widget.apartmentCount
        : pricePerSqm * typicalSqm * widget.apartmentCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.createBuildingFeesSubtitle,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'per_sqm', label: Text(l10n.feePerSqm)),
            ButtonSegment(value: 'fixed', label: Text(l10n.feeFixed)),
          ],
          selected: {feeMethod},
          onSelectionChanged: (s) => widget.onMethod(s.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: DiraColors.sage,
            selectedForegroundColor: DiraColors.creamCard,
          ),
        ),
        const SizedBox(height: 16),
        if (feeMethod == 'per_sqm') ...[
          _FeeAmountCard(
            label: l10n.pricePerSqmLabel,
            controller: _priceCtrl,
            suffix: '/${l10n.sqmUnit}',
            onMinus: () =>
                widget.onPrice((pricePerSqm - 0.5).clamp(0.5, 100)),
            onPlus: () =>
                widget.onPrice((pricePerSqm + 0.5).clamp(0.5, 100)),
            onEdited: (v) {
              if (v == null) return;
              widget.onPrice(v.clamp(0.5, 100));
            },
            chips: [
              for (final chip in _priceChips)
                (
                  label: _fmtMoney(chip),
                  selected: (pricePerSqm - chip).abs() < 0.01,
                  onTap: () => widget.onPrice(chip),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: DiraColors.creamCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  l10n.typicalApartmentSqmLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DiraColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.remove_rounded,
                      onPressed: () =>
                          widget.onTypical((typicalSqm - 1).clamp(20, 500)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _typicalCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: DiraColors.ink,
                          height: 1,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        onChanged: (raw) {
                          final v = _parse(raw);
                          if (v != null) {
                            widget.onTypical(v.clamp(20, 500));
                          }
                        },
                      ),
                    ),
                    _RoundIconButton(
                      icon: Icons.add_rounded,
                      onPressed: () =>
                          widget.onTypical((typicalSqm + 1).clamp(20, 500)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final size in _previewSizes) ...[
            _FeePreviewRow(
              label: size == null
                  ? l10n.feePreviewTypical(
                      typicalSqm == typicalSqm.roundToDouble()
                          ? '${typicalSqm.toInt()}'
                          : typicalSqm.toStringAsFixed(0),
                    )
                  : l10n.feePreviewSize(
                      size == size.roundToDouble()
                          ? '${size.toInt()}'
                          : size.toStringAsFixed(0),
                    ),
              amount: _fmtMoney(pricePerSqm * (size ?? typicalSqm)),
              emphasized: size == null,
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 8),
          _InfoBox(text: l10n.feeTemporaryNote),
        ] else ...[
          _FeeAmountCard(
            label: l10n.feeFixedMonthlyLabel,
            controller: _fixedCtrl,
            suffix: l10n.feePerApartmentUnit,
            prefixShekel: true,
            onMinus: () =>
                widget.onFixed((fixedFee - 10).clamp(10, 5000)),
            onPlus: () =>
                widget.onFixed((fixedFee + 10).clamp(10, 5000)),
            onEdited: (v) {
              if (v == null) return;
              widget.onFixed(v.clamp(10, 5000));
            },
            chips: [
              for (final chip in _fixedChips)
                (
                  label: _fmtMoney(chip),
                  selected: (fixedFee - chip).abs() < 0.01,
                  onTap: () => widget.onFixed(chip),
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Text(
          l10n.billingDayLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _billingDays)
              _QuickChip(
                label: '$d',
                selected: widget.billingDay == d,
                onTap: () => widget.onBillingDay(d),
              ),
          ],
        ),
        if (widget.apartmentCount > 0) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DiraColors.creamCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DiraColors.sageLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.expectedMonthlyCollection,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: DiraColors.inkSoft,
                    ),
                  ),
                ),
                Text(
                  _fmtMoney(expected),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DiraColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Dark sage amount card: editable value + ± + optional quick chips.
class _FeeAmountCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? suffix;
  final bool prefixShekel;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<double?> onEdited;
  final List<({String label, bool selected, VoidCallback onTap})> chips;

  const _FeeAmountCard({
    required this.label,
    required this.controller,
    required this.onMinus,
    required this.onPlus,
    required this.onEdited,
    required this.chips,
    this.suffix,
    this.prefixShekel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: DiraColors.sageDeep,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DiraColors.goldLight.withValues(alpha: 0.95),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.remove_rounded,
                background: DiraColors.sageDark,
                foreground: DiraColors.creamCard,
                onPressed: onMinus,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (prefixShekel)
                      const Text(
                        '₪',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: DiraColors.creamCard,
                        ),
                      ),
                    Flexible(
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: DiraColors.creamCard,
                          height: 1,
                        ),
                        cursorColor: DiraColors.creamCard,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        onChanged: (raw) {
                          final v = double.tryParse(
                            raw.trim().replaceAll(',', '.'),
                          );
                          onEdited(v);
                        },
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        suffix!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DiraColors.creamCard.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _RoundIconButton(
                icon: Icons.add_rounded,
                background: DiraColors.sageDark,
                foreground: DiraColors.creamCard,
                onPressed: onPlus,
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final chip in chips)
                  _QuickChip(
                    label: chip.label,
                    selected: chip.selected,
                    dark: true,
                    onTap: chip.onTap,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? (dark ? DiraColors.creamCard : DiraColors.sage)
        : (dark ? DiraColors.sageDark : DiraColors.creamCard);
    final fg = selected
        ? (dark ? DiraColors.sageDeep : DiraColors.creamCard)
        : (dark ? DiraColors.creamCard : DiraColors.ink);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: dark
                ? null
                : Border.all(
                    color: selected ? DiraColors.sage : DiraColors.creamDeep,
                  ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeePreviewRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool emphasized;

  const _FeePreviewRow({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: emphasized ? DiraColors.terracottaSoft : DiraColors.creamCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                color: DiraColors.ink,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: emphasized ? DiraColors.brickDark : DiraColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 5: Regular services ────────────────────────────────────────────────

class _ServiceDraft {
  final String eventType;
  final bool isCustom;
  bool enabled;
  String recurrence;
  List<int> daysOfWeek;
  int dayOfMonth;
  final TextEditingController costCtrl;
  final TextEditingController providerCtrl;
  final TextEditingController titleCtrl;

  _ServiceDraft({
    required this.eventType,
    required this.enabled,
    required this.recurrence,
    required this.daysOfWeek,
    this.dayOfMonth = 1,
    this.isCustom = false,
    String? cost,
    String? provider,
    String? title,
  })  : costCtrl = TextEditingController(text: cost ?? ''),
        providerCtrl = TextEditingController(text: provider ?? ''),
        titleCtrl = TextEditingController(text: title ?? '');

  void dispose() {
    costCtrl.dispose();
    providerCtrl.dispose();
    titleCtrl.dispose();
  }

  String resolvedTitle(AppLocalizations l10n) {
    if (isCustom || eventType == 'other') return titleCtrl.text;
    return switch (eventType) {
      'cleaning' => l10n.serviceCleaningStairs,
      'garbage' => l10n.serviceGarbage,
      'gardening' => l10n.serviceGardening,
      'pest' => l10n.servicePest,
      'water_tank' => l10n.serviceWaterTank,
      _ => titleCtrl.text,
    };
  }

  double? get parsedCost {
    final raw = costCtrl.text.trim().replaceAll(',', '.').replaceAll('₪', '');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  static List<_ServiceDraft> presets() => [
        _ServiceDraft(
          eventType: 'cleaning',
          enabled: true,
          recurrence: 'weekly',
          daysOfWeek: [2],
          cost: '3200',
        ),
        _ServiceDraft(
          eventType: 'garbage',
          enabled: true,
          recurrence: 'weekly',
          daysOfWeek: [0, 3],
        ),
        _ServiceDraft(
          eventType: 'gardening',
          enabled: false,
          recurrence: 'biweekly',
          daysOfWeek: [1],
          cost: '1850',
        ),
        _ServiceDraft(
          eventType: 'pest',
          enabled: false,
          recurrence: 'quarterly',
          daysOfWeek: const [],
          dayOfMonth: 1,
        ),
        _ServiceDraft(
          eventType: 'water_tank',
          enabled: false,
          recurrence: 'yearly',
          daysOfWeek: const [],
          dayOfMonth: 1,
        ),
      ];

  static _ServiceDraft custom() => _ServiceDraft(
        eventType: 'other',
        enabled: true,
        isCustom: true,
        recurrence: 'monthly',
        daysOfWeek: const [],
        dayOfMonth: 1,
      );

  void applyEnableDefaults() {
    if (eventType == 'gardening') {
      recurrence = 'biweekly';
      daysOfWeek = [1];
      if (costCtrl.text.trim().isEmpty) costCtrl.text = '1850';
    } else if (eventType == 'pest') {
      recurrence = 'quarterly';
      dayOfMonth = 1;
      daysOfWeek = [];
    } else if (eventType == 'water_tank') {
      recurrence = 'yearly';
      dayOfMonth = 1;
      daysOfWeek = [];
    }
  }
}

class _ServicesStep extends StatelessWidget {
  final List<_ServiceDraft> services;
  final double expectedCollection;
  final VoidCallback onChanged;
  final VoidCallback onSkip;

  const _ServicesStep({
    required this.services,
    required this.expectedCollection,
    required this.onChanged,
    required this.onSkip,
  });

  String _fmtMoney(double v) {
    if (v == v.roundToDouble()) return '${v.toInt()}';
    return v.toStringAsFixed(0);
  }

  double get _expenseSum {
    var sum = 0.0;
    for (final s in services) {
      if (!s.enabled) continue;
      final c = s.parsedCost;
      if (c != null && c > 0) sum += c;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expense = _expenseSum;
    final remaining = expectedCollection - expense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.createBuildingServicesSubtitle,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < services.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _ServiceCard(
            draft: services[i],
            onChanged: onChanged,
            onRemove: services[i].isCustom
                ? () {
                    final removed = services.removeAt(i);
                    removed.dispose();
                    onChanged();
                  }
                : null,
          ),
        ],
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () {
            services.add(_ServiceDraft.custom());
            onChanged();
          },
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(l10n.serviceAddCustom),
          style: OutlinedButton.styleFrom(
            foregroundColor: DiraColors.brickDark,
            side: const BorderSide(color: DiraColors.terracottaBlush),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DiraColors.creamCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DiraColors.sageLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.serviceEstimatedMonthly(_fmtMoney(expense)),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DiraColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              if (expectedCollection > 0) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.serviceBalanceAfterFees(_fmtMoney(remaining)),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: remaining >= 0
                        ? DiraColors.sageDeep
                        : DiraColors.brickDark,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _InfoBox(text: l10n.serviceCalendarNote),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onSkip,
          child: Text(
            l10n.serviceSkipLater,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: DiraColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final _ServiceDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _ServiceCard({
    required this.draft,
    required this.onChanged,
    this.onRemove,
  });

  static const _frequencies = [
    'weekly',
    'biweekly',
    'monthly',
    'quarterly',
    'yearly',
  ];

  String _freqLabel(AppLocalizations l10n, String r) => switch (r) {
        'weekly' => l10n.serviceFrequencyWeekly,
        'biweekly' => l10n.serviceFrequencyBiweekly,
        'monthly' => l10n.serviceFrequencyMonthly,
        'quarterly' => l10n.serviceFrequencyQuarterly,
        'yearly' => l10n.serviceFrequencyYearly,
        _ => r,
      };

  String _dayLetter(AppLocalizations l10n, int d) => switch (d) {
        0 => l10n.serviceDaySun,
        1 => l10n.serviceDayMon,
        2 => l10n.serviceDayTue,
        3 => l10n.serviceDayWed,
        4 => l10n.serviceDayThu,
        5 => l10n.serviceDayFri,
        6 => l10n.serviceDaySat,
        _ => '',
      };

  bool get _usesWeekdays =>
      draft.recurrence == 'weekly' || draft.recurrence == 'biweekly';

  String _summaryLine(AppLocalizations l10n) {
    final parts = <String>[_freqLabel(l10n, draft.recurrence)];
    if (_usesWeekdays && draft.daysOfWeek.isNotEmpty) {
      final days = [...draft.daysOfWeek]..sort();
      parts.add(days.map((d) => _dayLetter(l10n, d)).join(''));
    } else if (!_usesWeekdays) {
      parts.add('${draft.dayOfMonth}');
    }
    final cost = draft.parsedCost;
    if (cost != null && cost > 0) {
      parts.add(
        cost == cost.roundToDouble()
            ? '₪${cost.toInt()}'
            : '₪${cost.toStringAsFixed(0)}',
      );
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = draft.enabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: enabled ? DiraColors.creamCard : DiraColors.creamDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled ? DiraColors.sageLight : DiraColors.creamDeep,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (draft.isCustom)
                      TextField(
                        controller: draft.titleCtrl,
                        onChanged: (_) => onChanged(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: DiraColors.ink,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: l10n.serviceCustomTitle,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    else
                      Text(
                        draft.resolvedTitle(l10n),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: DiraColors.ink,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? _summaryLine(l10n) : l10n.serviceOffHint,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: DiraColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRemove != null) ...[
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: DiraColors.inkSoft,
                  visualDensity: VisualDensity.compact,
                ),
              ],
              Switch.adaptive(
                value: enabled,
                activeThumbColor: DiraColors.creamCard,
                activeTrackColor: DiraColors.sage,
                onChanged: (v) {
                  draft.enabled = v;
                  if (v) draft.applyEnableDefaults();
                  onChanged();
                },
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _frequencies)
                  _QuickChip(
                    label: _freqLabel(l10n, f),
                    selected: draft.recurrence == f,
                    onTap: () {
                      draft.recurrence = f;
                      if (f == 'weekly' || f == 'biweekly') {
                        if (draft.daysOfWeek.isEmpty) {
                          draft.daysOfWeek = [1];
                        }
                      }
                      onChanged();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_usesWeekdays)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var d = 0; d < 7; d++)
                    _DayCircle(
                      label: _dayLetter(l10n, d),
                      selected: draft.daysOfWeek.contains(d),
                      onTap: () {
                        if (draft.daysOfWeek.contains(d)) {
                          if (draft.daysOfWeek.length > 1) {
                            draft.daysOfWeek = [
                              for (final x in draft.daysOfWeek)
                                if (x != d) x,
                            ];
                          }
                        } else {
                          draft.daysOfWeek = [...draft.daysOfWeek, d]..sort();
                        }
                        onChanged();
                      },
                    ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.serviceDayOfMonth,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DiraColors.inkSoft,
                      ),
                    ),
                  ),
                  _RoundIconButton(
                    icon: Icons.remove_rounded,
                    onPressed: () {
                      draft.dayOfMonth = (draft.dayOfMonth - 1).clamp(1, 28);
                      onChanged();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${draft.dayOfMonth}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: DiraColors.ink,
                      ),
                    ),
                  ),
                  _RoundIconButton(
                    icon: Icons.add_rounded,
                    onPressed: () {
                      draft.dayOfMonth = (draft.dayOfMonth + 1).clamp(1, 28);
                      onChanged();
                    },
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => onChanged(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      hintText: l10n.serviceCostHint,
                      filled: true,
                      fillColor: DiraColors.creamDeep,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: draft.providerCtrl,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      hintText: l10n.serviceProviderHint,
                      filled: true,
                      fillColor: DiraColors.creamDeep,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayCircle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DiraColors.sage : DiraColors.creamDeep,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: selected ? DiraColors.creamCard : DiraColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Step 6: Summary ─────────────────────────────────────────────────────────

class _SummaryStep extends StatelessWidget {
  final String name;
  final String email;
  final String myApt;
  final String occupants;
  final String? phone;
  final String address;
  final int entranceCount;
  final int elevatorCount;
  final List<({String name, String code})> entrances;
  final BuildingFloorPlan? floorPlan;
  final String feeMethod;
  final double pricePerSqm;
  final double typicalSqm;
  final double fixedFee;
  final int billingDay;
  final TextEditingController openingBalance;
  final List<_ServiceDraft> services;
  final ValueChanged<int> onEdit;
  final VoidCallback onBalanceChanged;

  const _SummaryStep({
    required this.name,
    required this.email,
    required this.myApt,
    required this.occupants,
    required this.phone,
    required this.address,
    required this.entranceCount,
    required this.elevatorCount,
    required this.entrances,
    required this.floorPlan,
    required this.feeMethod,
    required this.pricePerSqm,
    required this.typicalSqm,
    required this.fixedFee,
    required this.billingDay,
    required this.openingBalance,
    required this.services,
    required this.onEdit,
    required this.onBalanceChanged,
  });

  String _fmtMoney(double v) {
    if (v == v.roundToDouble()) return '₪${v.toInt()}';
    return '₪${v.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phoneDisplay = phone == null || phone!.isEmpty
        ? '—'
        : PhoneField.formatDisplay(phone!);
    final aptTotal = floorPlan?.totalApartments ?? 0;
    final floorCount = floorPlan?.floorCount ?? 0;

    final entranceLines = entrances
        .map((e) => e.code.isEmpty ? e.name : '${e.name}: ${e.code}')
        .join(' · ');

    final feeLine = feeMethod == 'fixed'
        ? '${l10n.feeFixed}: ${_fmtMoney(fixedFee)}'
        : '${l10n.feePerSqm}: ${_fmtMoney(pricePerSqm)}/${l10n.sqmUnit} · '
            '${typicalSqm == typicalSqm.roundToDouble() ? typicalSqm.toInt() : typicalSqm} '
            '${l10n.sqmUnit}';

    final enabledServices = [
      for (final s in services)
        if (s.enabled && s.resolvedTitle(l10n).trim().length >= 2)
          s.resolvedTitle(l10n).trim(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.createBuildingSummarySubtitle,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          title: l10n.summaryContactTitle,
          lines: [
            name,
            phoneDisplay,
            if (email.isNotEmpty) email,
          ],
          onEdit: () => onEdit(0),
        ),
        const SizedBox(height: 10),
        _SummaryCard(
          title: l10n.summaryAddressTitle,
          lines: [address],
          onEdit: () => onEdit(1),
        ),
        const SizedBox(height: 10),
        _SummaryCard(
          title: l10n.summaryBuildingTitle,
          lines: [
            l10n.summaryEntrancesLine('$entranceCount', '$elevatorCount'),
            if (entranceLines.isNotEmpty) entranceLines,
          ],
          onEdit: () => onEdit(2),
        ),
        const SizedBox(height: 10),
        _SummaryCard(
          title: l10n.summaryFloorsTitle,
          lines: [
            l10n.mappingTotalMeta('$aptTotal', '$floorCount'),
          ],
          onEdit: () => onEdit(3),
        ),
        const SizedBox(height: 10),
        _SummaryCard(
          title: l10n.summaryFeesTitle,
          lines: [
            feeLine,
            l10n.billingDaySummary('$billingDay'),
          ],
          onEdit: () => onEdit(4),
        ),
        const SizedBox(height: 10),
        _SummaryCard(
          title: l10n.createBuildingStepMyApartment,
          lines: [
            l10n.apartmentLabel(myApt),
            if (occupants.isNotEmpty) l10n.occupantsN(occupants),
          ],
          onEdit: () => onEdit(5),
        ),
        const SizedBox(height: 10),
        _SummaryCard(
          title: l10n.summaryServicesTitle,
          lines: [
            if (enabledServices.isEmpty)
              l10n.summaryServicesNone
            else
              enabledServices.join(' · '),
          ],
          onEdit: () => onEdit(6),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.openingBalanceTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: DiraColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.openingBalanceBody,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 12),
        _FieldLabel(l10n.openingBalanceLabel),
        TextField(
          controller: openingBalance,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onBalanceChanged(),
          decoration: InputDecoration(
            prefixText: '₪ ',
            helperText: l10n.openingBalanceHint,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final VoidCallback onEdit;

  const _SummaryCard({
    required this.title,
    required this.lines,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: DiraColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                for (final line in lines)
                  if (line.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          color: DiraColors.inkSoft,
                        ),
                      ),
                    ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: DiraColors.brick,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.edit,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Success dialog ──────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final String joinLink;
  final String buildingName;
  const _SuccessDialog({required this.joinLink, required this.buildingName});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: DiraColors.creamCard,
            title: Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: DiraColors.sageLight,
                  child: Icon(
                    Icons.check_rounded,
                    size: 34,
                    color: DiraColors.sageDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.buildingCreated,
                  textAlign: TextAlign.center,
                  style: heading(fontSize: 20),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.shareJoinLink,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: DiraColors.inkSoft),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: joinLink));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.joinLinkCopied)),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DiraColors.creamDeep,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            joinLink,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.copy,
                          size: 16,
                          color: DiraColors.inkSoft,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                  ),
                  onPressed: () {
                    final text = context.l10n.shareJoinMessage(
                      buildingName,
                      joinLink,
                    );
                    launchUrl(
                      Uri.parse(
                        'https://wa.me/?text=${Uri.encodeComponent(text)}',
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: Text(l10n.shareOnWhatsapp),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
