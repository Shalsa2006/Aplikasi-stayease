import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/favorite_provider.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: const StayEaseApp(),
    ),
  );
}

class StayEaseApp extends StatelessWidget {
  const StayEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StayEase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) => switch (auth.status) {
          AuthStatus.unknown => const _Splash(),
          // Admin dan pengguna biasa mendapat tampilan berbeda
          AuthStatus.authenticated => (auth.user?.isAdmin ?? false) ? const AdminShell() : const MainShell(),
          AuthStatus.unauthenticated => const LoginScreen(),
        },
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.mainGradient),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.apartment_rounded, size: 72, color: Colors.white),
              SizedBox(height: 12),
              Text('StayEase', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1)),
              SizedBox(height: 4),
              Text('Menginap jadi lebih mudah', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 28),
              CircularProgressIndicator(color: Colors.white),
            ]),
          ),
        ),
      );
}
