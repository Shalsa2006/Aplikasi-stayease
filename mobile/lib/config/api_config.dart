/// Alamat backend StayEase.
///
/// - Emulator Android  : http://10.0.2.2:3000/api   (10.0.2.2 = localhost komputer)
/// - Flutter Web/Chrome: http://localhost:3000/api
/// - HP fisik (1 WiFi) : http://<IP-laptop>:3000/api  (cek IP dengan `ipconfig`)
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  static const Duration timeout = Duration(seconds: 15);
}
