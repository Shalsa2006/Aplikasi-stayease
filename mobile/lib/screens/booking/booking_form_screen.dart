import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/hotel.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../payment/payment_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final Hotel hotel;
  final Room room;
  final DateTimeRange dates;
  final int guests;
  const BookingFormScreen({super.key, required this.hotel, required this.room, required this.dates, required this.guests});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _notes = TextEditingController();
  late int _rooms;
  late int _guests;
  bool _loading = false;

  /// Maksimal kamar yang boleh dipesan = sisa kamar (jika diketahui), maks 10
  int get _maxRooms => min(10, widget.room.available ?? widget.room.totalRooms).clamp(1, 10);
  int get _maxGuests => widget.room.capacity * _rooms;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    // Jumlah kamar awal otomatis menyesuaikan jumlah tamu
    _rooms = (widget.guests / widget.room.capacity).ceil().clamp(1, _maxRooms);
    _guests = widget.guests.clamp(1, _maxGuests);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  int get _nights => widget.dates.duration.inDays;
  // Total langsung dihitung: harga × malam × kamar
  int get _total => widget.room.pricePerNight * _nights * _rooms;

  void _setRooms(int v) => setState(() {
        _rooms = v;
        if (_guests > _maxGuests) _guests = _maxGuests;
      });

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final booking = await BookingService().create(
        roomId: widget.room.id,
        checkIn: widget.dates.start,
        checkOut: widget.dates.end,
        guests: _guests,
        rooms: _rooms,
        guestName: _name.text.trim(),
        guestPhone: _phone.text.trim(),
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      showSnack(context, 'Pesanan ${booking.code} dibuat, silakan bayar');
      // Langsung ke halaman pembayaran
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
        result: true,
      );
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pemesanan')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              NetImage(widget.room.imageUrl, width: 82, height: 82, radius: BorderRadius.circular(14)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.hotel.name, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.ink)),
                  Text(widget.room.type, style: t.bodyMedium?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_month_rounded, size: 14, color: AppTheme.pink),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('${tanggalPendek(widget.dates.start)} → ${tanggal(widget.dates.end)}',
                          style: t.bodySmall?.copyWith(color: AppTheme.muted)),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(children: [
              _Counter(
                icon: Icons.bed_rounded,
                color: AppTheme.primary,
                label: 'Jumlah kamar',
                hint: widget.room.available != null ? 'Sisa ${widget.room.available} kamar' : null,
                value: _rooms,
                min: 1,
                max: _maxRooms,
                onChanged: _setRooms,
              ),
              const Divider(height: 24),
              _Counter(
                icon: Icons.people_alt_rounded,
                color: AppTheme.orange,
                label: 'Jumlah tamu',
                hint: 'Maks $_maxGuests orang',
                value: _guests,
                min: 1,
                max: _maxGuests,
                onChanged: (v) => setState(() => _guests = v),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Data Tamu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama tamu (sesuai KTP)', prefixIcon: Icon(Icons.badge_outlined)),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'No. HP', prefixIcon: Icon(Icons.phone_outlined)),
            validator: (v) => (v == null || v.trim().length < 9) ? 'No. HP tidak valid' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Permintaan khusus (opsional)',
              hintText: 'Contoh: kamar non-smoking',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 20),
          // Rincian harga — berubah otomatis saat jumlah kamar diubah
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF1EBFF), Color(0xFFFFEAF3)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(children: [
              _row('Harga per malam', rupiah(widget.room.pricePerNight)),
              _row('Lama menginap', '× $_nights malam'),
              _row('Jumlah kamar', '× $_rooms kamar'),
              const Divider(height: 20),
              Row(children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Text(
                    rupiah(_total),
                    key: ValueKey(_total),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.price),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Biaya layanan dihitung saat memilih metode pembayaran',
                    style: TextStyle(fontSize: 11, color: AppTheme.muted)),
              ),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: GradientButton(
            label: 'Pesan & Bayar · ${rupiah(_total)}',
            icon: Icons.lock_rounded,
            loading: _loading,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String r) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(l, style: const TextStyle(color: AppTheme.muted)),
          const Spacer(),
          Text(r, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink)),
        ]),
      );
}

class _Counter extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? hint;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Counter({
    required this.icon,
    required this.color,
    required this.label,
    this.hint,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        IconBadge(icon, color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
            if (hint != null) Text(hint!, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
          ]),
        ),
        _roundBtn(Icons.remove_rounded, value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 40,
          child: Text('$value',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink)),
        ),
        _roundBtn(Icons.add_rounded, value < max ? () => onChanged(value + 1) : null),
      ]);

  Widget _roundBtn(IconData i, VoidCallback? onTap) => Material(
        color: onTap == null ? const Color(0xFFEDEBF5) : color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(i, size: 20, color: onTap == null ? AppTheme.muted : Colors.white),
          ),
        ),
      );
}
