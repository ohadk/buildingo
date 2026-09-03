import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/status_pill.dart';
import '../widgets/vault_file_viewer.dart';

enum _UnpaidReceiptAction { view, markPaid }

/// Finances tab: two sub-tabs — the payment matrix (or the tenant's own
/// dues) and the building expense ledger.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _payments = [];
  List<Expense> _expenses = [];
  List<DirectoryEntry> _apartments = [];
  /// Building-wide paid dues (from /api/expenses summary).
  double _buildingIncome = 0;
  double _buildingExpensesTotal = 0;
  double _openingBalance = 0;
  bool _loading = true;

  /// Matrix filters: year (default current), half-year window so all
  /// six month columns fit on screen, and an apartment filter.
  int _year = DateTime.now().year;

  /// Expense-ledger filters: default to the current month; 0 = whole year.
  int _expYear = DateTime.now().year;
  int _expMonth = DateTime.now().month;
  int _half = DateTime.now().month <= 6 ? 0 : 1;
  bool _onlyWithDebt = false;
  String _query = '';

  /// Floor collapse state; unset floors default to "expanded when the
  /// floor has debt".
  final Map<int, bool> _expandedOverride = {};
  StreamSubscription<String>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _load();
    _realtimeSub = realtime.listen({'payments', 'expenses'}, _load);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final isVaad = context.read<SessionController>().user?.isVaad ?? false;
    try {
      final futures = <Future<Map<String, dynamic>>>[
        api.get('/api/payments'),
        api.get('/api/expenses'),
        if (isVaad) api.get('/api/directory'),
      ];
      final results = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _payments = ((results[0]['payments'] ?? []) as List)
            .map((p) => Payment.fromJson(p))
            .toList();
        _expenses = ((results[1]['expenses'] ?? []) as List)
            .map((e) => Expense.fromJson(e))
            .toList();
        final summary = results[1]['summary'] as Map<String, dynamic>?;
        _openingBalance =
            (summary?['openingBalance'] as num?)?.toDouble() ?? 0;
        _buildingIncome =
            (summary?['totalIncome'] as num?)?.toDouble() ??
            _payments
                .where((p) => p.status == 'paid')
                .fold(0.0, (s, p) => s + p.amount);
        _buildingExpensesTotal =
            (summary?['totalExpenses'] as num?)?.toDouble() ??
            _expenses.fold(0.0, (s, e) => s + e.amount);
        if (isVaad) {
          _apartments =
              ((results[2]['directory'] ?? []) as List)
                  .map((e) => DirectoryEntry.fromJson(e))
                  .toList()
                ..sort(
                  (a, b) => a.apartmentNumber.compareTo(b.apartmentNumber),
                );
        }
        _loading = false;
      });
      if (isVaad) await _ensureCurrentMonthDues();
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Silently open this calendar month for every apartment (pending / unpaid).
  /// Replaces the old manual "יצירת חיובי החודש" action.
  Future<void> _ensureCurrentMonthDues() async {
    if (!mounted || _apartments.isEmpty) return;
    final now = DateTime.now();
    final index = _cellIndex;
    final missing = _apartments.any(
      (a) => index[_cellKey(a.apartmentId, now.year, now.month)] == null,
    );
    if (!missing) return;
    try {
      final res = await api.post('/api/payments', {
        'month': now.month,
        'year': now.year,
      });
      final created = (res['created'] as num?)?.toInt() ?? 0;
      if (created < 1 || !mounted) return;
      final pay = await api.get('/api/payments');
      if (!mounted) return;
      setState(() {
        _payments = ((pay['payments'] ?? []) as List)
            .map((p) => Payment.fromJson(p))
            .toList();
      });
    } on ApiException {
      // Non-fatal — marking a cell can still create a row on demand.
    }
  }

  // ------------------------------------------------------------------
  // Matrix data helpers
  // ------------------------------------------------------------------

  List<DateTime> get _months =>
      List.generate(6, (i) => DateTime(_year, _half * 6 + i + 1));

  List<int> get _years {
    final now = DateTime.now();
    final years = <int>{
      now.year,
      now.year + 1,
      ..._payments.map((p) => p.year),
    };
    return years.toList()..sort();
  }

  /// Whether an unpaid row already counts as debt (due date reached).
  bool _isDue(Payment p) {
    final now = DateTime.now();
    return p.year < now.year || (p.year == now.year && p.month <= now.month);
  }

  /// All-time open debt for one apartment.
  double _debtOf(String apartmentId) => _payments
      .where(
        (p) => p.apartmentId == apartmentId && p.status != 'paid' && _isDue(p),
      )
      .fold(0.0, (s, p) => s + p.amount);

  String _cellKey(String apartmentId, int year, int month) =>
      '$apartmentId|$year-$month';

  bool _apartmentMatchesQuery(DirectoryEntry a, String q) {
    if (q.isEmpty) return true;
    if ('${a.apartmentNumber}' == q || '${a.apartmentNumber}'.contains(q)) {
      return true;
    }
    final parking = a.parkingSpot?.toLowerCase();
    if (parking != null && parking.contains(q)) return true;
    return a.residents.any(
      (r) =>
          r.name.toLowerCase().contains(q) ||
          r.phone.toLowerCase().contains(q),
    );
  }

  List<DirectoryEntry> _visibleApartments(Map<String, double> debts) {
    final q = _query.trim().toLowerCase();
    return [
      for (final a in _apartments)
        if (_apartmentMatchesQuery(a, q))
          if (!_onlyWithDebt || (debts[a.apartmentId] ?? 0) > 0) a,
    ];
  }

  Map<String, Payment> get _cellIndex => {
    for (final p in _payments)
      if (p.apartmentId != null) _cellKey(p.apartmentId!, p.year, p.month): p,
  };

  void _replaceCell(String apartmentId, DateTime month, Payment? replacement) {
    _payments.removeWhere(
      (p) =>
          p.apartmentId == apartmentId &&
          p.year == month.year &&
          p.month == month.month,
    );
    if (replacement != null) _payments.add(replacement);
  }

  /// Optimistic toggle: flip the cell instantly, sync with the server in
  /// the background and roll back (with an error message) on failure.
  /// Unmarking paid → unpaid asks for confirmation (and receipt keep/remove).
  Future<void> _toggleCell(DirectoryEntry apt, DateTime month) async {
    final previous =
        _cellIndex[_cellKey(apt.apartmentId, month.year, month.month)];
    final currentlyPaid = previous?.status == 'paid';

    // Unpaid month that still has a receipt: choose view vs mark paid.
    if (!currentlyPaid && (previous?.hasReceipt ?? false)) {
      final action = await _unpaidReceiptActions(previous!);
      if (action == _UnpaidReceiptAction.view) {
        await _openPaymentReceipt(previous);
      } else if (action == _UnpaidReceiptAction.markPaid) {
        await _applyPaymentStatus(apt, month, previous, status: 'paid');
      }
      return;
    }

    if (currentlyPaid) {
      final decision = await _confirmUnmarkPayment(apt, month, previous!);
      if (decision == null) return;
      await _applyPaymentStatus(
        apt,
        month,
        previous,
        status: 'pending',
        clearReceipt: decision.removeReceipt,
      );
      return;
    }

    await _applyPaymentStatus(apt, month, previous, status: 'paid');
  }

  String _apartmentWhoLabel(DirectoryEntry apt) {
    final names = apt.residents
        .map((r) => r.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isNotEmpty) return names.join(', ');
    return context.l10n.apartmentShort('${apt.apartmentNumber}');
  }

  /// Returns null if cancelled; otherwise whether to remove the receipt.
  Future<({bool removeReceipt})?> _confirmUnmarkPayment(
    DirectoryEntry apt,
    DateTime month,
    Payment payment,
  ) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final monthName = DateFormat('MMMM', locale).format(month);
    final who = _apartmentWhoLabel(apt);
    final hasReceipt = payment.hasReceipt;
    var removeReceipt = false;

    return showDialog<({bool removeReceipt})>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(l10n.confirmUnmarkPaymentTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.confirmUnmarkPaymentBody(
                      who,
                      monthName,
                      '${month.year}',
                    ),
                  ),
                  if (hasReceipt) ...[
                    const SizedBox(height: 14),
                    Text(
                      l10n.paymentHasReceiptNote,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: DiraColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(l10n.keepPaymentReceipt),
                          icon: const Icon(Icons.receipt_long_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(l10n.removePaymentReceipt),
                          icon: const Icon(Icons.delete_outline, size: 16),
                        ),
                      ],
                      selected: {removeReceipt},
                      onSelectionChanged: (s) =>
                          setLocal(() => removeReceipt = s.first),
                    ),
                    TextButton.icon(
                      onPressed: () => _openPaymentReceipt(payment),
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: Text(l10n.viewReceipt),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, (removeReceipt: removeReceipt)),
                  child: Text(l10n.confirmMarkUnpaid),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_UnpaidReceiptAction?> _unpaidReceiptActions(Payment payment) {
    final l10n = context.l10n;
    return showModalBottomSheet<_UnpaidReceiptAction>(
      context: context,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.receiptOnUnpaidHint,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.receipt_long_rounded,
                  color: DiraColors.brick,
                ),
                title: Text(l10n.viewReceipt),
                onTap: () => Navigator.pop(ctx, _UnpaidReceiptAction.view),
              ),
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: DiraColors.sageDark,
                ),
                title: Text(l10n.markPaymentPaid),
                onTap: () => Navigator.pop(ctx, _UnpaidReceiptAction.markPaid),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPaymentReceipt(Payment payment) async {
    final path = payment.receiptPath;
    if (path == null || path.isEmpty) {
      _snack(context.l10n.cantOpenDocument);
      return;
    }
    final locale = Localizations.localeOf(context).languageCode;
    final monthName =
        DateFormat('MMMM', locale).format(DateTime(payment.year, payment.month));
    await openVaultFile(
      context,
      bucket: 'receipts',
      path: path,
      title: context.l10n.paymentReceiptTitle(monthName, '${payment.year}'),
      asPopup: true,
    );
  }

  Future<void> _applyPaymentStatus(
    DirectoryEntry apt,
    DateTime month,
    Payment? previous, {
    required String status,
    bool clearReceipt = false,
  }) async {
    final keepReceipt = !clearReceipt && (previous?.hasReceipt ?? false);
    setState(() {
      _replaceCell(
        apt.apartmentId,
        month,
        Payment(
          id: previous?.id ?? 'optimistic',
          apartmentId: apt.apartmentId,
          month: month.month,
          year: month.year,
          amount: previous?.amount ?? 0,
          status: status,
          apartmentNumber: apt.apartmentNumber,
          receiptPath: keepReceipt ? previous?.receiptPath : null,
          receiptUrl: keepReceipt ? previous?.receiptUrl : null,
          paymentDate: status == 'paid' ? DateTime.now() : null,
        ),
      );
    });

    try {
      final res = await api.patch('/api/payments', {
        'apartmentId': apt.apartmentId,
        'month': month.month,
        'year': month.year,
        'status': status,
        if (clearReceipt) 'receiptPath': null,
      });
      if (!mounted) return;
      final payment = Payment.fromJson(res['payment']);
      // PATCH response may omit receipt_url; preserve local URLs when kept.
      setState(
        () => _replaceCell(
          apt.apartmentId,
          month,
          Payment(
            id: payment.id,
            apartmentId: payment.apartmentId,
            month: payment.month,
            year: payment.year,
            amount: payment.amount,
            status: payment.status,
            apartmentNumber: payment.apartmentNumber,
            paymentDate: payment.paymentDate,
            receiptPath: clearReceipt
                ? null
                : (payment.receiptPath ?? previous?.receiptPath),
            receiptUrl: clearReceipt
                ? null
                : (payment.receiptUrl ?? previous?.receiptUrl),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _replaceCell(apt.apartmentId, month, previous));
      _snack(e.message);
    }
  }

  /// Quick actions ("whole floor paid" / "whole month paid"): flip all
  /// unpaid cells optimistically, then sync in one bulk call.
  Future<void> _bulkMark(
    List<DirectoryEntry> apts,
    List<DateTime> months,
  ) async {
    final index = _cellIndex;
    final targets = <({DirectoryEntry apt, DateTime month})>[];
    for (final apt in apts) {
      for (final m in months) {
        final p = index[_cellKey(apt.apartmentId, m.year, m.month)];
        if (p?.status != 'paid') targets.add((apt: apt, month: m));
      }
    }
    if (targets.isEmpty) return;

    final snapshot = List<Payment>.from(_payments);
    setState(() {
      for (final t in targets) {
        final prev =
            index[_cellKey(t.apt.apartmentId, t.month.year, t.month.month)];
        _replaceCell(
          t.apt.apartmentId,
          t.month,
          Payment(
            id: prev?.id ?? 'optimistic',
            apartmentId: t.apt.apartmentId,
            month: t.month.month,
            year: t.month.year,
            amount: prev?.amount ?? 0,
            status: 'paid',
            apartmentNumber: t.apt.apartmentNumber,
          ),
        );
      }
    });

    try {
      await api.post('/api/payments/bulk', {
        'apartmentIds': apts.map((a) => a.apartmentId).toSet().toList(),
        'months': months
            .map((m) => {'month': m.month, 'year': m.year})
            .toList(),
        'status': 'paid',
      });
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _payments = snapshot);
      _snack(e.message);
    }
  }

  /// Long-press on a paid matrix cell: attach the receipt document.
  /// The resident then sees it next to that month in their own view.
  Future<void> _attachReceipt(DirectoryEntry apt, DateTime month) async {
    final l10n = context.l10n;
    final p = _cellIndex[_cellKey(apt.apartmentId, month.year, month.month)];
    if (p == null || p.status != 'paid') {
      _snack(l10n.attachReceiptOnlyPaid);
      return;
    }
    final picked = await pickAttachments(context, allowPdf: true);
    final file = picked.firstOrNull;
    if (file == null) return;
    try {
      final up = await api.uploadFile(
        '/api/payments/upload',
        bytes: file.bytes,
        filename: file.name,
      );
      await api.patch('/api/payments', {
        'paymentId': p.id,
        'status': 'paid',
        'receiptPath': up['receiptPath'],
      });
      _snack(l10n.receiptAttached);
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _addExpense() async {
    final categories = _expenses.map((e) => e.category).toSet().toList();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ExpenseSheet(existingCategories: categories),
    );
    if (saved == true && mounted) {
      _snack(context.l10n.expenseSaved);
      await _load();
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  double get _buildingBalance =>
      _openingBalance + _buildingIncome - _buildingExpensesTotal;

  Widget _buildingStatusCard(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final currency = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    final asOf = DateFormat('d MMMM yyyy', locale).format(DateTime.now());
    final balance = _buildingBalance;
    final balanceColor =
        balance >= 0 ? DiraColors.sageDark : DiraColors.brick;

    Widget row(String label, String value, {Color? valueColor}) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: DiraColors.inkSoft),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: valueColor ?? DiraColors.ink,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: DiraColors.creamDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.buildingBalance,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DiraColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currency.format(balance),
            style: heading(fontSize: 32, color: balanceColor),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.balanceAsOf(asOf),
            style: const TextStyle(fontSize: 12, color: DiraColors.inkSoft),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: DiraColors.creamCard),
          if (_openingBalance != 0)
            row(l10n.openingBalanceRow, currency.format(_openingBalance)),
          row(l10n.buildingIncome, currency.format(_buildingIncome)),
          row(
            l10n.buildingExpensesTotal,
            currency.format(_buildingExpensesTotal),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVaad = context.watch<SessionController>().user?.isVaad ?? false;
    final l10n = context.l10n;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.financesTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            labelColor: DiraColors.brickDark,
            unselectedLabelColor: DiraColors.inkSoft,
            indicatorColor: DiraColors.brick,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: l10n.payments),
              Tab(text: l10n.expensesTab),
            ],
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: DiraColors.brick),
              )
            : TabBarView(
                children: [
                  isVaad ? _matrixTab(context) : _tenantTab(context),
                  _expensesTab(context),
                ],
              ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Tab 1 (Vaad): summary line + filters + collapsible floor matrix
  // ------------------------------------------------------------------
  Widget _matrixTab(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final currency = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    final months = _months;
    final index = _cellIndex;

    // Header line: apartments · % collected (of dues that came due) · debt.
    final dueRows = _payments.where(_isDue).toList();
    final paidDue = dueRows.where((p) => p.status == 'paid').length;
    final pct = dueRows.isEmpty
        ? 100
        : (paidDue * 100 / dueRows.length).round();
    final totalDebt = dueRows
        .where((p) => p.status != 'paid')
        .fold(0.0, (s, p) => s + p.amount);

    final debts = {
      for (final a in _apartments) a.apartmentId: _debtOf(a.apartmentId),
    };
    final visible = _visibleApartments(debts);
    final searching = _query.trim().isNotEmpty;

    // Group by floor, ascending.
    final floors = <int, List<DirectoryEntry>>{};
    for (final a in visible) {
      floors.putIfAbsent(a.floor, () => []).add(a);
    }
    final sortedFloors = floors.keys.toList()..sort();

    String halfLabel(int half) {
      final from = DateFormat(
        'MMM',
        locale,
      ).format(DateTime(_year, half * 6 + 1));
      final to = DateFormat(
        'MMM',
        locale,
      ).format(DateTime(_year, half * 6 + 6));
      return '$from–$to';
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: DiraColors.brick,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildingStatusCard(context),
          const SizedBox(height: 14),
          Text(
            l10n.collectionSummary(
              '${_apartments.length}',
              '$pct',
              currency.format(totalDebt),
            ),
            style: const TextStyle(fontSize: 12.5, color: DiraColors.inkSoft),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchPayments,
              hintStyle: const TextStyle(
                fontSize: 13.5,
                color: DiraColors.inkSoft,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: DiraColors.inkSoft,
              ),
              isDense: true,
              filled: true,
              fillColor: DiraColors.creamCard,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: DiraColors.creamDeep),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: DiraColors.creamDeep),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(
                  color: DiraColors.brick,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filters: period dropdowns (year, half) + apartment filter chips.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DropdownChip<int>(
                  label: '$_year',
                  value: _year,
                  items: [for (final y in _years) (value: y, label: '$y')],
                  onSelected: (y) => setState(() => _year = y),
                ),
                const SizedBox(width: 8),
                _DropdownChip<int>(
                  label: halfLabel(_half),
                  value: _half,
                  items: [
                    for (final h in [0, 1]) (value: h, label: halfLabel(h)),
                  ],
                  onSelected: (h) => setState(() => _half = h),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.onlyWithDebt),
                  selected: _onlyWithDebt,
                  onSelected: (v) => setState(() => _onlyWithDebt = v),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(l10n.collapseAll),
                  onPressed: () => setState(() {
                    for (final f in _apartments.map((a) => a.floor).toSet()) {
                      _expandedOverride[f] = false;
                    }
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_apartments.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.noApartmentsYet,
                  style: const TextStyle(color: DiraColors.inkSoft),
                ),
              ),
            )
          else if (visible.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.noPaymentSearchResults,
                  style: const TextStyle(color: DiraColors.inkSoft),
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  children: [
                    _matrixHeader(context, months, visible),
                    const SizedBox(height: 6),
                    ...sortedFloors.map((floor) {
                      final apts = floors[floor]!;
                      final floorDebt = apts.fold(
                        0.0,
                        (s, a) => s + (debts[a.apartmentId] ?? 0),
                      );
                      final expanded = searching
                          ? true
                          : (_expandedOverride[floor] ?? false);
                      return _FloorSection(
                        floor: floor,
                        apartments: apts,
                        months: months,
                        debts: debts,
                        floorDebt: floorDebt,
                        expanded: expanded,
                        cellIndex: index,
                        cellKey: _cellKey,
                        onToggleExpand: () => setState(
                          () => _expandedOverride[floor] = !expanded,
                        ),
                        onCellTap: _toggleCell,
                        onCellLongPress: _attachReceipt,
                        onMarkFloorPaid: () => _bulkMark(apts, months),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _Legend(),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.attachReceiptHint,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 11, color: DiraColors.inkSoft),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  /// Header row: "דירה" | month labels with a mark-all button | "חוב".
  Widget _matrixHeader(
    BuildContext context,
    List<DateTime> months,
    List<DirectoryEntry> visible,
  ) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    return Row(
      children: [
        SizedBox(
          width: _MatrixDims.labelWidth,
          child: Text(
            l10n.apartmentColumn,
            style: const TextStyle(fontSize: 11, color: DiraColors.inkSoft),
          ),
        ),
        ...months.map(
          (m) => Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('MMM', locale).format(m),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: DiraColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 3),
                // Quick action: whole month paid for the visible list.
                InkWell(
                  onTap: () => _bulkMark(visible, [m]),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: DiraColors.sageLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: DiraColors.sageDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: _MatrixDims.debtWidth,
          child: Text(
            l10n.debtColumn,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: DiraColors.inkSoft),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Tab 1 (tenant): own dues — hero summary, year filter, month cards
  // with the payment date and the attached receipt.
  // ------------------------------------------------------------------
  Widget _tenantTab(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final currency = NumberFormat.currency(symbol: '₪', decimalDigits: 0);

    // Open debt counts only months whose due date has arrived.
    final totalDue = _payments
        .where((p) => p.status != 'paid' && _isDue(p))
        .fold(0.0, (sum, p) => sum + p.amount);

    final yearPayments = _payments.where((p) => p.year == _year).toList()
      ..sort((a, b) => b.month.compareTo(a.month));
    final hasDebt = totalDue > 0;

    return RefreshIndicator(
      onRefresh: _load,
      color: DiraColors.brick,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          Text(
            l10n.paymentsSubtitle,
            style: const TextStyle(fontSize: 13.5, color: DiraColors.inkSoft),
          ),
          const SizedBox(height: 16),
          if (hasDebt) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: DiraColors.terracottaSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.youOwe,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DiraColors.brickDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currency.format(totalDue),
                    style: heading(fontSize: 32, color: DiraColors.brick),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildingStatusCard(context),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.monthlyCommitteeFees,
                  style: heading(fontSize: 17),
                ),
              ),
              _DropdownChip<int>(
                label: '$_year',
                value: _year,
                items: [
                  for (final y in _years) (value: y, label: '$y'),
                ],
                onSelected: (y) => setState(() => _year = y),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (yearPayments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.noChargesForYear,
                textAlign: TextAlign.center,
                style: const TextStyle(color: DiraColors.inkSoft),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: DiraColors.creamCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DiraColors.creamDeep),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < yearPayments.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: DiraColors.creamDeep),
                    _TenantPaymentRow(
                      payment: yearPayments[i],
                      currency: currency,
                      locale: locale,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            l10n.paymentsAutoUpdated,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: DiraColors.inkSoft),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Tab 2: expense ledger
  // ------------------------------------------------------------------
  /// Expense years present in the ledger (plus the current one).
  List<int> get _expenseYears {
    final years = <int>{
      DateTime.now().year,
      ..._expenses.map((e) => int.parse(e.expenseDate.substring(0, 4))),
    };
    return years.toList()..sort();
  }

  /// Ledger rows narrowed to the selected year (and month, unless
  /// "whole year" is chosen).
  List<Expense> get _filteredExpenses => [
    for (final e in _expenses)
      if (int.parse(e.expenseDate.substring(0, 4)) == _expYear &&
          (_expMonth == 0 ||
              int.parse(e.expenseDate.substring(5, 7)) == _expMonth))
        e,
  ];

  Widget _expensesTab(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isVaad = context.read<SessionController>().user?.isVaad ?? false;
    final currency = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    final visible = _filteredExpenses;
    final totalExpenses = visible.fold(0.0, (sum, e) => sum + e.amount);

    return RefreshIndicator(
      onRefresh: _load,
      color: DiraColors.brick,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _DropdownChip<int>(
                label: '$_expYear',
                value: _expYear,
                items: [
                  for (final y in _expenseYears) (value: y, label: '$y'),
                ],
                onSelected: (y) => setState(() => _expYear = y),
              ),
              const SizedBox(width: 8),
              _DropdownChip<int>(
                label: _expMonth == 0
                    ? l10n.allYear
                    : DateFormat(
                        'MMMM',
                        locale,
                      ).format(DateTime(_expYear, _expMonth)),
                value: _expMonth,
                items: [
                  (value: 0, label: l10n.allYear),
                  for (var m = 1; m <= 12; m++)
                    (
                      value: m,
                      label: DateFormat(
                        'MMMM',
                        locale,
                      ).format(DateTime(_expYear, m)),
                    ),
                ],
                onSelected: (m) => setState(() => _expMonth = m),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // IntrinsicHeight bounds the stretch: inside a ListView the Row
          // gets infinite height and stretching alone would crash layout.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: l10n.buildingExpenses,
                    value: currency.format(totalExpenses),
                    color: DiraColors.sageDark,
                  ),
                ),
                if (isVaad) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: _addExpense,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_circle_outline,
                                color: DiraColors.brick,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.recordExpense,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: DiraColors.brickDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.noExpensesYet,
                  style: const TextStyle(color: DiraColors.inkSoft),
                ),
              ),
            )
          else
            ..._groupedExpenses(context, visible),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  /// Expenses grouped by month with a small month header, like the design.
  List<Widget> _groupedExpenses(BuildContext context, List<Expense> expenses) {
    final locale = Localizations.localeOf(context).languageCode;
    final currency = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    final groups = <String, List<Expense>>{};
    for (final e in expenses) {
      groups.putIfAbsent(e.expenseDate.substring(0, 7), () => []).add(e);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      for (final key in keys) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat(
                  'MMMM yyyy',
                  locale,
                ).format(DateTime.parse('$key-01')),
                style: heading(fontSize: 16),
              ),
              Text(
                currency.format(groups[key]!.fold(0.0, (s, e) => s + e.amount)),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DiraColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
        ...groups[key]!.map((e) => _ExpenseCard(expense: e)),
      ],
    ];
  }
}

// ====================================================================
// Floor-grouped matrix: collapsible floor rows, flexible month cells
// that fit the screen width (no horizontal scrolling), debt column.
// ====================================================================
class _MatrixDims {
  static const double labelWidth = 72;
  static const double debtWidth = 52;
  static const double cellHeight = 38;
}

/// Last token of a full name — works for Hebrew "שם משפחה" and Latin surnames.
String? _familyNameOf(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;
  return parts.last;
}

/// Compact surname label for the matrix. Same family once; mixed → first + "+".
String? _apartmentFamilyLabel(DirectoryEntry apt) {
  final families = <String>[];
  final seen = <String>{};
  for (final r in apt.residents) {
    final f = _familyNameOf(r.name);
    if (f == null) continue;
    final key = f.toLowerCase();
    if (seen.add(key)) families.add(f);
  }
  if (families.isEmpty) return null;
  if (families.length == 1) return families.first;
  return '${families.first}+';
}

String _apartmentResidentsTooltip(DirectoryEntry apt, AppLocalizations l10n) {
  final names = apt.residents
      .map((r) => r.name.trim())
      .where((n) => n.isNotEmpty)
      .toList();
  if (names.isEmpty) return l10n.vacant;
  return names.join('\n');
}

/// Apt number + optional family name under it; long-press tooltip for full names.
class _AptLabel extends StatelessWidget {
  final DirectoryEntry apartment;

  const _AptLabel({required this.apartment});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final family = _apartmentFamilyLabel(apartment);
    return Tooltip(
      message: _apartmentResidentsTooltip(apartment, l10n),
      waitDuration: const Duration(milliseconds: 350),
      child: SizedBox(
        width: _MatrixDims.labelWidth,
        height: _MatrixDims.cellHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.aptTiny('${apartment.apartmentNumber}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            if (family != null)
              Text(
                family,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: DiraColors.inkSoft,
                  height: 1.15,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloorSection extends StatelessWidget {
  final int floor;
  final List<DirectoryEntry> apartments;
  final List<DateTime> months;
  final Map<String, double> debts;
  final double floorDebt;
  final bool expanded;
  final Map<String, Payment> cellIndex;
  final String Function(String apartmentId, int year, int month) cellKey;
  final VoidCallback onToggleExpand;
  final void Function(DirectoryEntry apt, DateTime month) onCellTap;
  final void Function(DirectoryEntry apt, DateTime month) onCellLongPress;
  final VoidCallback onMarkFloorPaid;

  const _FloorSection({
    required this.floor,
    required this.apartments,
    required this.months,
    required this.debts,
    required this.floorDebt,
    required this.expanded,
    required this.cellIndex,
    required this.cellKey,
    required this.onToggleExpand,
    required this.onCellTap,
    required this.onCellLongPress,
    required this.onMarkFloorPaid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    final hasDebt = floorDebt > 0;

    return Column(
      children: [
        // Floor header: chevron, floor name, debt summary.
        InkWell(
          onTap: onToggleExpand,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: hasDebt ? DiraColors.goldLight : DiraColors.creamDeep,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(
                  l10n.floorN('$floor'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const Spacer(),
                Text(
                  hasDebt
                      ? l10n.debtAmount(currency.format(floorDebt))
                      : l10n.noDebt,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasDebt ? DiraColors.brickDark : DiraColors.inkSoft,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: DiraColors.inkSoft,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 6),
          ...apartments.map((a) {
            final debt = debts[a.apartmentId] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: _MatrixDims.labelWidth,
                    child: _AptLabel(apartment: a),
                  ),
                  ...months.map((m) {
                    final p =
                        cellIndex[cellKey(a.apartmentId, m.year, m.month)];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _MatrixCell(
                          payment: p,
                          month: m,
                          onTap: () => onCellTap(a, m),
                          onLongPress: () => onCellLongPress(a, m),
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    width: _MatrixDims.debtWidth,
                    child: Text(
                      debt > 0 ? currency.format(debt) : '—',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: debt > 0
                            ? DiraColors.brickDark
                            : DiraColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Quick action: mark every shown month for the whole floor.
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onMarkFloorPaid,
                style: TextButton.styleFrom(
                  backgroundColor: DiraColors.sageLight,
                  foregroundColor: DiraColors.sageDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.markFloorPaid,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MatrixCell extends StatelessWidget {
  final Payment? payment;
  final DateTime month;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _MatrixCell({
    required this.payment,
    required this.month,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Paid = green. Unpaid with a kept receipt = soft brick outline +
    // receipt icon (still tappable via the cell action sheet). Empty = blank.
    final paid = payment?.status == 'paid';
    final hasReceipt = payment?.hasReceipt ?? false;

    final Color bg;
    final Widget child;
    if (paid) {
      bg = DiraColors.sageLight;
      child = Icon(
        hasReceipt ? Icons.receipt_long_rounded : Icons.check,
        size: hasReceipt ? 14 : 15,
        color: DiraColors.sageDark,
      );
    } else if (hasReceipt) {
      bg = DiraColors.terracottaSoft;
      child = const Icon(
        Icons.receipt_long_rounded,
        size: 14,
        color: DiraColors.brickDark,
      );
    } else {
      bg = DiraColors.creamDeep;
      child = const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: _MatrixDims.cellHeight,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
          border: hasReceipt && !paid
              ? Border.all(color: DiraColors.brick.withValues(alpha: 0.35))
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// A chip-styled dropdown: shows the current selection with a caret and
/// opens a menu of options (scales to any number of years).
class _DropdownChip<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<({T value, String label})> items;
  final ValueChanged<T> onSelected;

  const _DropdownChip({
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      color: DiraColors.creamCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: Row(
              children: [
                Expanded(child: Text(item.label)),
                if (item.value == value)
                  const Icon(Icons.check, size: 16, color: DiraColors.brick),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsetsDirectional.only(
          start: 12,
          end: 6,
          top: 7,
          bottom: 7,
        ),
        decoration: BoxDecoration(
          color: DiraColors.goldLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DiraColors.gold),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: DiraColors.goldDark,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: DiraColors.goldDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// שולם / לא שולם color legend.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget dot(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: DiraColors.inkSoft),
        ),
      ],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(DiraColors.sageLight, l10n.statusPaid),
        const SizedBox(width: 8),
        dot(DiraColors.creamDeep, l10n.statusUnpaid),
        const SizedBox(width: 8),
        dot(DiraColors.terracottaSoft, l10n.receiptShort),
      ],
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    final e = expense;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if ((e.provider ?? '').isNotEmpty) e.provider!,
                        e.category,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: DiraColors.inkSoft,
                      ),
                    ),
                    if ((e.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        e.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: DiraColors.inkSoft,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (e.hasReceipt) ...[
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          final path = e.receiptPath;
                          if (path == null || path.isEmpty) return;
                          openVaultFile(
                            context,
                            bucket: 'receipts',
                            path: path,
                            title: e.title,
                            asPopup: true,
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.receipt_outlined,
                              size: 14,
                              color: DiraColors.brick,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.viewReceipt,
                              style: const TextStyle(
                                fontSize: 12,
                                color: DiraColors.brick,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                currency.format(e.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// Add-expense bottom sheet
// ====================================================================
class _ExpenseSheet extends StatefulWidget {
  final List<String> existingCategories;
  const _ExpenseSheet({required this.existingCategories});

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController();
  final _provider = TextEditingController();
  final _amount = TextEditingController();
  PickedAttachment? _receipt;
  bool _busy = false;
  String? _error;

  bool get _valid =>
      _title.text.trim().length >= 2 &&
      _category.text.trim().length >= 2 &&
      (double.tryParse(_amount.text.trim()) ?? 0) > 0;

  Future<void> _pickReceipt() async {
    final picked = await pickAttachments(context, allowPdf: true);
    final file = picked.firstOrNull;
    if (file != null) setState(() => _receipt = file);
  }

  Future<void> _save() async {
    // Dismiss the keyboard now; otherwise it stays open after the
    // sheet pops because focus is still on a text field.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String? receiptPath;
      final receipt = _receipt;
      if (receipt != null) {
        final res = await api.uploadFile(
          '/api/expenses/upload',
          bytes: receipt.bytes,
          filename: receipt.name,
        );
        receiptPath = res['receiptPath'] as String?;
      }
      await api.post('/api/expenses', {
        'title': _title.text.trim(),
        'category': _category.text.trim(),
        'amount': double.parse(_amount.text.trim()),
        'expenseDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim(),
        if (_provider.text.trim().isNotEmpty) 'provider': _provider.text.trim(),
        'receiptPath': ?receiptPath,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.recordExpense, style: heading(fontSize: 20)),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.titleLabel),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _category,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      hintText: l10n.categoryHint,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: l10n.amount),
                  ),
                ),
              ],
            ),
            if (widget.existingCategories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.existingCategories
                    .map(
                      (c) => ActionChip(
                        label: Text(c, style: const TextStyle(fontSize: 12)),
                        onPressed: () => setState(() => _category.text = c),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _provider,
              decoration: InputDecoration(labelText: l10n.providerOptional),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.descriptionOptional),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickReceipt,
              icon: Icon(
                _receipt == null
                    ? Icons.attach_file_rounded
                    : Icons.check_circle,
                size: 18,
                color: _receipt == null
                    ? DiraColors.brick
                    : DiraColors.sageDark,
              ),
              label: Text(_receipt?.name ?? l10n.attachReceipt),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy || !_valid ? null : _save,
              child: Text(_busy ? l10n.pleaseWait : l10n.save),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: DiraColors.brick),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: DiraColors.inkSoft),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Light payment row matching the marketing payments list.
class _TenantPaymentRow extends StatelessWidget {
  final Payment payment;
  final NumberFormat currency;
  final String locale;

  const _TenantPaymentRow({
    required this.payment,
    required this.currency,
    required this.locale,
  });

  Future<void> _openReceipt(BuildContext context) async {
    final path = payment.receiptPath;
    if (path == null || path.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cantOpenDocument)),
        );
      }
      return;
    }
    final monthName =
        DateFormat('MMMM', locale).format(DateTime(payment.year, payment.month));
    await openVaultFile(
      context,
      bucket: 'receipts',
      path: path,
      title: context.l10n.paymentReceiptTitle(monthName, '${payment.year}'),
      asPopup: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paid = payment.status == 'paid';
    final hasReceipt = payment.hasReceipt;
    return InkWell(
      onTap: hasReceipt ? () => _openReceipt(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat(
                      'MMMM yyyy',
                      locale,
                    ).format(DateTime(payment.year, payment.month)),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      currency.format(payment.amount),
                      if (paid && payment.paymentDate != null)
                        l10n.paidOnDate(
                          DateFormat(
                            'd/M/yyyy',
                            locale,
                          ).format(payment.paymentDate!),
                        ),
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: DiraColors.inkSoft,
                    ),
                  ),
                  if (hasReceipt) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          size: 14,
                          color: DiraColors.brick,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.viewReceipt,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DiraColors.brick,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            StatusPill.payment(context, paid: paid),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: hasReceipt ? DiraColors.brick : DiraColors.inkSoft,
            ),
          ],
        ),
      ),
    );
  }
}
