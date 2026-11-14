import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/booking.dart';
import '../models/hotel.dart';
import '../services/hotel_service.dart';
import 'common.dart';

const _ratingLabels = ['', 'Sangat buruk 😞', 'Kurang 😕', 'Cukup 🙂', 'Bagus 😊', 'Luar biasa! 🤩'];
const _quickTags = ['Kamar bersih', 'Staf ramah', 'Lokasi strategis', 'Nyaman', 'Sarapan enak', 'Worth it', 'Pemandangan indah'];

/// Menampilkan form ulasan (rating bintang + komentar) untuk pesanan yang sudah dibayar.
/// Mengembalikan true jika ulasan berhasil dikirim.
Future<bool> showReviewSheet(BuildContext context, Booking booking) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _ReviewSheet(booking: booking),
  );
  return sent == true;
}

class _ReviewSheet extends StatefulWidget {
  final Booking booking;
  const _ReviewSheet({required this.booking});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  final Set<String> _tags = {};
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final text = [
      if (_tags.isNotEmpty) _tags.join(', '),
      if (_comment.text.trim().isNotEmpty) _comment.text.trim(),
    ].join('. ');
    try {
      await HotelService().addReview(
        hotelId: widget.booking.hotelId,
        bookingId: widget.booking.id,
        rating: _rating,
        comment: text,
      );
      if (!mounted) return;
      showSnack(context, 'Terima kasih atas ulasanmu! ⭐');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
                width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFDAD6EA), borderRadius: BorderRadius.circular(4))),
          ),
          const SizedBox(height: 14),
          Row(children: [
            NetImage(b.hotelImage, width: 54, height: 54, radius: BorderRadius.circular(12)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Bagaimana menginapmu?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.ink)),
                Text('${b.hotelName} · ${b.roomType}', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: AnimatedScale(
                  scale: i < _rating ? 1.0 : 0.85,
                  duration: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 46,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(_ratingLabels[_rating],
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.price)),
          ),
          const SizedBox(height: 16),
          const Text('Apa yang kamu suka?', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (i, t) in _quickTags.indexed)
              FilterChip(
                label: Text(t),
                selected: _tags.contains(t),
                showCheckmark: false,
                selectedColor: AppTheme.pickColor(i),
                backgroundColor: AppTheme.pickColor(i).withValues(alpha: 0.10),
                labelStyle: TextStyle(
                  color: _tags.contains(t) ? Colors.white : AppTheme.pickColor(i),
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (v) => setState(() => v ? _tags.add(t) : _tags.remove(t)),
              ),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Ceritakan pengalamanmu (opsional)'),
          ),
          const SizedBox(height: 16),
          GradientButton(label: 'Kirim Ulasan', icon: Icons.send_rounded, loading: _sending, onPressed: _send),
        ]),
      ),
    );
  }
}

/// Ringkasan rating hotel: nilai rata-rata besar + grafik batang per bintang.
class RatingSummary extends StatelessWidget {
  final Hotel hotel;
  const RatingSummary({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    final total = hotel.ratingBreakdown.values.fold<int>(0, (s, v) => s + v);
    final maxCount = hotel.ratingBreakdown.values.fold<int>(0, (m, v) => v > m ? v : m);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Column(children: [
          ShaderMask(
            shaderCallback: (r) => AppTheme.warmGradient.createShader(r),
            child: Text(
              hotel.rating?.toStringAsFixed(1) ?? '-',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          RatingStars((hotel.rating ?? 0).round(), size: 15),
          const SizedBox(height: 4),
          Text('$total ulasan', style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        ]),
        const SizedBox(width: 18),
        Expanded(
          child: Column(children: [
            for (var s = 5; s >= 1; s--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  SizedBox(width: 14, child: Text('$s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                  const Icon(Icons.star_rounded, size: 13, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: maxCount == 0 ? 0 : (hotel.ratingBreakdown[s] ?? 0) / maxCount,
                        minHeight: 8,
                        color: AppTheme.pickColor(5 - s),
                        backgroundColor: const Color(0xFFEFEBFA),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 22,
                    child: Text('${hotel.ratingBreakdown[s] ?? 0}',
                        textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                  ),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}
