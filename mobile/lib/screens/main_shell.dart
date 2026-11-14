import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorite_provider.dart';
import 'booking/my_bookings_screen.dart';
import 'favorite/favorites_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  // Key agar daftar pesanan bisa di-refresh saat tab dibuka
  final _bookingsKey = GlobalKey<MyBookingsScreenState>();

  @override
  void initState() {
    super.initState();
    // Muat daftar hotel yang disukai setelah login
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<FavoriteProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final favCount = context.watch<FavoriteProvider>().count;
    return Scaffold(
      body: IndexedStack(index: _index, children: [
        const HomeScreen(),
        const FavoritesScreen(),
        MyBookingsScreen(key: _bookingsKey),
        const ProfileScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 2) _bookingsKey.currentState?.refresh();
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Jelajah'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: favCount > 0,
              label: Text('$favCount'),
              child: const Icon(Icons.favorite_border_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: favCount > 0,
              label: Text('$favCount'),
              child: const Icon(Icons.favorite_rounded),
            ),
            label: 'Disukai',
          ),
          const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
