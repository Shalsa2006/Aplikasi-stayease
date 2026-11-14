import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/common.dart';
import '../favorite/favorites_screen.dart';
import 'my_reviews_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favCount = context.watch<FavoriteProvider>().count;
    final u = auth.user;
    final phone = u?.phone;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        // ---------- header gradasi ----------
        Container(
          padding: EdgeInsets.fromLTRB(20, top + 24, 20, 28),
          decoration: const BoxDecoration(
            gradient: AppTheme.mainGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.warmGradient),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: Text(
                  (u?.name.isNotEmpty ?? false) ? u!.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppTheme.primary, fontSize: 34, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(u?.name ?? '-', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(u?.email ?? '-', style: const TextStyle(color: Colors.white70)),
            if (phone != null && phone.isNotEmpty) Text(phone, style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _tile(Icons.edit_rounded, AppTheme.primary, 'Edit Profil', 'Ubah nama, no. HP, password', () => _edit(context)),
            _tile(
              Icons.favorite_rounded,
              AppTheme.pink,
              'Hotel Disukai',
              favCount == 0 ? 'Belum ada' : '$favCount hotel tersimpan',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
            ),
            _tile(
              Icons.star_rounded,
              AppTheme.orange,
              'Ulasan Saya',
              'Rating & ulasan yang pernah kamu berikan',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsScreen())),
            ),
            _tile(Icons.logout_rounded, const Color(0xFFE11D48), 'Keluar', 'Keluar dari akun ini', () {
              context.read<FavoriteProvider>().clear();
              context.read<AuthProvider>().logout();
            }),
          ]),
        ),
      ]),
    );
  }

  Widget _tile(IconData icon, Color color, String label, String sub, VoidCallback onTap) => AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          leading: IconBadge(icon, color),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
          subtitle: Text(sub, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right_rounded, color: color),
          onTap: onTap,
        ),
      );

  Future<void> _edit(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final name = TextEditingController(text: auth.user?.name);
    final phone = TextEditingController(text: auth.user?.phone);
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 10),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'No. HP', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 10),
          TextField(
            controller: pass,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password baru (opsional)', prefixIcon: Icon(Icons.lock_outline)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await auth.updateProfile(name.text.trim(), phone.text.trim(), pass.text);
      if (context.mounted) showSnack(context, 'Profil diperbarui');
    } catch (e) {
      if (context.mounted) showSnack(context, '$e', error: true);
    }
  }
}
