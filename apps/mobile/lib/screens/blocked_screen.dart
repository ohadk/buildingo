import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/phone_field.dart';

/// Shown when the building's subscription lapsed: either the 14-day
/// trial ended or the super admin blocked access. There is no in-app
/// purchase — the Vaad reaches out through the contact form and we
/// activate the subscription (₪4.90 per apartment / month) manually.
class BlockedScreen extends StatelessWidget {
  /// 'trial_expired' | 'blocked'
  final String reason;
  const BlockedScreen({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.read<SessionController>();
    final trialExpired = reason == 'trial_expired';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: heroGradient),
        child: SafeArea(
          child: Center(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(32),
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: trialExpired
                      ? DiraColors.goldLight
                      : DiraColors.terracottaSoft,
                  child: Icon(
                    trialExpired
                        ? Icons.hourglass_disabled_rounded
                        : Icons.lock_outline_rounded,
                    size: 40,
                    color:
                        trialExpired ? DiraColors.goldDark : DiraColors.brick,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  trialExpired ? l10n.trialEndedTitle : l10n.accessBlockedTitle,
                  textAlign: TextAlign.center,
                  style: heading(fontSize: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  trialExpired ? l10n.trialEndedBody : l10n.accessBlockedBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DiraColors.inkSoft,
                    height: 1.5,
                  ),
                ),
                if (trialExpired) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: DiraColors.creamCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.pricingLine,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: DiraColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.likeItContactUs,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: DiraColors.inkSoft,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _openContactForm(context),
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: Text(l10n.contactUs),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => session.refreshMe(),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.checkAgain),
                ),
                TextButton(
                  onPressed: () => session.signOut(),
                  child: Text(l10n.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openContactForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DiraColors.creamCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ContactSheet(topic: 'subscription'),
    );
  }
}

/// "Contact us" form — stores the request and emails the Buildingo team.
/// Works even while the building is blocked.
class ContactSheet extends StatefulWidget {
  final String topic;
  const ContactSheet({super.key, this.topic = 'general'});

  @override
  State<ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<ContactSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  String _phoneE164 = '';
  String? _initialPhone;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionController>().user;
    _name.text = user?.fullName ?? '';
    _initialPhone = user?.phoneNumber;
    _phoneE164 = user?.phoneNumber ?? '';
    _email.text = user?.email ?? '';
  }

  bool get _valid =>
      _name.text.trim().length >= 2 &&
      PhoneField.isValid(_phoneE164) &&
      _message.text.trim().length >= 2;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await api.post('/api/contact', {
        'name': _name.text.trim(),
        'phone': _phoneE164,
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        'message': _message.text.trim(),
        'topic': widget.topic,
      });
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_sent) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: DiraColors.sageLight,
              child: Icon(
                Icons.mark_email_read_rounded,
                size: 34,
                color: DiraColors.sageDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.contactSentTitle, style: heading(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              l10n.contactSentBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DiraColors.inkSoft, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.contactUs, style: heading(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            l10n.contactFormHint,
            style: const TextStyle(
              fontSize: 13,
              color: DiraColors.inkSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.fullName),
          ),
          const SizedBox(height: 10),
          PhoneField(
            initialValue: _initialPhone,
            onChanged: (v) => setState(() => _phoneE164 = v),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: l10n.emailOptional),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _message,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.contactMessage),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy || !_valid ? null : _submit,
            child: Text(_busy ? l10n.pleaseWait : l10n.contactSend),
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
    );
  }
}
