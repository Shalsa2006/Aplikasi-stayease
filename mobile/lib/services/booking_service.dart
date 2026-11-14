import '../models/booking.dart';
import '../utils/format.dart';
import 'api_client.dart';

class BookingService {
  Future<Booking> create({
    required int roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    int rooms = 1,
    required String guestName,
    required String guestPhone,
    String? notes,
  }) async {
    final data = await ApiClient.post('/bookings', {
      'room_id': roomId,
      'check_in': apiDate(checkIn),
      'check_out': apiDate(checkOut),
      'guests': guests,
      'rooms': rooms,
      'guest_name': guestName,
      'guest_phone': guestPhone,
      'notes': notes,
    });
    return Booking.fromJson(data);
  }

  Future<List<Booking>> myBookings() async {
    final data = await ApiClient.get('/bookings');
    return (data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<Booking> detail(int id) async => Booking.fromJson(await ApiClient.get('/bookings/$id'));

  /// Membuat tagihan: nomor Virtual Account (pilih bank) atau kode QRIS.
  Future<Booking> createPayment(int id, PaymentMethod method, {String? bank}) async =>
      Booking.fromJson(await ApiClient.post('/bookings/$id/payment', {'method': method.name, 'bank': bank}));

  /// Simulasi konfirmasi pembayaran → status "paid" + nomor bukti pembayaran.
  Future<Booking> pay(int id) async => Booking.fromJson(await ApiClient.patch('/bookings/$id/pay'));

  Future<Booking> cancel(int id) async => Booking.fromJson(await ApiClient.patch('/bookings/$id/cancel'));
}
