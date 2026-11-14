import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/admin.dart';
import '../../models/booking.dart';
import '../../services/admin_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Kartu satu pesanan di daftar admin: hotel, kamar yang dipesan, pemesan, total, status.
class AdminBookingTile extends StatelessWidget {
  final AdminBooking item;
  final VoidCallback onTap;
  const AdminBookingTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = item.booking;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              NetImage(b.hotelImage, width: 64, height: 72, radius: BorderRadius.circular(12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(b.code, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.admin, letterSpacing: 0.5)),
                    const Spacer(),
                    StatusChip(b.status),
                  ]),
                  const SizedBox(height: 2),
                  Text(b.hotelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
                  Text('🛏 ${b.roomType} × ${b.rooms} kamar · ${b.nights} malam',
                      style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                  Text('${b.guestName} · ${tanggalPendek(b.checkIn)} – ${tanggalPendek(b.checkOut)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                  const SizedBox(height: 2),
                  Text(rupiah(b.paymentAmount ?? b.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.price)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet detail pesanan untuk admin + tombol ubah status.
/// Mengembalikan data terbaru bila status diubah.
Future<AdminBooking?> showAdminBookingSheet(BuildContext context, AdminBooking item) {
  return showModalBottomSheet<AdminBooking>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _AdminBookingSheet(item: item),
  );
}

class _AdminBookingSheet extends StatefulWidget {
  final AdminBooking item;
  const _AdminBookingSheet({required this.item});

  @override
  State<_AdminBookingSheet> createState() => _AdminBookingSheetState();
}

class _AdminBookingSheetState extends State<_AdminBookingSheet> {
  late AdminBooking _item = widget.item;
  bool _busy = false;

  Future<void> _setStatus(BookingStatus s) async {
    setState(() => _busy = true);
    try {
      final updated = await AdminService().updateStatus(_item.booking.id, s);
      if (!mounted) return;
      setState(() => _item = updated);
      showSnack(context, 'Status diubah menjadi "${s.label}"');
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _item.booking;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => ListView(controller: controller, padding: const EdgeInsets.fromLTRB(20, 10, 20, 24), children: [
        Center(
          child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFDAD6EA), borderRadius: BorderRadius.circular(4))),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: Text(b.code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.admin, letterSpacing: 1)),
          ),
          StatusChip(b.status),
        ]),
        Text('Dipesan ${tanggalJam(b.createdAt.toLocal())}', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            NetImage(b.hotelImage, height: 130, width: double.infinity),
            Positioned(
              left: 12,
              bottom: 10,
              right: 12,
              child: Text('${b.hotelName}\n${b.hotelCity}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 8)])),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        _group('Kamar yang dipesan', Icons.bed_rounded, AppTheme.primary, [
          _kv('Tipe kamar', b.roomType),
          _kv('Jumlah kamar', '${b.rooms} kamar'),
          _kv('Tamu', '${b.guests} orang'),
          _kv('Check-in', tanggal(b.checkIn)),
          _kv('Check-out', tanggal(b.checkOut)),
          _kv('Durasi', '${b.nights} malam'),
        ]),
        _group('Pemesan', Icons.person_rounded, AppTheme.orange, [
          _kv('Akun', '${_item.userName}\n${_item.userEmail}'),
          _kv('Nama tamu', b.guestName),
          _kv('No. HP', b.guestPhone),
          if (b.notes != null && b.notes!.isNotEmpty) _kv('Catatan', b.notes!),
        ]),
        _group('Pembayaran', Icons.payments_rounded, AppTheme.mint, [
          _kv('Harga kamar', '${rupiah(b.pricePerNight)} × ${b.nights} × ${b.rooms}'),
          _kv('Subtotal', rupiah(b.totalPrice)),
          _kv('Metode', b.paymentLabel),
          if (b.vaNumber != null) _kv('No. VA', groupDigits(b.vaNumber!)),
          if (b.qrisRef != null) _kv('Ref. QRIS', b.qrisRef!),
          _kv('Biaya layanan', rupiah(b.serviceFee)),
          _kv('Total', rupiah(b.paymentAmount ?? b.totalPrice), strong: true),
          if (b.receiptNumber != null) _kv('No. bukti', b.receiptNumber!),
          if (b.paidAt != null) _kv('Dibayar', tanggalJam(b.paidAt!)),
        ]),
        const SizedBox(height: 6),
        const Text('Ubah status', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in BookingStatus.values)
            ChoiceChip(
              label: Text(s.label),
              selected: b.status == s,
              showCheckmark: false,
              selectedColor: AppTheme.admin,
              labelStyle: TextStyle(color: b.status == s ? Colors.white : AppTheme.admin, fontWeight: FontWeight.w700),
              backgroundColor: AppTheme.admin.withValues(alpha: 0.08),
              onSelected: _busy || b.status == s ? null : (_) => _setStatus(s),
            ),
        ]),
        const SizedBox(height: 18),
        GradientButton(
          label: 'Tutup',
          gradient: AppTheme.adminGradient,
          onPressed: () => Navigator.pop(context, _item),
        ),
      ]),
    );
  }

  Widget _group(String title, IconData icon, Color color, List<Widget> rows) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
          ]),
          const SizedBox(height: 6),
          ...rows,
        ]),
      );

  Widget _kv(String k, String v, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(color: AppTheme.muted, fontSize: 13))),
          Expanded(
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
                  color: strong ? AppTheme.price : AppTheme.ink,
                  fontSize: strong ? 15 : 13,
                )),
          ),
        ]),
      );
}
