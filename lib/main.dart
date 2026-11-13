import 'package:flutter/material.dart';
import 'data/app_state.dart';
import 'pages/auth_pages.dart';
import 'pages/home_page.dart';
import 'pages/onboarding_page.dart';
import 'theme.dart';
import 'widgets/cute_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  runApp(MaggotKuApp(state: state));
}

class MaggotKuApp extends StatefulWidget {
  const MaggotKuApp({super.key, this.state});

  /// Data yang sudah dimuat; null = data baru kosong (dipakai di test).
  final AppState? state;
  @override
  State<MaggotKuApp> createState() => _MaggotKuAppState();
}

class _MaggotKuAppState extends State<MaggotKuApp> {
  final _nav = GlobalKey<NavigatorState>();
  late final AppState state = (widget.state ?? AppState())
    // Sesi login habis → kembali ke halaman Login.
    ..onSessionExpired = () {
      _nav.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
      final ctx = _nav.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Sesi berakhir, silakan masuk lagi.')),
        );
      }
    };

  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: MaterialApp(
      navigatorKey: _nav,
      title: 'MaggotKu',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      // Belum login → onboarding setiap kali aplikasi dibuka, lalu Login.
      // Sudah login → langsung Beranda.
      home: state.loggedIn ? const HomePage() : const OnboardingPage(),
      builder: (context, child) => CuteBackground(child: child!),
    ),
  );
}
