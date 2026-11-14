import '../utils/format.dart';

class Hotel {
  final int id;
  final String name;
  final String city;
  final String address;
  final String description;
  final int star;
  final String imageUrl;
  final List<String> facilities;
  final double? rating;
  final int reviewCount;
  final int minPrice;
  final List<Room> rooms;
  final List<Review> reviews;

  /// Jumlah ulasan per bintang: {5: 10, 4: 3, ...}
  final Map<int, int> ratingBreakdown;

  Hotel({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.description,
    required this.star,
    required this.imageUrl,
    required this.facilities,
    this.rating,
    this.reviewCount = 0,
    this.minPrice = 0,
    this.rooms = const [],
    this.reviews = const [],
    this.ratingBreakdown = const {},
  });

  factory Hotel.fromJson(Map<String, dynamic> j) => Hotel(
        id: toInt(j['id']),
        name: j['name'] ?? '',
        city: j['city'] ?? '',
        address: j['address'] ?? '',
        description: j['description'] ?? '',
        star: toInt(j['star']),
        imageUrl: j['image_url'] ?? '',
        facilities: (j['facilities'] as List? ?? []).map((e) => '$e').toList(),
        rating: toDoubleOrNull(j['rating']),
        reviewCount: toInt(j['review_count']),
        minPrice: toInt(j['min_price']),
        rooms: (j['rooms'] as List? ?? []).map((e) => Room.fromJson(e)).toList(),
        reviews: (j['reviews'] as List? ?? []).map((e) => Review.fromJson(e)).toList(),
        ratingBreakdown: {
          for (final e in ((j['rating_breakdown'] as Map?) ?? {}).entries) toInt(e.key): toInt(e.value),
        },
      );
}

class Room {
  final int id;
  final int hotelId;
  final String type;
  final String description;
  final int pricePerNight;
  final int capacity;
  final int totalRooms;
  final String imageUrl;

  /// null = tanggal belum dipilih
  final int? available;

  Room({
    required this.id,
    required this.hotelId,
    required this.type,
    required this.description,
    required this.pricePerNight,
    required this.capacity,
    required this.totalRooms,
    required this.imageUrl,
    this.available,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        id: toInt(j['id']),
        hotelId: toInt(j['hotel_id']),
        type: j['type'] ?? '',
        description: j['description'] ?? '',
        pricePerNight: toInt(j['price_per_night']),
        capacity: toInt(j['capacity']),
        totalRooms: toInt(j['total_rooms']),
        imageUrl: j['image_url'] ?? '',
        available: j['available'] == null ? null : toInt(j['available']),
      );
}

class Review {
  final int id;
  final int rating;
  final String? comment;
  final String userName;
  final DateTime createdAt;

  Review({required this.id, required this.rating, this.comment, required this.userName, required this.createdAt});

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: toInt(j['id']),
        rating: toInt(j['rating']),
        comment: j['comment'],
        userName: j['user_name'] ?? '',
        createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
      );
}
