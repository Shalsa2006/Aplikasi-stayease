import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  Future<User> login(String email, String password) async {
    final data = await ApiClient.post('/auth/login', {'email': email, 'password': password});
    await ApiClient.saveToken(data['token']);
    return User.fromJson(data['user']);
  }

  Future<User> register({required String name, required String email, required String password, String? phone}) async {
    final data = await ApiClient.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    });
    await ApiClient.saveToken(data['token']);
    return User.fromJson(data['user']);
  }

  Future<User> me() async => User.fromJson(await ApiClient.get('/auth/me'));

  Future<User> updateProfile({required String name, String? phone, String? password}) async {
    final data = await ApiClient.put('/auth/me', {
      'name': name,
      'phone': phone,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return User.fromJson(data);
  }

  Future<void> logout() => ApiClient.saveToken(null);
}
