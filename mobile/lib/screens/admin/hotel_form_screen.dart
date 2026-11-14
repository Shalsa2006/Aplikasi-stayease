import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/hotel.dart';
import '../../services/admin_service.dart';
import '../../services/hotel_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Foto yang tersedia di dalam aplikasi (mobile/assets/images).
/// Tambahkan nama file di sini bila kamu menaruh foto baru di folder tersebut.
const assetPhotos = [
  'assets/images/hotel_1.jpg',
  'assets/images/hotel_2.jpg',
  'assets/images/hotel_5.jpg',
  'assets/images/hotel_6.jpg',
  'assets/images/hotel_7.jpg',
  'assets/images/hotel_8.jpg',
  'assets/images/hotel_9.jpg',
  'assets/images/hotel_10.jpg',
  'assets/images/hotel_11.jpg',
  'assets/images/hotel_12.jpg',
  'assets/images/hotel_13.jpg',
  'assets/images/hotel_14.jpg',
  'assets/images/hotel_15.jpg',
  'assets/images/hotel_16.jpg',
  'assets/images/hotel_17.jpg',
  'assets/images/hotel_18.jpg',
  'assets/images/room_king_classic.jpg',
  'assets/images/room_marble_suite.jpg',
  'assets/images/room_twin_blue.jpg',
  'assets/images/room_twin_wood.jpg',
  'assets/images/room_twin_bronze.jpg',
  'assets/images/room_mountain_view.jpg',
  'assets/images/room_galaxy_suite.jpg',
  'assets/images/room_chandelier.jpg',
];

/// Tambah hotel baru (hotelId = null) atau ubah hotel + kelola tipe kamarnya.
class HotelFormScreen extends StatefulWidget {
  final int? hotelId;
  const HotelFormScreen({super.key, this.hotelId});

  @override
  State<HotelFormScreen> createState() => _HotelFormScreenState();
}

class _HotelFormScreenState extends State<HotelFormScreen> {
  final _admin = AdminService();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _desc = TextEditingController();
  final _facilities = TextEditingController();
  String _image = assetPhotos.first;
  int _star = 3;
  Hotel? _hotel;
  bool _loading = false;
  bool _saving = false;
  bool _changed = false;

  bool get _isNew => widget.hotelId == null;

  @override
  void initState() {
    super.initState();
    if (!_isNew) _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _city, _address, _desc, _facilities]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final h = await HotelService().getHotel(widget.hotelId!);
      if (!mounted) return;
      setState(() {
        _hotel = h;
        _name.text = h.name;
        _city.text = h.city;
        _address.text = h.address;
        _desc.text = h.description;
        _facilities.text = h.facilities.join(', ');
        _star = h.star.clamp(1, 5);
        if (h.imageUrl.isNotEmpty) _image = h.imageUrl;
      });
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _name.text.trim(),
      'city': _city.text.trim(),
      'address': _address.text.trim(),
      'description': _desc.text.trim(),
      'star': _star,
      'image_url': _image,
      'facilities': _facilities.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    };
    try {
      if (_isNew) {
        await _admin.createHotel(data);
        if (!mounted) return;
        showSnack(context, 'Hotel ditambahkan. Buka lagi untuk menambah kamar.');
        Navigator.pop(context, true);
      } else {
        await _admin.updateHotel(widget.hotelId!, data);
        if (!mounted) return;
        _changed = true;
        showSnack(context, 'Hotel disimpan');
      }
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteHotel() async {
    final yes = await _confirm('Hapus hotel ini?', 'Semua kamar, pesanan, dan ulasan hotel ini ikut terhapus.');
    if (!yes) return;
    try {
      await _admin.deleteHotel(widget.hotelId!);
      if (!mounted) return;
      showSnack(context, 'Hotel dihapus');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
  }

  Future<bool> _confirm(String title, String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(100, 44), backgroundColor: const Color(0xFFE11D48)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _editRoom([Room? room]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RoomFormSheet(hotelId: widget.hotelId!, room: room),
    );
    if (saved == true) {
      _changed = true;
      _load();
    }
  }

  Future<void> _deleteRoom(Room r) async {
    final yes = await _confirm('Hapus kamar "${r.type}"?', 'Pesanan untuk tipe kamar ini ikut terhapus.');
    if (!yes) return;
    try {
      await _admin.deleteRoom(r.id);
      _changed = true;
      _load();
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'Tambah Hotel' : 'Ubah Hotel'),
          actions: [
            if (!_isNew)
              IconButton(
                tooltip: 'Hapus hotel',
                onPressed: _deleteHotel,
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48)),
              ),
          ],
        ),
        body: _loading && _hotel == null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _form,
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: NetImage(_image, height: 170, width: double.infinity),
                  ),
                  const SizedBox(height: 10),
                  const Text('Pilih foto', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      for (final p in assetPhotos)
                        GestureDetector(
                          onTap: () => setState(() => _image = p),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _image == p ? AppTheme.admin : Colors.transparent, width: 3),
                            ),
                            child: NetImage(p, width: 80, height: 60, radius: BorderRadius.circular(9)),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  _field(_name, 'Nama hotel', Icons.apartment_rounded, required: true),
                  _field(_city, 'Kota', Icons.location_city_rounded, required: true),
                  _field(_address, 'Alamat', Icons.place_outlined, required: true),
                  _field(_desc, 'Deskripsi', Icons.notes_rounded, maxLines: 3),
                  _field(_facilities, 'Fasilitas (pisahkan dengan koma)', Icons.checklist_rounded),
                  Row(children: [
                    const Text('Bintang', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
                    const Spacer(),
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _star = i),
                        icon: Icon(i <= _star ? Icons.star_rounded : Icons.star_outline_rounded, color: AppTheme.accent, size: 30),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  GradientButton(
                    label: _isNew ? 'Tambah Hotel' : 'Simpan Perubahan',
                    icon: Icons.save_rounded,
                    gradient: AppTheme.adminGradient,
                    loading: _saving,
                    onPressed: _save,
                  ),
                  if (!_isNew) ...[
                    const SizedBox(height: 26),
                    Row(children: [
                      const Expanded(
                        child: Text('Tipe Kamar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.ink)),
                      ),
                      TextButton.icon(
                        onPressed: () => _editRoom(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah kamar'),
                      ),
                    ]),
                    if (_hotel?.rooms.isEmpty ?? true)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Belum ada kamar. Hotel tanpa kamar tidak tampil di aplikasi pengguna.',
                            style: TextStyle(color: AppTheme.muted)),
                      ),
                    for (final (i, r) in (_hotel?.rooms ?? <Room>[]).indexed)
                      AppCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        child: Row(children: [
                          NetImage(r.imageUrl, width: 60, height: 60, radius: BorderRadius.circular(12)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r.type, style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.pickColor(i))),
                              Text('${rupiah(r.pricePerNight)}/malam',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.price, fontSize: 13)),
                              Text('${r.totalRooms} unit · maks ${r.capacity} orang',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                            ]),
                          ),
                          IconButton(onPressed: () => _editRoom(r), icon: const Icon(Icons.edit_rounded, color: AppTheme.admin)),
                          IconButton(
                            onPressed: () => _deleteRoom(r),
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48)),
                          ),
                        ]),
                      ),
                  ],
                ]),
              ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool required = false, int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null : null,
        ),
      );
}

