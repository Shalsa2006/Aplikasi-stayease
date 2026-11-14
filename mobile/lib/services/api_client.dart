import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

/// Pembungkus `http` yang otomatis menambahkan token JWT dan
/// mengurai format respons backend: { success, message, data }.
class ApiClient {
  static const _tokenKey = 'auth_token';
  static String? _token;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    token == null ? await prefs.remove(_tokenKey) : await prefs.setString(_tokenKey, token);
  }

  static bool get hasToken => _token != null;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && '$v'.isNotEmpty) q[k] = '$v';
    });
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers));

  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  static Future<dynamic> put(String path, [Map<String, dynamic>? body]) =>
      _send(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  static Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _send(() => http.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  static Future<dynamic> delete(String path) => _send(() => http.delete(_uri(path), headers: _headers));

  static Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException('Server tidak merespons (timeout).');
    } catch (_) {
      // SocketException / ClientException: server mati atau alamat salah
      throw ApiException('Tidak dapat terhubung ke server. Pastikan backend berjalan.');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respons server tidak valid (${res.statusCode})', res.statusCode);
    }

    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return body['data'];
    }
    throw ApiException(body['message']?.toString() ?? 'Terjadi kesalahan', res.statusCode);
  }
}
