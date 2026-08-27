import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/phone_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _phoneE164 = '';
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  String? _error;

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneE164,
      verificationCompleted: (credential) async {
        // Android auto-retrieval: signs in without typing the code
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (e) {
        setState(() {
          _busy = false;
          _error =
              e.message ?? (mounted ? context.l10n.verificationFailed : '');
        });
      },
      codeSent: (verificationId, _) {
        setState(() {
          _busy = false;
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      // AuthGate takes over from here (token exchange + routing)
    } on FirebaseAuthException catch (e) {
      setState(
        () => _error = e.message ?? (mounted ? context.l10n.invalidCode : ''),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final awaitingCode = _verificationId != null;
    final l10n = context.l10n;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: heroGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: TextButton.icon(
                  onPressed: () =>
                      context.read<LocaleController>().toggle(context),
                  icon: const Icon(Icons.language, size: 18),
                  label: Text(l10n.language),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.home_work_rounded,
                            size: 48,
                            color: DiraColors.brick,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.welcome,
                            textAlign: TextAlign.center,
                            style: heading(fontSize: 23),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            awaitingCode
                                ? l10n.enterCodeSentTo(_phoneE164)
                                : l10n.signInWithPhone,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: DiraColors.inkSoft),
                          ),
                          const SizedBox(height: 24),
                          if (!awaitingCode)
                            PhoneField(
                              onChanged: (v) => setState(() => _phoneE164 = v),
                            )
                          else
                            TextField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              textDirection: TextDirection.ltr,
                              maxLength: 6,
                              autofocus: true,
                              autofillHints: const [
                                AutofillHints.oneTimeCode,
                              ],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              // Verification continues automatically once
                              // all 6 digits are in — no extra tap needed.
                              onChanged: (v) {
                                if (v.length == 6 && !_busy) _verifyCode();
                              },
                              decoration: InputDecoration(
                                labelText: l10n.smsCode,
                                counterText: '',
                                prefixIcon: const Icon(Icons.sms),
                              ),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                _busy ||
                                    (!awaitingCode &&
                                        !PhoneField.isValid(_phoneE164))
                                ? null
                                : (awaitingCode ? _verifyCode : _sendCode),
                            child: Text(
                              _busy
                                  ? l10n.pleaseWait
                                  : awaitingCode
                                  ? l10n.verifyAndSignIn
                                  : l10n.sendCode,
                            ),
                          ),
                          if (awaitingCode)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _verificationId = null),
                              child: Text(l10n.useDifferentNumber),
                            ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: DiraColors.brick),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
