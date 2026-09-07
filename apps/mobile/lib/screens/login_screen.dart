import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/auth_errors.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/app_version_label.dart';
import '../widgets/phone_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Dual-sim / manual QA only — never prefill in release / App Store builds.
  static const _testPhoneDefine = String.fromEnvironment('TEST_PHONE');
  static const _testOtpDefine = String.fromEnvironment('TEST_OTP');
  static String get _testPhone =>
      kDebugMode ? _testPhoneDefine : '';
  static String get _testOtp => kDebugMode ? _testOtpDefine : '';

  String _phoneE164 = '';
  bool _phoneValid = false;
  late final TextEditingController _codeController = TextEditingController(
    text: _testOtp,
  );
  String? _verificationId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Debug QA prefills only — production login always starts empty.
    if (_testPhone.isNotEmpty) {
      _phoneE164 = _testPhone;
      _phoneValid = PhoneField.isValid(_testPhone);
    }
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    debugPrint('Phone auth sendCode phone=$_phoneE164');

    // Debug-only diagnostic path. Never compile into App Store via FORCE_REAL alone.
    const forceReal = bool.fromEnvironment('FORCE_REAL_PHONE_AUTH');
    if (kDebugMode && forceReal) {
      try {
        const channel = MethodChannel('buildingo/apns');
        final raw = await channel.invokeMethod<Map>('verifyPhone', _phoneE164);
        // ignore: avoid_print
        print('Native verifyPhone result=$raw');
        if (raw != null && raw['ok'] == true) {
          final id = raw['verificationId'] as String?;
          if (id != null && mounted) {
            setState(() {
              _busy = false;
              _verificationId = id;
            });
            return;
          }
        }
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = authErrorMessage(
            FirebaseAuthException(
              code: 'internal-error',
              message: '${raw?['error'] ?? raw}',
            ),
            context.l10n,
          );
        });
        return;
      } catch (e) {
        // ignore: avoid_print
        print('Native verifyPhone channel error=$e');
      }
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneE164,
      verificationCompleted: (credential) async {
        // Android auto-retrieval: signs in without typing the code
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (e) {
        // ignore: avoid_print
        print(
          'Phone auth verificationFailed '
          'code=${e.code} message=${e.message} '
          'stack=${e.stackTrace}',
        );
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = authErrorMessage(e, context.l10n);
        });
      },
      codeSent: (verificationId, _) {
        // ignore: avoid_print
        print('Phone auth codeSent verificationIdLen=${verificationId.length}');
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
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e, context.l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final awaitingCode = _verificationId != null;
    final l10n = context.l10n;
    return Scaffold(
      // Avoid rebuilding / reflowing the heavy brand stack with the keyboard;
      // a tiny bottom spacer listens to viewInsets instead.
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(gradient: heroGradient),
        child: Stack(
          children: [
            // Soft "organic" backdrop shapes.
            const Positioned(
              top: -110,
              left: -80,
              child: _Blob(size: 260, color: Color(0x66FFFBF2)),
            ),
            const Positioned(
              top: 40,
              right: -70,
              child: _Blob(size: 170, color: Color(0x40D9B382)),
            ),
            const Positioned(
              bottom: -100,
              right: -70,
              child: _Blob(size: 280, color: Color(0x59DCE5D9)),
            ),
            const Positioned(
              bottom: 90,
              left: -50,
              child: _Blob(size: 130, color: Color(0x33A34A3A)),
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: TextButton.icon(
                        onPressed: () =>
                            context.read<LocaleController>().toggle(context),
                        style: TextButton.styleFrom(
                          foregroundColor: DiraColors.brickDark,
                          backgroundColor: const Color(0x99FFFBF2),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.language, size: 18),
                        label: Text(l10n.language),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _LoginBrandMark(),
                              const SizedBox(height: 18),
                              Text(
                                'Buildingo',
                                textAlign: TextAlign.center,
                                style: heading(
                                  fontSize: 34,
                                  color: DiraColors.brickDeep,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.welcome,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: DiraColors.brickDark,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Card(
                                elevation: 4,
                                shadowColor: DiraColors.brickDeep.withValues(
                                  alpha: 0.25,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    28,
                                    24,
                                    24,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 280),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, 0.06),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        ),
                                    child: Column(
                                      key: ValueKey(awaitingCode),
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: awaitingCode
                                          ? _codeStep(l10n)
                                          : _phoneStep(l10n),
                                    ),
                                  ),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DiraColors.terracottaSoft,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 20,
                                        color: DiraColors.brickDark,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: DiraColors.brickDark,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const _KeyboardInsetPad(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10, top: 4),
                    child: AppVersionLabel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _phoneStep(AppLocalizations l10n) => [
    Text(
      l10n.signInWithPhone,
      textAlign: TextAlign.center,
      style: const TextStyle(color: DiraColors.inkSoft, fontSize: 14),
    ),
    const SizedBox(height: 20),
    PhoneField(
      initialValue: _testPhone.isEmpty ? null : _testPhone,
      enableAutofill: false,
      onChanged: (v) {
        _phoneE164 = v;
        final valid = PhoneField.isValid(v);
        // Only rebuild when the Send button enablement flips — not every digit.
        if (valid != _phoneValid) {
          setState(() => _phoneValid = valid);
        }
      },
    ),
    const SizedBox(height: 20),
    _primaryButton(
      label: l10n.sendCode,
      enabled: !_busy && _phoneValid,
      onPressed: _sendCode,
    ),
  ];

  List<Widget> _codeStep(AppLocalizations l10n) => [
    const Icon(Icons.sms_outlined, size: 34, color: DiraColors.sage),
    const SizedBox(height: 10),
    Text(
      l10n.enterCodeSentTo(PhoneField.formatDisplay(_phoneE164)),
      textAlign: TextAlign.center,
      style: const TextStyle(color: DiraColors.inkSoft, fontSize: 14),
    ),
    const SizedBox(height: 20),
    TextField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLength: 6,
      autofocus: true,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: heading(fontSize: 28, color: DiraColors.ink).copyWith(
        letterSpacing: 12,
      ),
      // Verification continues automatically once all 6 digits are
      // in — no extra tap needed.
      onChanged: (v) {
        if (v.length == 6 && !_busy) _verifyCode();
      },
      decoration: InputDecoration(
        counterText: '',
        hintText: '······',
        hintStyle: const TextStyle(
          color: DiraColors.inkSoft,
          letterSpacing: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: DiraColors.ink.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: DiraColors.brick, width: 1.5),
        ),
      ),
    ),
    const SizedBox(height: 20),
    _primaryButton(
      label: l10n.verifyAndSignIn,
      enabled: !_busy,
      onPressed: _verifyCode,
    ),
    const SizedBox(height: 4),
    TextButton.icon(
      onPressed: _busy
          ? null
          : () => setState(() {
              _verificationId = null;
              _codeController.clear();
            }),
      style: TextButton.styleFrom(foregroundColor: DiraColors.brickDark),
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: Text(l10n.useDifferentNumber),
    ),
  ];

  Widget _primaryButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: DiraColors.creamCard,
                ),
              )
            : Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

/// Brand mark isolated so keyboard inset rebuilds don't re-decode the 1024 icon.
class _LoginBrandMark extends StatelessWidget {
  const _LoginBrandMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RepaintBoundary(
        child: Container(
          width: 96,
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: DiraColors.creamCard,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: DiraColors.brickDeep.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Image.asset(
            'assets/icon/app_icon_1024.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            // Decode near display size (3x) instead of full 1024² every rebuild.
            cacheWidth: 288,
            cacheHeight: 288,
          ),
        ),
      ),
    );
  }
}

/// Only this leaf rebuilds when the keyboard opens/closes.
class _KeyboardInsetPad extends StatelessWidget {
  const _KeyboardInsetPad();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: MediaQuery.viewInsetsOf(context).bottom);
  }
}

/// A soft translucent circle used as a decorative backdrop element.
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
