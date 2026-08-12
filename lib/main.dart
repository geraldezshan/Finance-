import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/background_controller.dart';
import 'theme/currency_controller.dart';
import 'theme/budget_config_controller.dart';
import 'services/connectivity_controller.dart';
import 'services/powersync_db.dart';
import 'screens/auth/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await openPowerSync();
  await ThemeController.instance.load();
  await BackgroundController.instance.load();
  await CurrencyController.instance.load();
  await BudgetConfigController.instance.load();
  await ConnectivityController.instance.start();

  // Connect PowerSync when logged in; clear the local DB on logout.
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.session != null) {
      connectPowerSync();
    } else {
      disconnectPowerSync();
    }
  });

  runApp(const FinancePlusApp());
}

class FinancePlusApp extends StatelessWidget {
  const FinancePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Finance+',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        builder: (context, child) {
          // Paints the user's chosen background (with opacity) behind every
          // screen, over a solid base color.
          final bg = BackgroundController.instance;
          return AnimatedBuilder(
            animation: Listenable.merge([bg.id, bg.opacity]),
            builder: (_, __) => Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: bg.baseColor()),
                Opacity(
                  opacity: bg.opacity.value.clamp(0.0, 1.0),
                  child: DecoratedBox(decoration: bg.decoration()),
                ),
                child ?? const SizedBox.shrink(),
              ],
            ),
          );
        },
        home: const AuthGate(),
      ),
    );
  }
}

/// Decides between the login flow and the in-app flow based on auth state.
///
/// IMPORTANT: AuthGate must STAY mounted for the whole session so that when the
/// user logs out, `onAuthStateChange` rebuilds it and sends them back to login.
/// That's why the welcome -> home transition happens *inside* [AppFlow] using
/// local state, instead of Navigator.pushReplacement (which would detach
/// AuthGate and break logout).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        if (session != null) {
          return const AppFlow();
        }
        return const LoginScreen();
      },
    );
  }
}

/// The logged-in experience: show the Welcome screen first, then the main app.
class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return WelcomeScreen(onStart: () => setState(() => _started = true));
    }
    return const HomeShell(initialIndex: 2);
  }
}