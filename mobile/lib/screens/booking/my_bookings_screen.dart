import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/review_widgets.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => MyBookingsScreenState();
}

class MyBookingsScreenState extends State<MyBookingsScreen> {
  final _service = BookingService();
  List<Booking> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final data = await _service.myBookings();
      if (mounted) setState(() => _items = data);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Booking> _filter(bool active) => _items
      .where((b) => active
          ? (b.status == BookingStatus.pending || b.status == BookingStatus.paid)
          : (b.status == BookingStatus.cancelled || b.status == BookingStatus.completed))
      .toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pesanan Saya'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.muted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            indicator: BoxDecoration(gradient: AppTheme.mainGradient, borderRadius: BorderRadius.circular(30)),
            tabs: const [Tab(text: 'Aktif'), Tab(text: 'Riwayat')],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorView(message: _error!, onRetry: refresh)
                : TabBarView(children: [_list(_filter(true)), _list(_filter(false))]),
      ),
    );
  }

  Widget _list(List<Booking> items) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: items.isEmpty
          ? ListView(children: const [
              SizedBox(height: 120),
              Center(child: IconBadge(Icons.luggage_rounded, AppTheme.orange, size: 48)),
              SizedBox(height: 12),
              Center(child: Text('Belum ada pesanan', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.muted))),
            ])
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final b = items[i];
                final tint = AppTheme.pickColor(i);
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppTheme.softShadow(tint),
                  ),
                  child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id)));
                      refresh();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        NetImage(b.hotelImage, width: 80, height: 86, radius: BorderRadius.circular(14)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(b.hotelName,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('${b.roomType} · ${b.rooms} kamar · ${b.nights} malam',
                                style: TextStyle(fontSize: 12, color: tint, fontWeight: FontWeight.w700)),
                            Text('${tanggalPendek(b.checkIn)} – ${tanggal(b.checkOut)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Row(children: [
                              StatusChip(b.status),
                              const Spacer(),
                              Text(rupiah(b.paymentAmount ?? b.totalPrice),
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.price)),
                            ]),
                            if (b.canReview)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.price,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () async {
                                    if (await showReviewSheet(context, b)) refresh();
                                  },
                                  icon: const Icon(Icons.star_rounded, color: AppTheme.accent, size: 18),
                                  label: const Text('Beri ulasan', style: TextStyle(fontWeight: FontWeight.w800)),
                                ),
                              )
                            else if (b.hasReview)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('✓ Sudah diulas', style: TextStyle(fontSize: 12, color: AppTheme.mint, fontWeight: FontWeight.w700)),
                              ),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                  ),
                );
              },
            ),
    );
  }
}
