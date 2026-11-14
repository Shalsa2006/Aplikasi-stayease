import '../models/hotel.dart';
import 'api_client.dart';

class FavoriteService {
  Future<List<Hotel>> list() async {
    final data = await ApiClient.get('/favorites');
    return (data as List).map((e) => Hotel.fromJson(e)).toList();
  }

  Future<void> add(int hotelId) => ApiClient.post('/hotels/$hotelId/favorite');

  Future<void> remove(int hotelId) => ApiClient.delete('/hotels/$hotelId/favorite');
}
