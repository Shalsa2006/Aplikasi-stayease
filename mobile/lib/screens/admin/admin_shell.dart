import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'admin_bookings_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_hotels_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_rooms_screen.dart';

/// Tampilan utama ADMIN — berbeda dari pengguna biasa (MainShell).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Theme(
      // warna aktif navigasi pakai biru admin
      data: Theme.of(context).copyWith(
        navigationBarTheme: Theme.of(context).navigationBarTheme.copyWith(
              indicatorColor: AppTheme.admin.withValues(alpha: 0.14),
              iconTheme: WidgetStateProperty.resolveWith(
                (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppTheme.admin : AppTheme.muted),
              ),
              labelTextStyle: WidgetStateProperty.resolveWith(
                (s) => TextStyle(
                  fontSize: 11,
                  fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
                  color: s.contains(WidgetState.selected) ? AppTheme.admin : AppTheme.muted,
                ),
              ),
            ),
      ),
      child: Scaffold(
        body: IndexedStack(index: _index, children: [
          AdminDashboardScreen(onNavigate: _go),
          const AdminBookingsScreen(),
          const AdminRoomsScreen(),
          const AdminHotelsScreen(),
          const AdminReviewsScreen(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
            NavigationDestination(icon: Icon(Icons.bed_outlined), selectedIcon: Icon(Icons.bed_rounded), label: 'Kamar'),
            NavigationDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment_rounded), label: 'Hotel'),
            NavigationDestination(icon: Icon(Icons.star_outline_rounded), selectedIcon: Icon(Icons.star_rounded), label: 'Ulasan'),
          ],
        ),
      ),
    );
  }
}

/// Header gradasi biru khas admin, dipakai di semua halaman admin.
class AdminHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? bottom;
  const AdminHeader({super.key, required this.title, this.subtitle, this.actions = const [], this.bottom});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 12, 18),
        decoration: const BoxDecoration(
          gradient: AppTheme.adminGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(6)),
                  child: const Text('ADMIN',
                      style: TextStyle(color: AppTheme.ink, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 6),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                if (subtitle != null) Text(subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            ...actions,
          ]),
          if (bottom != null) ...[const SizedBox(height: 14), bottom!],
        ]),
      );
}
