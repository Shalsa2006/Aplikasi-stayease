import '../models/admin.dart';
import '../models/hotel.dart';
import '../utils/format.dart';
import 'api_client.dart';

class HotelService {
  Future<List<Hotel>> getHotels({String? q, String? city, int? guests, String? sort, bool includeEmpty = false}) async {
    final data = await ApiClient.get('/hotels', query: {
      'q': q,
      'city': city,
      'guests': guests,
      'sort': sort,
      if (includeEmpty) 'include_empty': 1,
    });
    return (data as List).map((e) => Hotel.fromJson(e)).toList();
  }

  Future<List<String>> getCities() async {
    final data = await ApiClient.get('/hotels/cities');
    return (data as List).map((e) => '${e['city']}').toList();
  }

  Future<Hotel> getHotel(int id, {DateTime? checkIn, DateTime? checkOut}) async {
    final data = await ApiClient.get('/hotels/$id', query: {
      'check_in': checkIn == null ? null : apiDate(checkIn),
      'check_out': checkOut == null ? null : apiDate(checkOut),
    });
    return Hotel.fromJson(data);
  }

  Future<void> addReview({required int hotelId, required int bookingId, required int rating, String? comment}) async {
    await ApiClient.post('/hotels/$hotelId/reviews', {'booking_id': bookingId, 'rating': rating, 'comment': comment});
  }

  /// Ulasan yang pernah ditulis user yang sedang login
  Future<List<ReviewItem>> myReviews() async {
    final data = await ApiClient.get('/reviews/me');
    return (data as List).map((e) => ReviewItem.fromJson(e)).toList();
  }
}
