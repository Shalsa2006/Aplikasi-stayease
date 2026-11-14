import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/hotel.dart';
import '../../services/hotel_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_shell.dart';
import 'hotel_form_screen.dart';

/// Daftar semua hotel per kota + tambah/ubah/hapus.
class AdminHotelsScreen extends StatefulWidget {
  const AdminHotelsScreen({super.key});

  @override
  State<AdminHotelsScreen> createState() => _AdminHotelsScreenState();
}

class _AdminHotelsScreenState extends State<AdminHotelsScreen> {
  final _service = HotelService();
  List<Hotel> _hotels = [];
  String? _city;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _hotels.isEmpty;
      _error = null;
    });
    try {
      final h = await _service.getHotels(includeEmpty: true);
      if (mounted) setState(() => _hotels = h);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open({int? hotelId}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => HotelFormScreen(hotelId: hotelId)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final cities = _hotels.map((h) => h.city).toSet().toList()..sort();
    final shown = _city == null ? _hotels : _hotels.where((h) => h.city == _city).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.admin,
        foregroundColor: Colors.white,
        onPressed: () => _open(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Hotel', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(children: [
        AdminHeader(
          title: 'Kelola Hotel',
          subtitle: '${_hotels.length} hotel di ${cities.length} kota',
          actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: Colors.white))],
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            children: [
              _chip('Semua', null),
              for (final c in cities) _chip('$c (${_hotels.where((h) => h.city == c).length})', c),
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
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: shown.length,
                        itemBuilder: (_, i) {
                          final h = shown[i];
                          return AppCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              onTap: () => _open(hotelId: h.id),
                              leading: NetImage(h.imageUrl, width: 64, height: 64, radius: BorderRadius.circular(12)),
                              title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  StarRow(h.star),
                                  const SizedBox(width: 6),
                                  Text(h.city, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                                ]),
                                Text(
                                  'mulai ${rupiah(h.minPrice)}'
                                  '${h.rating != null ? ' · ★ ${h.rating!.toStringAsFixed(1)} (${h.reviewCount})' : ''}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.admin, fontWeight: FontWeight.w700),
                                ),
                              ]),
                              trailing: const Icon(Icons.edit_rounded, color: AppTheme.admin),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _chip(String label, String? city) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _city == city,
          showCheckmark: false,
          selectedColor: AppTheme.admin,
          backgroundColor: AppTheme.admin.withValues(alpha: 0.08),
          labelStyle: TextStyle(color: _city == city ? Colors.white : AppTheme.admin, fontWeight: FontWeight.w700),
          onSelected: (_) => setState(() => _city = city),
        ),
      );
}
