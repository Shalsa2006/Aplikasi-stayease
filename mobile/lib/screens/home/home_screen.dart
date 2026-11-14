import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/hotel.dart';
import '../../providers/auth_provider.dart';
import '../../services/hotel_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/hotel_card.dart';
import '../hotel/hotel_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = HotelService();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Hotel> _hotels = [];
  List<String> _cities = [];
  String? _city;
  String _sort = '';
  int _guests = 2;
  late DateTimeRange _dates;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _dates = DateTimeRange(start: today.add(const Duration(days: 1)), end: today.add(const Duration(days: 2)));
    _loadCities();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final c = await _service.getCities();
      if (mounted) setState(() => _cities = c);
    } catch (_) {/* abaikan; daftar kota opsional */}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getHotels(
        q: _searchCtrl.text.trim(),
        city: _city,
        guests: _guests,
        sort: _sort.isEmpty ? null : _sort,
      );
      if (mounted) setState(() => _hotels = data);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _load);
  }

  Future<void> _pickDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: _dates,
      helpText: 'Pilih tanggal menginap',
      saveText: 'Simpan',
    );
    if (picked != null && picked.duration.inDays >= 1) setState(() => _dates = picked);
  }

  void _pickGuests() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(24),
          child: Row(children: [
            const Text('Jumlah tamu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton.outlined(
              onPressed: _guests > 1 ? () => setSheet(() => setState(() => _guests--)) : null,
              icon: const Icon(Icons.remove),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('$_guests', style: const TextStyle(fontSize: 18))),
            IconButton.outlined(
              onPressed: _guests < 10 ? () => setSheet(() => setState(() => _guests++)) : null,
              icon: const Icon(Icons.add),
            ),
          ]),
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().user?.name.split(' ').first ?? '';
    final nights = _dates.duration.inDays;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.mainGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(children: [
                // lingkaran dekoratif
                Positioned(top: -40, right: -30, child: _Bubble(160, Colors.white.withValues(alpha: 0.10))),
                Positioned(bottom: -50, left: -40, child: _Bubble(140, AppTheme.orange.withValues(alpha: 0.25))),
                Positioned(top: 60, right: 70, child: _Bubble(26, AppTheme.accent.withValues(alpha: 0.6))),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 18, 20, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Halo, $name 👋', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                          const SizedBox(height: 4),
                          const Text('Mau menginap\ndi mana hari ini?',
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.2)),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
                      ),
                    ]),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Cari hotel, kota, atau alamat',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        flex: 3,
                        child: _Pill(
                          icon: Icons.calendar_month_rounded,
                          color: AppTheme.pink,
                          text: '${tanggalPendek(_dates.start)} – ${tanggalPendek(_dates.end)} · $nights mlm',
                          onTap: _pickDates,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _Pill(icon: Icons.people_alt_rounded, color: AppTheme.orange, text: '$_guests tamu', onTap: _pickGuests),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  _chip('Semua kota', _city == null, () => setState(() => _city = null), 0),
                  for (var i = 0; i < _cities.length; i++)
                    _chip(_cities[i], _city == _cities[i], () => setState(() => _city = _cities[i]), i + 1),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Text(_loading ? 'Memuat...' : '${_hotels.length} hotel ditemukan',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
                const Spacer(),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Rekomendasi')),
                    DropdownMenuItem(value: 'price_asc', child: Text('Harga terendah')),
                    DropdownMenuItem(value: 'price_desc', child: Text('Harga tertinggi')),
                    DropdownMenuItem(value: 'rating', child: Text('Rating tertinggi')),
                  ],
                  onChanged: (v) {
                    setState(() => _sort = v ?? '');
                    _load();
                  },
                ),
              ]),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            SliverFillRemaining(hasScrollBody: false, child: ErrorView(message: _error!, onRetry: _load))
          else if (_hotels.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Tidak ada hotel yang cocok.\nCoba ubah kata kunci atau jumlah tamu.', textAlign: TextAlign.center)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.separated(
                itemCount: _hotels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (_, i) => HotelCard(
                  hotel: _hotels[i],
                  colorIndex: i,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HotelDetailScreen(hotelId: _hotels[i].id, dates: _dates, guests: _guests),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, int colorIndex) {
    final color = AppTheme.pickColor(colorIndex);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        avatar: selected ? null : Icon(Icons.location_city_rounded, size: 16, color: color),
        labelStyle: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w700),
        backgroundColor: color.withValues(alpha: 0.10),
        selectedColor: color,
        onSelected: (_) {
          onTap();
          _load();
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final Color color;
  const _Bubble(this.size, this.color);

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;
  const _Pill({required this.icon, required this.text, required this.onTap, this.color = AppTheme.primary});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.ink)),
              ),
            ]),
          ),
        ),
      );
}
