import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/deep_links.dart';
import 'core/push_permission.dart';
import 'core/realtime.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'core/tickets_controller.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'screens/blocked_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/welcome_choice_screen.dart';
import 'widgets/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Simulator / debug: skip APNs + reCAPTCHA app verification so Firebase
  // test phone numbers work without the production push/OAuth setup.
  // Never enable this in release — real devices need APNs (or reCAPTCHA).
  // Pass --dart-define=FORCE_REAL_PHONE_AUTH=true to test real SMS in debug.
  const forceRealPhoneAuth = bool.fromEnvironment('FORCE_REAL_PHONE_AUTH');
  if (kDebugMode && !forceRealPhoneAuth) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }
  if (kDebugMode && forceRealPhoneAuth) {
    // ignore: avoid_print
    print('FORCE_REAL_PHONE_AUTH=true (APNs/reCAPTCHA path enabled)');
    unawaited(_logApnsStatus());
  }
  // Never block first paint on Realtime/config — a bad API URL used to hang
  // App Review on the splash screen ("app did not load").
  unawaited(initRealtime());
  await initializeDateFormatting('he');
  await initializeDateFormatting('en');
  final localeController = LocaleController();
  await localeController.load();
  final deepLinks = DeepLinkController();
  unawaited(deepLinks.start());
  runApp(
    DiraApp(localeController: localeController, deepLinks: deepLinks),
  );
}

Future<void> _logApnsStatus() async {
  const channel = MethodChannel('buildingo/apns');
  for (var i = 0; i < 8; i++) {
    try {
      final status = await channel.invokeMethod<String>('status');
      // ignore: avoid_print
      print('APNs status[$i]=$status');
      if (status != null && status != 'pending') return;
    } catch (e) {
      // ignore: avoid_print
      print('APNs status[$i] error=$e');
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}

class DiraApp extends StatelessWidget {
  final LocaleController localeController;
  final DeepLinkController deepLinks;
  const DiraApp({
    super.key,
    required this.localeController,
    required this.deepLinks,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionController()),
        ChangeNotifierProvider(create: (_) => TicketsController()),
        ChangeNotifierProvider.value(value: localeController),
        ChangeNotifierProvider.value(value: deepLinks),
      ],
      child: Consumer<LocaleController>(
        builder: (context, locales, _) => MaterialApp(
          title: 'Buildingo',
          debugShowCheckedModeBanner: false,
          theme: buildDiraTheme(),
          locale: locales.locale ?? const Locale('he'),
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (device, supported) {
            if (locales.locale != null) return locales.locale;
            // App default is Hebrew unless the user picked another language.
            return const Locale('he');
          },
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          // Firebase Phone Auth reCAPTCHA returns via a deep link like
          // `/link?deep_link_id=...`. Ignore it so MaterialApp doesn't crash
          // (native Firebase Auth already consumes the callback).
          // Keep FlutterDeepLinkingEnabled=false; app_links handles /open/*.
          onGenerateRoute: (settings) {
            final name = settings.name ?? '';
            if (name.contains('/link') ||
                name.contains('firebaseauth') ||
                name.contains('deep_link_id')) {
              return MaterialPageRoute<void>(
                builder: (_) => const SizedBox.shrink(),
                settings: settings,
              );
            }
            return null;
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute<void>(
              builder: (_) => const SizedBox.shrink(),
              settings: settings,
            );
          },
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.data == null) return const LoginScreen();
        return const _SessionGate();
      },
    );
  }
}

/// After Firebase sign-in: run the backend token exchange once, then
/// route to onboarding or the main app.
class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  bool _pushPromptScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionController>();
      if (session.user == null && !session.loading) session.bootstrap();
    });
  }

  void _schedulePushPermissionPrompt() {
    if (_pushPromptScheduled) return;
    _pushPromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Ask on every signed-in path (home, welcome/join, onboarding) so App
      // Review always sees the consent flow (Guideline 4.5.4).
      await PushPermission.ensureRequested(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (session.loading || (session.user == null && session.error == null)) {
      return const SplashScreen();
    }
    if (session.error != null && session.user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(session.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => session.bootstrap(),
                  child: Text(context.l10n.retry),
                ),
                TextButton(
                  onPressed: () => session.signOut(),
                  child: Text(context.l10n.signOut),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Subscription lapsed (trial over / blocked by the super admin):
    // freeze the app behind a friendly paywall screen.
    if (session.blockedReason != null) {
      return BlockedScreen(reason: session.blockedReason!);
    }

    _schedulePushPermissionPrompt();

    if (session.user!.needsOnboarding) {
      // Not attached to any building yet → self-service entry point
      // (create a building as Vaad / find one as tenant / enter a code).
      if (session.user!.buildingId == null) return const WelcomeChoiceScreen();
      return const OnboardingScreen();
    }
    return const MainShell();
  }
}
