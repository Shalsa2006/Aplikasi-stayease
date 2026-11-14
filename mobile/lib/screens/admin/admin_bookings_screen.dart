import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/admin.dart';
import '../../models/booking.dart';
import '../../services/admin_service.dart';
import '../../widgets/common.dart';
import 'admin_booking_detail_sheet.dart';
import 'admin_shell.dart';

/// Semua pesanan dari semua pengguna, bisa difilter status & dicari.
class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _service = AdminService();
  final _search = TextEditingController();
  Timer? _debounce;
  BookingStatus? _status;
  List<AdminBooking> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final data = await _service.bookings(status: _status, q: _search.text.trim());
      if (mounted) setState(() => _items = data);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        AdminHeader(
          title: 'Semua Pesanan',
          subtitle: '${_items.length} pesanan ditampilkan',
          actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: Colors.white))],
          bottom: TextField(
            controller: _search,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), _load);
            },
            decoration: InputDecoration(
              hintText: 'Cari kode booking, nama tamu, email, hotel',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            children: [
              _chip('Semua', null),
              for (final s in BookingStatus.values) _chip(s.label, s),
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
                              Center(child: Text('Tidak ada pesanan', style: TextStyle(color: AppTheme.muted))),
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _items.length,
                              itemBuilder: (_, i) => AdminBookingTile(
                                item: _items[i],
                                onTap: () async {
                                  final updated = await showAdminBookingSheet(context, _items[i]);
                                  if (updated != null) _load();
                                },
                              ),
                            ),
                    ),
        ),
      ]),
    );
  }

  Widget _chip(String label, BookingStatus? s) {
    final selected = _status == s;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppTheme.admin,
        backgroundColor: AppTheme.admin.withValues(alpha: 0.08),
        labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.admin, fontWeight: FontWeight.w700),
        onSelected: (_) {
          setState(() => _status = s);
          _load();
        },
      ),
    );
  }
}
