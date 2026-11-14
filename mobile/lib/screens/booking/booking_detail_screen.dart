import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/review_widgets.dart';
import '../payment/payment_screen.dart';
import '../payment/receipt_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _service = BookingService();
  Booking? _b;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await _service.detail(widget.bookingId);
      if (mounted) {
        setState(() {
          _b = b;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _run(Future<Booking> Function() action, String okMsg) async {
    setState(() => _busy = true);
    try {
      final b = await action();
      if (!mounted) return;
      setState(() => _b = b);
      showSnack(context, okMsg);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Buka halaman pembayaran (Virtual Account / QRIS)
  Future<void> _pay() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(booking: _b!)));
    _load();
  }

  void _receipt() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(booking: _b!)));

  Future<void> _cancel() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: const Text('Kamar akan dilepas dan pesanan tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(100, 44)), onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, batalkan')),
        ],
      ),
    );
    if (yes == true) await _run(() => _service.cancel(_b!.id), 'Pesanan dibatalkan');
  }

  Future<void> _review() async {
    if (await showReviewSheet(context, _b!)) _load();
  }

  @override
  Widget build(BuildContext context) {
    final b = _b;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: b == null
          ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()))
          : ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppTheme.mainGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppTheme.softShadow(AppTheme.pink),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Kode Booking', style: TextStyle(color: Colors.white70)),
                      SelectableText(b.code,
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      StatusChip(b.status),
                    ]),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: NetImage(b.hotelImage, width: 72, height: 72),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              _section('Hotel', [
                _kv('Nama', b.hotelName),
                _kv('Alamat', '${b.hotelAddress}, ${b.hotelCity}'),
                _kv('Tipe kamar', b.roomType),
                _kv('Jumlah kamar', '${b.rooms} kamar'),
              ]),
              _section('Menginap', [
                _kv('Check-in', '${tanggal(b.checkIn)} · 14:00'),
                _kv('Check-out', '${tanggal(b.checkOut)} · 12:00'),
                _kv('Durasi', '${b.nights} malam'),
                _kv('Tamu', '${b.guests} orang'),
              ]),
              _section('Data Pemesan', [
                _kv('Nama', b.guestName),
                _kv('No. HP', b.guestPhone),
                if (b.notes != null && b.notes!.isNotEmpty) _kv('Catatan', b.notes!),
              ]),
              _section('Pembayaran', [
                _kv('${rupiah(b.pricePerNight)} × ${b.nights} mlm × ${b.rooms} kmr', rupiah(b.totalPrice)),
                if (b.paymentMethod != null) ...[
                  _kv('Metode', b.paymentLabel),
                  _kv('Biaya layanan', rupiah(b.serviceFee)),
                ],
                _kv('Total', rupiah(b.paymentAmount ?? b.totalPrice), bold: true),
                if (b.receiptNumber != null) _kv('No. Bukti', b.receiptNumber!),
              ]),
              if (b.status == BookingStatus.paid)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Tunjukkan kode booking ini ke resepsionis saat check-in.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ),
            ]),
      bottomNavigationBar: b == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (b.canPay)
                    GradientButton(
                      label: b.hasActiveInvoice ? 'Lanjutkan Pembayaran' : 'Bayar Sekarang',
                      icon: Icons.payments_rounded,
                      onPressed: _busy ? null : _pay,
                    ),
                  if (b.hasReceipt) ...[
                    GradientButton(
                      label: 'Lihat Bukti Pembayaran',
                      icon: Icons.receipt_long_rounded,
                      gradient: AppTheme.mintGradient,
                      onPressed: _receipt,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (b.canReview)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      onPressed: _busy ? null : _review,
                      icon: const Icon(Icons.star_rounded, color: AppTheme.accent),
                      label: const Text('Beri Ulasan'),
                    ),
                  if (b.canCancel)
                    TextButton(
                      onPressed: _busy ? null : _cancel,
                      child: const Text('Batalkan Pesanan', style: TextStyle(color: Colors.red)),
                    ),
                ]),
              ),
            ),
    );
  }

  Widget _section(String title, List<Widget> rows) => AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.pickColor(title.length),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
          ]),
          const SizedBox(height: 8),
          ...rows,
        ]),
      );

  Widget _kv(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(k, style: const TextStyle(color: AppTheme.muted))),
          Expanded(
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 14)),
          ),
        ]),
      );
}
