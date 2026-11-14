import 'dart:async';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'receipt_screen.dart';

/// Warna khas tiap bank untuk tampilan Virtual Account
const bankColors = {
  'BCA': Color(0xFF0060AF),
  'BNI': Color(0xFFF15A23),
  'BRI': Color(0xFF00529C),
  'MANDIRI': Color(0xFF003D79),
};

/// Halaman pembayaran (simulasi):
/// 1. Pilih metode → Virtual Account (pilih bank) atau QRIS; total + biaya layanan langsung dihitung.
/// 2. Tagihan dibuat → tampil nomor VA / kode QR + barcode + jumlah yang harus dibayar.
/// 3. "Saya Sudah Bayar" → status lunas & muncul bukti pembayaran.
class PaymentScreen extends StatefulWidget {
  final Booking booking;
  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _service = BookingService();
  late Booking _b = widget.booking;
  PaymentMethod _method = PaymentMethod.va;
  String _bank = 'BCA';
  bool _busy = false;
  bool _changing = false; // user menekan "Ganti metode"
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (_b.paymentMethod != null) _method = _b.paymentMethod!;
    if (_b.paymentBank != null) _bank = _b.paymentBank!;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    void tick() {
      final exp = _b.paymentExpiresAt;
      if (!mounted) return;
      setState(() => _left = exp == null ? Duration.zero : exp.difference(DateTime.now()));
    }

    tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  bool get _showInvoice => _b.hasActiveInvoice && !_changing;
  int get _fee => serviceFeeFor(_method, _b.totalPrice);
  int get _grandTotal => _b.totalPrice + _fee;

  Future<void> _createInvoice() async {
    setState(() => _busy = true);
    try {
      final b = await _service.createPayment(_b.id, _method, bank: _method == PaymentMethod.va ? _bank : null);
      if (!mounted) return;
      setState(() {
        _b = b;
        _changing = false;
      });
      _startTimer();
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmPaid() async {
    setState(() => _busy = true);
    try {
      final b = await _service.pay(_b.id);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ReceiptScreen(booking: b, justPaid: true)),
        result: true,
      );
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showSnack(context, '$label disalin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(_showInvoice ? 'Selesaikan Pembayaran' : 'Pilih Pembayaran')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: _showInvoice ? _invoiceView() : _methodView(),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _showInvoice
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    GradientButton(
                      label: 'Saya Sudah Bayar',
                      icon: Icons.verified_rounded,
                      gradient: AppTheme.mintGradient,
                      loading: _busy,
                      onPressed: _confirmPaid,
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _changing = true),
                      child: const Text('Ganti metode pembayaran'),
                    ),
                  ])
                : GradientButton(
                    label: 'Bayar ${rupiah(_grandTotal)}',
                    icon: Icons.lock_rounded,
                    loading: _busy,
                    onPressed: _createInvoice,
                  ),
          ),
        ),
    );
  }

  // ---------------- Langkah 1: pilih metode ----------------
  List<Widget> _methodView() => [
        _OrderSummary(b: _b),
        const SizedBox(height: 20),
        const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
        const SizedBox(height: 10),
        _MethodCard(
          selected: _method == PaymentMethod.va,
          icon: Icons.account_balance_rounded,
          color: AppTheme.primary,
          title: 'Transfer Virtual Account',
          subtitle: 'BCA · BNI · BRI · Mandiri — biaya Rp 4.000',
          onTap: () => setState(() => _method = PaymentMethod.va),
          child: _method != PaymentMethod.va
              ? null
              : Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final bank in vaBanks)
                    ChoiceChip(
                      label: Text(bank),
                      selected: _bank == bank,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _bank == bank ? Colors.white : bankColors[bank],
                      ),
                      selectedColor: bankColors[bank],
                      backgroundColor: bankColors[bank]!.withValues(alpha: 0.08),
                      onSelected: (_) => setState(() => _bank = bank),
                    ),
                ]),
        ),
        const SizedBox(height: 12),
        _MethodCard(
          selected: _method == PaymentMethod.qris,
          icon: Icons.qr_code_2_rounded,
          color: AppTheme.pink,
          title: 'QRIS',
          subtitle: 'Scan pakai GoPay, OVO, DANA, ShopeePay, m-banking — biaya 0,7%',
          onTap: () => setState(() => _method = PaymentMethod.qris),
        ),
        const SizedBox(height: 20),
        _PriceBreakdown(subtotal: _b.totalPrice, fee: _fee, feeLabel: _method == PaymentMethod.va ? 'Biaya layanan VA' : 'Biaya layanan QRIS (0,7%)'),
      ];

  // ---------------- Langkah 2: tagihan ----------------
  List<Widget> _invoiceView() {
    final amount = _b.paymentAmount ?? _b.totalPrice;
    final expired = _left.isNegative || _left == Duration.zero;
    String two(int n) => n.toString().padLeft(2, '0');
    final countdown = '${two(_left.inHours)}:${two(_left.inMinutes % 60)}:${two(_left.inSeconds % 60)}';

    return [
      // batas waktu
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(gradient: AppTheme.warmGradient, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.timer_outlined, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Bayar sebelum', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_b.paymentExpiresAt == null ? '-' : tanggalJam(_b.paymentExpiresAt!),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
          Text(expired ? 'Kedaluwarsa' : countdown,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()])),
        ]),
      ),
      const SizedBox(height: 16),
      if (_b.paymentMethod == PaymentMethod.va) _vaCard(amount) else _qrisCard(amount),
      const SizedBox(height: 16),
      _PriceBreakdown(
        subtotal: _b.totalPrice,
        fee: _b.serviceFee,
        feeLabel: _b.paymentMethod == PaymentMethod.va ? 'Biaya layanan VA' : 'Biaya layanan QRIS (0,7%)',
      ),
      const SizedBox(height: 12),
      _OrderSummary(b: _b),
      const SizedBox(height: 8),
      const Text(
        'Ini simulasi untuk keperluan tugas — tidak ada uang sungguhan yang ditarik. '
        'Tekan "Saya Sudah Bayar" untuk menganggap pembayaran berhasil.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: AppTheme.muted),
      ),
    ];
  }

  Widget _vaCard(int amount) {
    final bank = _b.paymentBank ?? '';
    final color = bankColors[bank] ?? AppTheme.primary;
    final va = _b.vaNumber ?? '';
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Text(bank, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Virtual Account', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
          ),
        ]),
        const SizedBox(height: 16),
        const Text('Nomor Virtual Account', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: Text(groupDigits(va),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
          ),
          _CopyChip(onTap: () => _copy(va, 'Nomor VA'), color: color),
        ]),
        const Divider(height: 28),
        const Text('Jumlah yang harus dibayar', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: Text(rupiah(amount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.price)),
          ),
          _CopyChip(onTap: () => _copy('$amount', 'Jumlah'), color: AppTheme.price),
        ]),
        const SizedBox(height: 4),
        const Text('Transfer tepat sesuai jumlah di atas.', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Cara bayar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            children: [
              for (final (i, step) in [
                'Buka aplikasi m-banking / ATM $bank.',
                'Pilih menu Transfer → Virtual Account.',
                'Masukkan nomor VA ${groupDigits(va)}.',
                'Pastikan nama "StayEase" dan jumlah ${rupiah(amount)} sudah benar.',
                'Konfirmasi dengan PIN, lalu kembali ke aplikasi ini.',
              ].indexed)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(radius: 12, backgroundColor: color, child: Text('${i + 1}', style: const TextStyle(fontSize: 11, color: Colors.white))),
                  title: Text(step),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _qrisCard(int amount) {
    final ref = _b.qrisRef ?? '';
    // Isi QR (simulasi). Pada sistem nyata, payload QRIS dibuat oleh payment gateway.
    final payload = 'STAYEASE|QRIS|$ref|${_b.code}|$amount';
    return AppCard(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ShaderMask(
            shaderCallback: (r) => AppTheme.warmGradient.createShader(r),
            child: const Text('QRIS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
          ),
          const SizedBox(width: 8),
          const Text('StayEase Hotel Booking', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.pink.withValues(alpha: 0.4), width: 2),
          ),
          child: BarcodeWidget(barcode: Barcode.qrCode(), data: payload, width: 210, height: 210, color: AppTheme.ink),
        ),
        const SizedBox(height: 14),
        const Text('Total yang harus dibayar', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
        Text(rupiah(amount), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.price)),
        const SizedBox(height: 14),
        BarcodeWidget(
          barcode: Barcode.code128(),
          data: ref,
          width: 260,
          height: 56,
          drawText: false,
          color: AppTheme.ink,
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Text(ref, style: const TextStyle(fontSize: 12, letterSpacing: 1, color: AppTheme.muted))),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.pink),
            onPressed: () => _copy(ref, 'Kode QRIS'),
          ),
        ]),
        const Text('Scan QR dengan aplikasi e-wallet atau m-banking apa pun yang mendukung QRIS.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.muted)),
      ]),
    );
  }
}

