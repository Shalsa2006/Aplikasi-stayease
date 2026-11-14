import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  AuthStatus status = AuthStatus.unknown;
  User? user;

  /// Dipanggil saat aplikasi dibuka: cek token tersimpan masih valid atau tidak.
  Future<void> bootstrap() async {
    await ApiClient.loadToken();
    if (!ApiClient.hasToken) {
      status = AuthStatus.unauthenticated;
    } else {
      try {
        user = await _service.me();
        status = AuthStatus.authenticated;
      } on ApiException catch (e) {
        if (e.statusCode == 401) await _service.logout();
        status = AuthStatus.unauthenticated;
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    user = await _service.login(email.trim(), password);
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password, String phone) async {
    user = await _service.register(name: name.trim(), email: email.trim(), password: password, phone: phone.trim());
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> updateProfile(String name, String phone, String? password) async {
    user = await _service.updateProfile(name: name, phone: phone, password: password);
    notifyListeners();
  }

  Future<void> logout() async {
    await _service.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
