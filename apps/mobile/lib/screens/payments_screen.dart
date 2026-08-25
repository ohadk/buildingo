import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/realtime.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _payments = [];
  List<Expense> _expenses = [];
  bool _loading = true;
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
    try {
      final results = await Future.wait([
        api.get('/api/payments'),
        api.get('/api/expenses'),
      ]);
      if (!mounted) return;
      setState(() {
        _payments = ((results[0]['payments'] ?? []) as List)
            .map((p) => Payment.fromJson(p))
            .toList();
        _expenses = ((results[1]['expenses'] ?? []) as List)
            .map((e) => Expense.fromJson(e))
            .toList();
        _loading = false;
      });
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateMonth() async {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;
    try {
      final res = await api.post('/api/payments', {
        'month': now.month,
        'year': now.year,
      });
      if (!mounted) return;
      _snack(
        context.l10n.generatedDues(
          '${res['created']}',
          DateFormat('MMMM', locale).format(now),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _markPaid(Payment p) async {
    try {
      await api.patch('/api/payments', {'paymentId': p.id, 'status': 'paid'});
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _addExpense() async {
    final title = TextEditingController();
    final category = TextEditingController();
    final amount = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.recordExpense),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: InputDecoration(labelText: ctx.l10n.titleLabel),
            ),
            TextField(
              controller: category,
              decoration: InputDecoration(
                labelText: ctx.l10n.category,
                hintText: ctx.l10n.categoryHint,
              ),
            ),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: ctx.l10n.amount),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.save),
          ),
        ],
      ),
    );
    if (saved != true) return;
    try {
      await api.post('/api/expenses', {
        'title': title.text.trim(),
        'category': category.text.trim(),
        'amount': double.tryParse(amount.text) ?? 0,
        'expenseDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isVaad = context.watch<SessionController>().user?.isVaad ?? false;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final currency = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    final totalDue = _payments
        .where((p) => p.status != 'paid')
        .fold(0.0, (sum, p) => sum + p.amount);
    final totalExpenses = _expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.payments,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isVaad)
            IconButton(
              tooltip: l10n.generateMonthDues,
              icon: const Icon(Icons.playlist_add),
              onPressed: _generateMonth,
            ),
          if (isVaad)
            IconButton(
              tooltip: l10n.recordExpense,
              icon: const Icon(Icons.receipt_long),
              onPressed: _addExpense,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DiraColors.brick),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: DiraColors.brick,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: isVaad ? l10n.outstandingDues : l10n.youOwe,
                          value: currency.format(totalDue),
                          color: DiraColors.brick,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: l10n.buildingExpenses,
                          value: currency.format(totalExpenses),
                          color: DiraColors.sageDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isVaad ? l10n.paymentMatrix : l10n.myDues,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._payments.map(
                    (p) => Card(
                      child: ListTile(
                        title: Text(
                          '${DateFormat('MMMM yyyy', locale).format(DateTime(p.year, p.month))}'
                          '${isVaad && p.apartmentNumber != null ? ' — ${l10n.apartmentShort('${p.apartmentNumber}')}' : ''}',
                        ),
                        subtitle: Text(currency.format(p.amount)),
                        trailing: p.status == 'paid'
                            ? const Icon(
                                Icons.check_circle,
                                color: DiraColors.sageDark,
                              )
                            : isVaad
                            ? TextButton(
                                onPressed: () => _markPaid(p),
                                child: Text(l10n.markPaid),
                              )
                            : Text(
                                p.status == 'overdue'
                                    ? l10n.overdue
                                    : l10n.pendingPayment,
                                style: const TextStyle(
                                  color: DiraColors.brick,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.expenseLedger,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._expenses.map(
                    (e) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.receipt,
                          color: DiraColors.gold,
                        ),
                        title: Text(e.title),
                        subtitle: Text('${e.category} · ${e.expenseDate}'),
                        trailing: Text(
                          currency.format(e.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
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
