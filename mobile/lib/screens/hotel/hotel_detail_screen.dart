import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/hotel.dart';
import '../../services/hotel_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/review_widgets.dart';
import '../booking/booking_form_screen.dart';

class HotelDetailScreen extends StatefulWidget {
  final int hotelId;
  final DateTimeRange dates;
  final int guests;
  const HotelDetailScreen({super.key, required this.hotelId, required this.dates, required this.guests});

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  final _service = HotelService();
  late DateTimeRange _dates = widget.dates;
  Hotel? _hotel;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final h = await _service.getHotel(widget.hotelId, checkIn: _dates.start, checkOut: _dates.end);
      if (mounted) setState(() => _hotel = h);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: _dates,
    );
    if (picked != null && picked.duration.inDays >= 1) {
      setState(() => _dates = picked);
      _load(); // hitung ulang ketersediaan kamar
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hotel == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ErrorView(message: _error ?? 'Gagal memuat', onRetry: _load),
      );
    }
    final h = _hotel!;
    final t = Theme.of(context).textTheme;
    final nights = _dates.duration.inDays;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            actions: [
              Padding(padding: const EdgeInsets.only(right: 12), child: FavoriteButton(hotel: h, size: 22)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                NetImage(h.imageUrl, width: double.infinity),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        AppTheme.primary.withValues(alpha: 0.55),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.name, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.ink)),
                const SizedBox(height: 6),
                Row(children: [
                  StarRow(h.star),
                  const SizedBox(width: 8),
                  if (h.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(gradient: AppTheme.warmGradient, borderRadius: BorderRadius.circular(8)),
                      child: Text('★ ${h.rating!.toStringAsFixed(1)} · ${h.reviewCount} ulasan',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ]),
                const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.place_rounded, size: 18, color: AppTheme.pink),
                  const SizedBox(width: 4),
                  Expanded(child: Text('${h.address}, ${h.city}', style: t.bodyMedium)),
                ]),
                const SizedBox(height: 16),
                Text(h.description, style: t.bodyMedium?.copyWith(height: 1.5, color: AppTheme.muted)),
                const SizedBox(height: 16),
                Text('Fasilitas', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < h.facilities.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.pickColor(i).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_facilityIcon(h.facilities[i]), size: 16, color: AppTheme.pickColor(i)),
                          const SizedBox(width: 6),
                          Text(h.facilities[i],
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.pickColor(i))),
                        ]),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Text('Pilih Kamar', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _changeDates,
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text('${tanggalPendek(_dates.start)} – ${tanggalPendek(_dates.end)} ($nights mlm)'),
                  ),
                ]),
                const SizedBox(height: 8),
                for (final (i, r) in h.rooms.indexed) ...[
                  _RoomTile(
                    room: r,
                    color: AppTheme.pickColor(i),
                    nights: nights,
                    guests: widget.guests,
                    onBook: () async {
                      final booked = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingFormScreen(hotel: h, room: r, dates: _dates, guests: widget.guests),
                        ),
                      );
                      if (booked == true) _load();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                Text('Rating & Ulasan Tamu', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (h.reviews.isNotEmpty) ...[RatingSummary(hotel: h), const SizedBox(height: 8)],
                if (h.reviews.isEmpty)
                  const Text('Belum ada ulasan. Pesan dan menginap untuk jadi yang pertama memberi rating!',
                      style: TextStyle(color: AppTheme.muted)),
                for (final rv in h.reviews)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.pickColor(rv.id),
                      foregroundColor: Colors.white,
                      child: Text(rv.userName.isNotEmpty ? rv.userName[0].toUpperCase() : '?'),
                    ),
                    title: Row(children: [
                      Flexible(
                        child: Text(rv.userName,
                            overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      RatingStars(rv.rating, size: 14),
                    ]),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(rv.comment?.isNotEmpty == true ? rv.comment! : '-', style: const TextStyle(color: AppTheme.ink)),
                      Text(tanggal(rv.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                    ]),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final Room room;
  final int nights;
  final int guests;
  final Color color;
  final VoidCallback onBook;
  const _RoomTile({
    required this.room,
    required this.nights,
    required this.guests,
    required this.onBook,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    final soldOut = room.available != null && room.available! <= 0;
    // Tamu lebih banyak dari kapasitas tetap bisa pesan beberapa kamar sekaligus
    final roomsNeeded = (guests / room.capacity).ceil();
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow(color),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NetImage(room.imageUrl, width: 116, height: 150),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.type, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
              Text(room.description, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person_outline, size: 14),
                Text(' maks ${room.capacity}', style: t.bodySmall),
                const SizedBox(width: 10),
                if (room.available != null)
                  Text(
                    soldOut ? 'Penuh' : 'Sisa ${room.available} kamar',
                    style: t.bodySmall?.copyWith(
                      color: soldOut || room.available! <= 2 ? Colors.red : Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(rupiah(room.pricePerNight),
                        style: t.titleSmall?.copyWith(color: AppTheme.price, fontWeight: FontWeight.w900)),
                    Text('/malam · total ${rupiah(room.pricePerNight * nights)}', style: t.labelSmall),
                  ]),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(72, 36), backgroundColor: color),
                  onPressed: soldOut ? null : onBook,
                  child: Text(soldOut ? 'Penuh' : 'Pesan'),
                ),
              ]),
              if (roomsNeeded > 1)
                Text('Perlu $roomsNeeded kamar untuk $guests tamu',
                    style: t.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }
}

IconData _facilityIcon(String f) {
  final s = f.toLowerCase();
  if (s.contains('wifi')) return Icons.wifi_rounded;
  if (s.contains('kolam') || s.contains('renang')) return Icons.pool_rounded;
  if (s.contains('parkir')) return Icons.local_parking_rounded;
  if (s.contains('restoran')) return Icons.restaurant_rounded;
  if (s.contains('sarapan')) return Icons.free_breakfast_rounded;
  if (s.contains('ac')) return Icons.ac_unit_rounded;
  if (s.contains('spa')) return Icons.spa_rounded;
  if (s.contains('laundry')) return Icons.local_laundry_service_rounded;
  if (s.contains('bandara') || s.contains('jemput')) return Icons.airport_shuttle_rounded;
  return Icons.check_circle_rounded;
}
