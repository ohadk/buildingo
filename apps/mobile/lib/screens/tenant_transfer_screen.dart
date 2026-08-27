import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/api_client.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/phone_field.dart';

/// 3-step holder transfer wizard for a rental unit:
///   1. End the current tenancy (effective date + what happens to debt).
///   2. Incoming holder — self-completes via SMS link, or Vaad fills in.
///   3. Confirm: what stays on the apartment card, what moves, what ends.
/// The apartment card and its full history stay with the unit.
class TenantTransferScreen extends StatefulWidget {
  final String apartmentId;
  final int apartmentNumber;
  final Tenancy? current;
  final double debt;

  const TenantTransferScreen({
    super.key,
    required this.apartmentId,
    required this.apartmentNumber,
    required this.current,
    required this.debt,
  });

  @override
  State<TenantTransferScreen> createState() => _TenantTransferScreenState();
}

class _TenantTransferScreenState extends State<TenantTransferScreen> {
  int _step = 0;

  // Step 1 — end of the current tenancy.
  DateTime _endDate = DateTime.now();
  String _debtPolicy = 'keep_with_outgoing';

  // Step 2 — the incoming holder.
  String _mode = 'self'; // self | vaad
  final _name = TextEditingController();
  String _phoneE164 = '';
  String _holderType = 'renter';
  DateTime _startDate = DateTime.now();
  bool _sendSms = true;

  bool _busy = false;
  String? _error;

  bool get _stepValid => switch (_step) {
    1 =>
      _mode == 'self'
          ? PhoneField.isValid(_phoneE164)
          : _name.text.trim().length >= 2,
    _ => true,
  };

