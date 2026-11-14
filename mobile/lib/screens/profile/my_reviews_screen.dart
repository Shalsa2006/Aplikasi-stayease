import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/admin.dart';
import '../../services/hotel_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Daftar ulasan & rating yang pernah diberikan pengguna.
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<ReviewItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await HotelService().myReviews();
      if (mounted) {
        setState(() {
          _items = d;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: const Text('Ulasan Saya')),
      body: items == null
          ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              onRefresh: _load,
              child: items.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 100),
                      Center(child: IconBadge(Icons.star_rounded, AppTheme.accent, size: 46)),
                      SizedBox(height: 12),
                      Center(
                        child: Text('Belum ada ulasan', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
                      ),
                      SizedBox(height: 4),
                      Center(
                        child: Text('Beri rating dari menu Pesanan setelah membayar.',
                            style: TextStyle(color: AppTheme.muted)),
                      ),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final r = items[i];
                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            NetImage(r.hotelImage, width: 64, height: 64, radius: BorderRadius.circular(12)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(r.hotelName, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
                                Text('${r.roomType} · ${r.hotelCity}', style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                                const SizedBox(height: 4),
                                RatingStars(r.rating),
                                const SizedBox(height: 4),
                                Text(r.comment?.isNotEmpty == true ? r.comment! : '(tanpa komentar)',
                                    style: const TextStyle(color: AppTheme.ink)),
                                Text(tanggal(r.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                              ]),
                            ),
                          ]),
                        );
                      },
                    ),
            ),
    );
  }
}
