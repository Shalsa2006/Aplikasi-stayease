import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Bukti pembayaran: nomor bukti, metode (VA/QRIS), jumlah, QR code untuk check-in, dan barcode.
class ReceiptScreen extends StatelessWidget {
  final Booking booking;
  final bool justPaid;
  const ReceiptScreen({super.key, required this.booking, this.justPaid = false});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final amount = b.paymentAmount ?? b.totalPrice;
    final receipt = b.receiptNumber ?? '-';
    final isVa = b.paymentMethod == PaymentMethod.va;

    return Scaffold(
      appBar: AppBar(title: const Text('Bukti Pembayaran')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ---------- kepala bukti ----------
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: const BoxDecoration(
            gradient: AppTheme.mintGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 10),
            Text(justPaid ? 'Pembayaran Berhasil!' : 'Pembayaran Lunas',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(rupiah(amount), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
            if (b.paidAt != null)
              Text(tanggalJam(b.paidAt!), style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        // ---------- isi bukti ----------
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            boxShadow: AppTheme.softShadow(AppTheme.mint),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Nomor Bukti Pembayaran', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
            Row(children: [
              Expanded(
                child: SelectableText(receipt,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.ink, letterSpacing: 0.5)),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.mint),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: receipt));
                  showSnack(context, 'Nomor bukti disalin');
                },
              ),
            ]),
            const SizedBox(height: 6),
            Center(
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: receipt,
                width: 280,
                height: 60,
                drawText: false,
                color: AppTheme.ink,
              ),
            ),
            const _Dashed(),
            _kv('Kode Booking', b.code, strong: true),
            _kv('Metode', b.paymentLabel),
            if (isVa) _kv('No. Virtual Account', groupDigits(b.vaNumber ?? '-')),
            if (!isVa) _kv('Ref. QRIS', b.qrisRef ?? '-'),
            _kv('Status', 'LUNAS', color: AppTheme.mint, strong: true),
            const _Dashed(),
            _kv('Hotel', b.hotelName),
            _kv('Kamar', '${b.roomType} × ${b.rooms}'),
            _kv('Menginap', '${tanggalPendek(b.checkIn)} – ${tanggal(b.checkOut)} (${b.nights} malam)'),
            _kv('Nama tamu', b.guestName),
            const _Dashed(),
            _kv('${rupiah(b.pricePerNight)} × ${b.nights} mlm × ${b.rooms} kmr', rupiah(b.totalPrice)),
            _kv('Biaya layanan', rupiah(b.serviceFee)),
            _kv('Total dibayar', rupiah(amount), strong: true, color: AppTheme.price),
          ]),
        ),
        const SizedBox(height: 18),
        // ---------- QR untuk check-in ----------
        AppCard(
          child: Column(children: [
            const Text('QR Check-in', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
            const SizedBox(height: 4),
            const Text('Tunjukkan QR ini ke resepsionis saat check-in',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            const SizedBox(height: 14),
            BarcodeWidget(
              barcode: Barcode.qrCode(),
              data: 'STAYEASE|${b.code}|$receipt',
              width: 180,
              height: 180,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (r) => AppTheme.mainGradient.createShader(r),
              child: Text(b.code,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
            ),
          ]),
        ),
      ]),
      bottomNavigationBar: justPaid
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GradientButton(
                  label: 'Selesai',
                  icon: Icons.done_all_rounded,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            )
          : null,
    );
  }

  Widget _kv(String k, String v, {bool strong = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5, child: Text(k, style: const TextStyle(color: AppTheme.muted, fontSize: 13))),
          Expanded(
            flex: 6,
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
                  fontSize: strong ? 15 : 13,
                  color: color ?? AppTheme.ink,
                )),
          ),
        ]),
      );
}

/// Garis putus-putus pemisah ala struk
class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(
          builder: (_, c) => Row(
            children: List.generate(
              (c.maxWidth / 9).floor(),
              (_) => Container(width: 5, height: 1.5, margin: const EdgeInsets.only(right: 4), color: const Color(0xFFD9D4EE)),
            ),
          ),
        ),
      );
}
