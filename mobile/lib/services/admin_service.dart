import '../models/admin.dart';
import '../models/booking.dart';
import '../utils/format.dart';
import 'api_client.dart';

/// Semua pemanggilan API khusus admin (butuh login sebagai admin)
class AdminService {
  Future<AdminStats> stats() async => AdminStats.fromJson(await ApiClient.get('/admin/stats'));

  Future<List<AdminBooking>> bookings({BookingStatus? status, String? q}) async {
    final data = await ApiClient.get('/admin/bookings', query: {'status': status?.name, 'q': q});
    return (data as List).map((e) => AdminBooking.fromJson(e)).toList();
  }

  Future<AdminBooking> updateStatus(int id, BookingStatus status) async =>
      AdminBooking.fromJson(await ApiClient.patch('/admin/bookings/$id/status', {'status': status.name}));

  Future<BookedRoomsResult> bookedRooms(DateTime date) async =>
      BookedRoomsResult.fromJson(await ApiClient.get('/admin/rooms/booked', query: {'date': apiDate(date)}));

  Future<List<ReviewItem>> reviews({int? rating}) async {
    final data = await ApiClient.get('/admin/reviews', query: {'rating': rating});
    return (data as List).map((e) => ReviewItem.fromJson(e)).toList();
  }

  Future<void> deleteReview(int id) => ApiClient.delete('/admin/reviews/$id');

  // ----- hotel & kamar -----
  Future<void> createHotel(Map<String, dynamic> data) => ApiClient.post('/admin/hotels', data);
  Future<void> updateHotel(int id, Map<String, dynamic> data) => ApiClient.put('/admin/hotels/$id', data);
  Future<void> deleteHotel(int id) => ApiClient.delete('/admin/hotels/$id');

  Future<void> createRoom(Map<String, dynamic> data) => ApiClient.post('/admin/rooms', data);
  Future<void> updateRoom(int id, Map<String, dynamic> data) => ApiClient.put('/admin/rooms/$id', data);
  Future<void> deleteRoom(int id) => ApiClient.delete('/admin/rooms/$id');
}
