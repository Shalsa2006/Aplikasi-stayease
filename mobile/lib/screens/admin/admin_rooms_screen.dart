import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/admin.dart';
import '../../services/admin_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_shell.dart';

/// Kamar yang dipesan pada tanggal tertentu: per hotel & tipe kamar,
/// lengkap dengan daftar tamu yang menempati.
class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key});

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  final _service = AdminService();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  BookedRoomsResult? _data;
  String? _error;
  bool _loading = true;
  bool _onlyBooked = true;
  String? _city;

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
      final d = await _service.bookedRooms(_date);
      if (mounted) setState(() => _data = d);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Lihat kamar terpesan pada',
    );
    if (picked != null) {
      setState(() => _date = picked);
      _load();
    }
  }

  void _shiftDay(int d) {
    setState(() => _date = _date.add(Duration(days: d)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final cities = d == null ? <String>[] : d.rooms.map((r) => r.hotelCity).toSet().toList();
    var rooms = d?.rooms ?? <BookedRoom>[];
    if (_onlyBooked) rooms = rooms.where((r) => r.booked > 0).toList();
    if (_city != null) rooms = rooms.where((r) => r.hotelCity == _city).toList();

    // kelompokkan per hotel
    final groups = <int, List<BookedRoom>>{};
    for (final r in rooms) {
      groups.putIfAbsent(r.hotelId, () => []).add(r);
    }

    return Scaffold(
      body: Column(children: [
        AdminHeader(
          title: 'Kamar Terpesan',
          subtitle: d == null ? 'Memuat...' : '${d.totalBooked} dari ${d.totalRooms} kamar terisi',
          bottom: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              IconButton(onPressed: () => _shiftDay(-1), icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.admin)),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.admin),
                      const SizedBox(width: 6),
                      Text(tanggal(_date), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
                    ]),
                  ),
                ),
              ),
              IconButton(onPressed: () => _shiftDay(1), icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.admin)),
            ]),
          ),
        ),
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            children: [
              FilterChip(
                label: const Text('Hanya yang terpesan'),
                selected: _onlyBooked,
                selectedColor: AppTheme.admin.withValues(alpha: 0.18),
                checkmarkColor: AppTheme.admin,
                onSelected: (v) => setState(() => _onlyBooked = v),
              ),
              const SizedBox(width: 8),
              _cityChip('Semua kota', null),
              for (final c in cities) _cityChip(c, c),
            ],
          ),
        ),
        Expanded(
          child: _loading && d == null
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: groups.isEmpty
                          ? ListView(children: [
                              const SizedBox(height: 90),
                              const Center(child: IconBadge(Icons.bed_rounded, AppTheme.admin, size: 44)),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  _onlyBooked ? 'Tidak ada kamar terpesan pada ${tanggal(_date)}' : 'Tidak ada data kamar',
                                  style: const TextStyle(color: AppTheme.muted),
                                ),
                              ),
                            ])
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              children: [
                                for (final entry in groups.entries) _HotelGroup(rooms: entry.value),
                              ],
                            ),
                    ),
        ),
      ]),
    );
  }

  Widget _cityChip(String label, String? city) => Padding(
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

class _HotelGroup extends StatelessWidget {
  final List<BookedRoom> rooms;
  const _HotelGroup({required this.rooms});

  @override
  Widget build(BuildContext context) {
    final first = rooms.first;
    final booked = rooms.fold<int>(0, (s, r) => s + r.booked);
    final total = rooms.fold<int>(0, (s, r) => s + r.totalRooms);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const IconBadge(Icons.apartment_rounded, AppTheme.admin),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(first.hotelName, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.ink)),
              Text(first.hotelCity, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
            ]),
          ),
          Text('$booked/$total', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.admin, fontSize: 16)),
        ]),
        const SizedBox(height: 10),
        for (final (i, r) in rooms.indexed) _RoomRow(room: r, color: AppTheme.pickColor(i)),
      ]),
    );
  }
}

class _RoomRow extends StatelessWidget {
  final BookedRoom room;
  final Color color;
  const _RoomRow({required this.room, required this.color});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Row(children: [
          Expanded(child: Text(room.type, style: TextStyle(fontWeight: FontWeight.w800, color: color))),
          Text('${room.booked} terpesan · ${room.available} kosong',
              style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: room.occupancy.clamp(0, 1).toDouble(),
              minHeight: 8,
              color: room.available == 0 ? const Color(0xFFE11D48) : color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ),
        children: [
          for (final b in room.bookings)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                  child: Text('${b.rooms}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${b.guestName} · ${b.code}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
                    Text('${tanggalPendek(b.checkIn)} – ${tanggalPendek(b.checkOut)} · ${b.guests} tamu · ${b.guestPhone}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                  ]),
                ),
                StatusChip(b.status),
              ]),
            ),
        ],
      ),
    );
  }
}