  Future<void> _pickDate({required bool end}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: end ? _endDate : _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => end ? _endDate = picked : _startDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final fmt = DateFormat('yyyy-MM-dd');
    try {
      await api.post('/api/apartments/${widget.apartmentId}/transfer', {
        'endDate': fmt.format(_endDate),
        'debtPolicy': _debtPolicy,
        'incoming': {
          'mode': _mode,
          if (_name.text.trim().isNotEmpty) 'fullName': _name.text.trim(),
          if (PhoneField.isValid(_phoneE164)) 'phone': _phoneE164,
          'holderType': _holderType,
          'startDate': fmt.format(_startDate),
        },
        'sendSms': _sendSms && PhoneField.isValid(_phoneE164),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final holderName =
        widget.current?.fullName ??
        widget.current?.phoneNumber ??
        l10n.vacant;

    return Scaffold(
      backgroundColor: DiraColors.cream,
      body: Column(
        children: [
          _Header(
            apartmentNumber: widget.apartmentNumber,
            holderName: holderName,
            holderType: widget.current?.holderType,
            occupants: widget.current?.numOccupants,
          ),
          _StepIndicator(step: _step),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: switch (_step) {
                0 => _buildEndStep(l10n, holderName),
                1 => _buildIncomingStep(l10n),
                _ => _buildConfirmStep(l10n, holderName),
              },
            ),
          ),
          _BottomBar(
            step: _step,
            busy: _busy,
            canContinue: _stepValid,
            onBack: () => setState(() => _step--),
            onCancel: () => Navigator.pop(context),
            onContinue: () {
              if (_step < 2) {
                setState(() {
                  if (_step == 0 && _startDate.isBefore(_endDate)) {
                    _startDate = _endDate;
                  }
                  _step++;
                });
              } else {
                _submit();
              }
            },
            error: _error,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- step 1: end
  Widget _buildEndStep(dynamic l10n, String holderName) {
    final currency = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.endTenancyTitle(holderName), style: heading(fontSize: 19)),
        const SizedBox(height: 6),
        Text(
          l10n.endTenancyBody,
          style: const TextStyle(
            color: DiraColors.inkSoft,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.endDateLabel,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _dateBox(_endDate, () => _pickDate(end: true))),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.debt > 0
                    ? DiraColors.terracottaSoft
                    : DiraColors.sagePale,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.debt > 0
                    ? l10n.debtAmount(currency.format(widget.debt))
                    : l10n.noDebt,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.debt > 0
                      ? DiraColors.brickDark
                      : DiraColors.sageDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.debtQuestion,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _OptionCard(
          title: l10n.debtKeepTitle,
          body: l10n.debtKeepBody,
          selected: _debtPolicy == 'keep_with_outgoing',
          onTap: () => setState(() => _debtPolicy = 'keep_with_outgoing'),
        ),
        _OptionCard(
          title: l10n.debtOwnerTitle,
          body: l10n.debtOwnerBody,
          selected: _debtPolicy == 'transfer_to_owner',
          onTap: () => setState(() => _debtPolicy = 'transfer_to_owner'),
        ),
        _OptionCard(
          title: l10n.debtCloseTitle,
          body: l10n.debtCloseBody,
          selected: _debtPolicy == 'closed',
          onTap: () => setState(() => _debtPolicy = 'closed'),
        ),
      ],
    );
  }

  // -------------------------------------------------- step 2: incoming
  Widget _buildIncomingStep(dynamic l10n) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.stepIncomingHolder, style: heading(fontSize: 19)),
        const SizedBox(height: 6),
        Text(
          l10n.incomingDetailsBody(
            '${widget.apartmentNumber}',
            fmt.format(_startDate),
          ),
          style: const TextStyle(color: DiraColors.inkSoft, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _OptionCard(
          title: l10n.modeSelfTitle,
          body: l10n.modeSelfBody,
          selected: _mode == 'self',
          onTap: () => setState(() => _mode = 'self'),
        ),
        _OptionCard(
          title: l10n.modeVaadTitle,
          body: l10n.modeVaadBody,
          selected: _mode == 'vaad',
          onTap: () => setState(() => _mode = 'vaad'),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _name,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: _mode == 'self' ? l10n.optionalField : null,
            filled: true,
            fillColor: DiraColors.creamCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.mobilePhoneLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        PhoneField(onChanged: (v) => setState(() => _phoneE164 = v)),
        const SizedBox(height: 14),
        Text(
          l10n.holderTypeLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _typeButton(l10n.holderRenter, 'renter'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _typeButton(l10n.holderOwner, 'owner'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.startDateLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _dateBox(_startDate, () => _pickDate(end: false)),
        if (_mode == 'self') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DiraColors.sageDeep,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.linkExplainTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                for (final (i, step) in [
                  l10n.linkStepOtp,
                  l10n.linkStepProfile,
                  l10n.linkStepContract,
                  l10n.linkStepConfirm,
                ].indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: DiraColors.goldLight,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: DiraColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _sendSms,
          onChanged: (v) => setState(() => _sendSms = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: DiraColors.sageDark,
          title: Text(
            l10n.sendSmsOnTransfer,
            style: const TextStyle(fontSize: 13.5),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------- step 3: confirm
  Widget _buildConfirmStep(dynamic l10n, String holderName) {
    final incomingName = _name.text.trim().isNotEmpty
        ? _name.text.trim()
        : l10n.newHolderFallback;
    final phoneLabel = PhoneField.isValid(_phoneE164)
        ? PhoneField.formatDisplay(_phoneE164)
        : l10n.noPhone;
    final typeLabel = _holderType == 'owner'
        ? l10n.holderOwner
        : l10n.holderRenter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.stepConfirmTransfer, style: heading(fontSize: 19)),
        const SizedBox(height: 6),
        Text(
          '${l10n.apartmentShort('${widget.apartmentNumber}')} · '
          '$holderName ← $incomingName · $typeLabel · $phoneLabel',
          style: const TextStyle(
            color: DiraColors.inkSoft,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        if (_mode == 'self')
          Text(
            l10n.selfCompleteNote,
            style: const TextStyle(color: DiraColors.inkSoft, fontSize: 13),
          ),
        const SizedBox(height: 16),
        _InfoCard(title: l10n.keptOnCardTitle, body: l10n.keptOnCardBody),
        _InfoCard(title: l10n.movesToNewTitle, body: l10n.movesToNewBody),
        _InfoCard(
          title: l10n.staysWithOutgoingTitle,
          body: l10n.staysWithOutgoingBody,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DiraColors.goldLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.transferLogNote,
            style: const TextStyle(fontSize: 12.5, height: 1.5),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------- helpers
  Widget _dateBox(DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DiraColors.creamCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 17,
              color: DiraColors.inkSoft,
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(String label, String value) {
    final selected = _holderType == value;
    return InkWell(
      onTap: () => setState(() => _holderType = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? DiraColors.sageDeep : DiraColors.creamCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: selected ? Colors.white : DiraColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Dark-green banner: apartment card label, holder name, type · occupants.
class _Header extends StatelessWidget {
  final int apartmentNumber;
  final String holderName;
  final String? holderType;
  final int? occupants;

  const _Header({
    required this.apartmentNumber,
    required this.holderName,
    required this.holderType,
    required this.occupants,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtitleParts = [
      if (holderType != null)
        holderType == 'owner' ? l10n.holderOwner : l10n.holderRenter,
      if (occupants != null) l10n.occupantsN('$occupants'),
    ];
    return Container(
      width: double.infinity,
      color: DiraColors.sageDeep,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.apartmentCardTitle('$apartmentNumber'),
                  style: const TextStyle(
                    color: DiraColors.gold,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            holderName,
            style: heading(fontSize: 24, color: Colors.white),
          ),
          if (subtitleParts.isNotEmpty)
            Text(
              subtitleParts.join(' · '),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}

/// The 1-2-3 progress row with connecting lines.
class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      l10n.stepEndTenancy,
      l10n.stepIncomingHolder,
      l10n.stepConfirmTransfer,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= step
                      ? DiraColors.sageDark
                      : DiraColors.creamDeep,
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: i < step
                      ? DiraColors.sageDark
                      : i == step
                      ? DiraColors.brick
                      : DiraColors.creamDeep,
                  child: i < step
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: i == step
                                ? Colors.white
                                : DiraColors.inkSoft,
                          ),
                        ),
                ),
                const SizedBox(width: 5),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: i == step ? FontWeight.w700 : FontWeight.w500,
                    color: i <= step ? DiraColors.ink : DiraColors.inkSoft,
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

/// Radio-style selectable card (debt policy / incoming mode).
class _OptionCard extends StatelessWidget {
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? DiraColors.sagePale : DiraColors.creamCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? DiraColors.sageDark : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: DiraColors.inkSoft,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White explainer card on the confirmation step.
class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DiraColors.creamCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: const TextStyle(
              fontSize: 12.5,
              color: DiraColors.inkSoft,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cancel / back / continue (or confirm) bar pinned to the bottom.
class _BottomBar extends StatelessWidget {
  final int step;
  final bool busy;
  final bool canContinue;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  const _BottomBar({
    required this.step,
    required this.busy,
    required this.canContinue,
    required this.error,
    required this.onBack,
    required this.onCancel,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: const BoxDecoration(
          color: DiraColors.cream,
          border: Border(top: BorderSide(color: DiraColors.creamDeep)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  error!,
                  style: const TextStyle(color: DiraColors.brick),
                ),
              ),
            Row(
              children: [
                TextButton(
                  onPressed: busy ? null : onCancel,
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: DiraColors.brick),
                  ),
                ),
                const Spacer(),
                if (step > 0)
                  TextButton(
                    onPressed: busy ? null : onBack,
                    child: Text(l10n.backBtn),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: busy || !canContinue ? null : onContinue,
                  child: Text(
                    busy
                        ? l10n.pleaseWait
                        : step < 2
                        ? l10n.continueLabel
                        : l10n.confirmAndTransfer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
