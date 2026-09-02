import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initRealtime();
  await initializeDateFormatting('he');
  await initializeDateFormatting('en');
  final localeController = LocaleController();
  await localeController.load();
  runApp(DiraApp(localeController: localeController));
}

class DiraApp extends StatelessWidget {
  final LocaleController localeController;
  const DiraApp({super.key, required this.localeController});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionController()),
        ChangeNotifierProvider(create: (_) => TicketsController()),
        ChangeNotifierProvider.value(value: localeController),
      ],
      child: Consumer<LocaleController>(
        builder: (context, locales, _) => MaterialApp(
          title: 'Buildingo',
          debugShowCheckedModeBanner: false,
          theme: buildDiraTheme(),
          locale: locales.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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
          return const _Splash();
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionController>();
      if (session.user == null && !session.loading) session.bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (session.loading || (session.user == null && session.error == null)) {
      return const _Splash();
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
    if (session.user!.needsOnboarding) {
      // Not attached to any building yet → self-service entry point
      // (create a building as Vaad / find one as tenant / enter a code).
      if (session.user!.buildingId == null) return const WelcomeChoiceScreen();
      return const OnboardingScreen();
    }
    return const MainShell();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: heroGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_work_rounded, size: 64, color: DiraColors.brick),
              SizedBox(height: 12),
              Text(
                'Buildingo',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: DiraColors.ink,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: DiraColors.brick),
            ],
          ),
        ),
      ),
    );
  }
}