/// Form tambah/ubah tipe kamar
class _RoomFormSheet extends StatefulWidget {
  final int hotelId;
  final Room? room;
  const _RoomFormSheet({required this.hotelId, this.room});

  @override
  State<_RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<_RoomFormSheet> {
  final _form = GlobalKey<FormState>();
  late final _type = TextEditingController(text: widget.room?.type ?? '');
  late final _desc = TextEditingController(text: widget.room?.description ?? '');
  late final _price = TextEditingController(text: widget.room == null ? '' : '${widget.room!.pricePerNight}');
  late final _capacity = TextEditingController(text: '${widget.room?.capacity ?? 2}');
  late final _total = TextEditingController(text: '${widget.room?.totalRooms ?? 5}');
  late String _image = (widget.room?.imageUrl.isNotEmpty ?? false) ? widget.room!.imageUrl : assetPhotos[4];
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_type, _desc, _price, _capacity, _total]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'hotel_id': widget.hotelId,
      'type': _type.text.trim(),
      'description': _desc.text.trim(),
      'price_per_night': int.parse(_price.text.trim()),
      'capacity': int.parse(_capacity.text.trim()),
      'total_rooms': int.parse(_total.text.trim()),
      'image_url': _image,
    };
    try {
      final admin = AdminService();
      if (widget.room == null) {
        await admin.createRoom(data);
      } else {
        await admin.updateRoom(widget.room!.id, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _number(String? v) => (int.tryParse(v?.trim() ?? '') ?? 0) > 0 ? null : 'Isi angka > 0';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.room == null ? 'Tambah Tipe Kamar' : 'Ubah Tipe Kamar',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.ink)),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final p in assetPhotos)
                  GestureDetector(
                    onTap: () => setState(() => _image = p),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _image == p ? AppTheme.admin : Colors.transparent, width: 3),
                      ),
                      child: NetImage(p, width: 72, height: 54, radius: BorderRadius.circular(9)),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _type,
              decoration: const InputDecoration(labelText: 'Nama tipe (mis. Deluxe)', prefixIcon: Icon(Icons.bed_rounded)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Deskripsi', prefixIcon: Icon(Icons.notes_rounded)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga per malam (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
              validator: _number,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Kapasitas', prefixIcon: Icon(Icons.people_outline)),
                  validator: _number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _total,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah unit', prefixIcon: Icon(Icons.numbers_rounded)),
                  validator: _number,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Simpan Kamar',
              icon: Icons.save_rounded,
              gradient: AppTheme.adminGradient,
              loading: _saving,
              onPressed: _save,
            ),
          ]),
        ),
      ),
    );
  }
}