// ---------------- Widget pendukung ----------------

class _OrderSummary extends StatelessWidget {
  final Booking b;
  const _OrderSummary({required this.b});

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          NetImage(b.hotelImage, width: 64, height: 64, radius: BorderRadius.circular(12)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.hotelName, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
              Text('${b.roomType} · ${b.rooms} kamar · ${b.nights} malam',
                  style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              Text('${tanggalPendek(b.checkIn)} – ${tanggal(b.checkOut)} · Kode ${b.code}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
            ]),
          ),
        ]),
      );
}

class _PriceBreakdown extends StatelessWidget {
  final int subtotal;
  final int fee;
  final String feeLabel;
  const _PriceBreakdown({required this.subtotal, required this.fee, required this.feeLabel});

  @override
  Widget build(BuildContext context) {
    Widget row(String l, String r, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Text(l, style: TextStyle(color: bold ? AppTheme.ink : AppTheme.muted, fontWeight: bold ? FontWeight.w800 : FontWeight.normal)),
            const Spacer(),
            Text(r,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                  fontSize: bold ? 18 : 14,
                  color: bold ? AppTheme.price : AppTheme.ink,
                )),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF1EBFF), Color(0xFFFFEAF3)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: [
        row('Harga kamar', rupiah(subtotal)),
        row(feeLabel, rupiah(fee)),
        const Divider(height: 18),
        row('Total bayar', rupiah(subtotal + fee), bold: true),
      ]),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? child;

  const _MethodCard({
    required this.selected,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : Colors.transparent, width: 2),
          boxShadow: AppTheme.softShadow(color),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconBadge(icon, color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                    ]),
                  ),
                  Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: selected ? color : AppTheme.muted),
                ]),
                if (child != null) ...[const SizedBox(height: 12), child!],
              ]),
            ),
          ),
        ),
      );
}

class _CopyChip extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  const _CopyChip({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(Icons.copy_rounded, size: 16, color: color),
        label: Text('Salin', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        backgroundColor: color.withValues(alpha: 0.10),
        onPressed: onTap,
      );
}
