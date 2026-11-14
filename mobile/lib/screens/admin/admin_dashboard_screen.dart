import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/admin.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_booking_detail_sheet.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends StatefulWidget {
  /// Pindah tab di AdminShell (1 = Pesanan, 2 = Kamar, 3 = Hotel, 4 = Ulasan)
  final ValueChanged<int> onNavigate;
  const AdminDashboardScreen({super.key, required this.onNavigate});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _service = AdminService();
  AdminStats? _s;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _service.stats();
      if (mounted) {
        setState(() {
          _s = s;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun admin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().user?.name ?? 'Admin';
    final s = _s;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          AdminHeader(
            title: 'Halo, ${name.split(' ').first}',
            subtitle: 'Ringkasan bisnis StayEase hari ini',
            actions: [
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
              IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded, color: Colors.white)),
            ],
            bottom: s == null
                ? null
                : Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.accent, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Total pendapatan (lunas)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(rupiah(s.revenue),
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        ]),
                      ),
                    ]),
                  ),
          ),
          if (s == null)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: _error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _StatCard('Kamar terpesan hari ini', '${s.bookedToday} / ${s.totalRooms}', Icons.bed_rounded,
                        AppTheme.coolGradient, () => widget.onNavigate(2)),
                    _StatCard('Menunggu bayar', '${s.pending}', Icons.hourglass_top_rounded, AppTheme.warmGradient,
                        () => widget.onNavigate(1)),
                    _StatCard('Lunas (aktif)', '${s.paid}', Icons.verified_rounded, AppTheme.mintGradient,
                        () => widget.onNavigate(1)),
                    _StatCard('Total pesanan', '${s.bookings}', Icons.receipt_long_rounded, AppTheme.mainGradient,
                        () => widget.onNavigate(1)),
                    _StatCard('Hotel · tipe kamar', '${s.hotels} · ${s.roomTypes}', Icons.apartment_rounded,
                        AppTheme.adminGradient, () => widget.onNavigate(3)),
                    _StatCard(
                      'Rating rata-rata',
                      s.avgRating == null ? '-' : '★ ${s.avgRating!.toStringAsFixed(1)}  (${s.reviews})',
                      Icons.star_rounded,
                      const LinearGradient(colors: [Color(0xFFE5A100), Color(0xFFFF8A3D)]),
                      () => widget.onNavigate(4),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text('Hotel per kota', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(children: [
                    for (final (i, c) in s.cities.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          IconBadge(Icons.location_city_rounded, AppTheme.pickColor(i), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(c.city, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
                          ),
                          Text('${c.hotels} hotel', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.pickColor(i).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${c.bookings} pesanan',
                                style: TextStyle(color: AppTheme.pickColor(i), fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        ]),
                      ),
                  ]),
                ),
                const SizedBox(height: 22),
                Row(children: [
                  const Expanded(
                    child: Text('Pesanan terbaru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
                  ),
                  TextButton(onPressed: () => widget.onNavigate(1), child: const Text('Lihat semua')),
                ]),
                if (s.recent.isEmpty) const Text('Belum ada pesanan.', style: TextStyle(color: AppTheme.muted)),
                for (final ab in s.recent)
                  AdminBookingTile(
                    item: ab,
                    onTap: () async {
                      await showAdminBookingSheet(context, ab);
                      _load();
                    },
                  ),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  const _StatCard(this.label, this.value, this.icon, this.gradient, this.onTap);

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(18)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, color: Colors.white, size: 22),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
          ),
        ),
      );
}
