import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/admin.dart';
import '../../services/admin_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_shell.dart';

/// Semua ulasan & rating dari pengguna. Admin bisa memfilter per bintang dan menghapus ulasan.
class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final _service = AdminService();
  List<ReviewItem> _items = [];
  int? _rating;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final d = await _service.reviews(rating: _rating);
      if (mounted) setState(() => _items = d);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(ReviewItem r) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus ulasan?'),
        content: Text('Ulasan dari ${r.userName} untuk ${r.hotelName} akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44), backgroundColor: const Color(0xFFE11D48)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _service.deleteReview(r.id);
      if (!mounted) return;
      showSnack(context, 'Ulasan dihapus');
      _load();
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avg = _items.isEmpty ? 0.0 : _items.fold<int>(0, (s, r) => s + r.rating) / _items.length;
    return Scaffold(
      body: Column(children: [
        AdminHeader(
          title: 'Ulasan & Rating',
          subtitle: _items.isEmpty ? 'Belum ada ulasan' : '${_items.length} ulasan · rata-rata ★ ${avg.toStringAsFixed(1)}',
          actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: Colors.white))],
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            children: [
              _chip('Semua', null),
              for (var s = 5; s >= 1; s--) _chip('$s ★', s),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _items.isEmpty
                          ? ListView(children: const [
                              SizedBox(height: 100),
                              Center(child: Text('Tidak ada ulasan', style: TextStyle(color: AppTheme.muted))),
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _items.length,
                              itemBuilder: (_, i) {
                                final r = _items[i];
                                return AppCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.pickColor(r.id),
                                        foregroundColor: Colors.white,
                                        child: Text(r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?'),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
                                          Text(r.userEmail, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                                        ]),
                                      ),
                                      RatingStars(r.rating),
                                    ]),
                                    const SizedBox(height: 10),
                                    Text(r.comment?.isNotEmpty == true ? r.comment! : '(tanpa komentar)',
                                        style: const TextStyle(color: AppTheme.ink, height: 1.4)),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.admin.withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(children: [
                                        const Icon(Icons.apartment_rounded, size: 16, color: AppTheme.admin),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text('${r.hotelName} · ${r.roomType} · ${r.bookingCode}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12, color: AppTheme.admin, fontWeight: FontWeight.w700)),
                                        ),
                                      ]),
                                    ),
                                    Row(children: [
                                      Text(tanggalJam(r.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () => _delete(r),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE11D48)),
                                        label: const Text('Hapus', style: TextStyle(color: Color(0xFFE11D48))),
                                      ),
                                    ]),
                                  ]),
                                );
                              },
                            ),
                    ),
        ),
      ]),
    );
  }

  Widget _chip(String label, int? rating) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _rating == rating,
          showCheckmark: false,
          selectedColor: AppTheme.admin,
          backgroundColor: AppTheme.admin.withValues(alpha: 0.08),
          labelStyle: TextStyle(color: _rating == rating ? Colors.white : AppTheme.admin, fontWeight: FontWeight.w700),
          onSelected: (_) {
            setState(() => _rating = rating);
            _load();
          },
        ),
      );
}
