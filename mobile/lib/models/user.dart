import '../utils/format.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;

  User({required this.id, required this.name, required this.email, this.phone, this.role = 'user'});

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: toInt(j['id']),
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'],
        role: j['role'] ?? 'user',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'phone': phone, 'role': role};
}
