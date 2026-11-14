import 'package:flutter/foundation.dart';

import '../models/hotel.dart';
import '../services/favorite_service.dart';

/// Menyimpan daftar hotel yang disukai user, dipakai oleh ikon hati di semua halaman.
class FavoriteProvider extends ChangeNotifier {
  final _service = FavoriteService();

  List<Hotel> hotels = [];
  final Set<int> _ids = {};
  bool loading = false;
  String? error;

  bool isFavorite(int hotelId) => _ids.contains(hotelId);
  int get count => _ids.length;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      hotels = await _service.list();
      _ids
        ..clear()
        ..addAll(hotels.map((h) => h.id));
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Tambah/hapus favorit. Tampilan langsung berubah (optimistic), dikembalikan bila API gagal.
  Future<bool> toggle(Hotel hotel) async {
    final wasFav = isFavorite(hotel.id);
    if (wasFav) {
      _ids.remove(hotel.id);
      hotels.removeWhere((h) => h.id == hotel.id);
    } else {
      _ids.add(hotel.id);
      hotels.insert(0, hotel);
    }
    notifyListeners();
    try {
      if (wasFav) {
        await _service.remove(hotel.id);
      } else {
        await _service.add(hotel.id);
      }
      return !wasFav;
    } catch (e) {
      // rollback
      if (wasFav) {
        _ids.add(hotel.id);
        hotels.insert(0, hotel);
      } else {
        _ids.remove(hotel.id);
        hotels.removeWhere((h) => h.id == hotel.id);
      }
      notifyListeners();
      rethrow;
    }
  }

  void clear() {
    hotels = [];
    _ids.clear();
    notifyListeners();
  }
}
