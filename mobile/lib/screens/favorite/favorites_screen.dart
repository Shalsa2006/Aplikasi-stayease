import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/hotel_card.dart';
import '../hotel/hotel_detail_screen.dart';

/// Tab "Disukai": daftar hotel yang ditandai dengan ikon hati.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>();
    final today = DateUtils.dateOnly(DateTime.now());
    final dates = DateTimeRange(start: today.add(const Duration(days: 1)), end: today.add(const Duration(days: 2)));

    Widget body;
    if (fav.loading && fav.hotels.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (fav.error != null && fav.hotels.isEmpty) {
      body = ErrorView(message: fav.error!, onRetry: fav.load);
    } else if (fav.hotels.isEmpty) {
      body = ListView(children: [
        const SizedBox(height: 110),
        const Center(child: IconBadge(Icons.favorite_rounded, AppTheme.pink, size: 48)),
        const SizedBox(height: 16),
        const Center(
          child: Text('Belum ada hotel yang disukai',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('Ketuk ikon ♡ pada hotel untuk menyimpannya di sini.',
              style: TextStyle(color: AppTheme.muted.withValues(alpha: 0.9))),
        ),
      ]);
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: fav.hotels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => HotelCard(
          hotel: fav.hotels[i],
          colorIndex: i,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HotelDetailScreen(hotelId: fav.hotels[i].id, dates: dates, guests: 2)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('Disukai'),
          const SizedBox(width: 8),
          if (fav.count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(gradient: AppTheme.warmGradient, borderRadius: BorderRadius.circular(20)),
              child: Text('${fav.count}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ),
        ]),
      ),
      body: RefreshIndicator(onRefresh: fav.load, child: body),
    );
  }
}
