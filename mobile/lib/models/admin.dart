import '../utils/format.dart';
import 'booking.dart';

/// Ringkasan angka untuk dashboard admin
class AdminStats {
  final int hotels;
  final int roomTypes;
  final int totalRooms;
  final int users;
  final int bookings;
  final int pending;
  final int paid;
  final int revenue;
  final int bookedToday;
  final int reviews;
  final double? avgRating;
  final List<CityStat> cities;
  final List<AdminBooking> recent;

  AdminStats({
    required this.hotels,
    required this.roomTypes,
    required this.totalRooms,
    required this.users,
    required this.bookings,
    required this.pending,
    required this.paid,
    required this.revenue,
    required this.bookedToday,
    required this.reviews,
    this.avgRating,
    this.cities = const [],
    this.recent = const [],
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        hotels: toInt(j['hotels']),
        roomTypes: toInt(j['room_types']),
        totalRooms: toInt(j['total_rooms']),
        users: toInt(j['users']),
        bookings: toInt(j['bookings']),
        pending: toInt(j['pending']),
        paid: toInt(j['paid']),
        revenue: toInt(j['revenue']),
        bookedToday: toInt(j['booked_today']),
        reviews: toInt(j['reviews']),
        avgRating: toDoubleOrNull(j['avg_rating']),
        cities: (j['cities'] as List? ?? []).map((e) => CityStat.fromJson(e)).toList(),
        recent: (j['recent_bookings'] as List? ?? []).map((e) => AdminBooking.fromJson(e)).toList(),
      );
}

class CityStat {
  final String city;
  final int hotels;
  final int bookings;
  CityStat({required this.city, required this.hotels, required this.bookings});

  factory CityStat.fromJson(Map<String, dynamic> j) =>
      CityStat(city: j['city'] ?? '', hotels: toInt(j['hotels']), bookings: toInt(j['bookings']));
}

/// Booking + data pemesan (khusus admin)
class AdminBooking {
  final Booking booking;
  final String userName;
  final String userEmail;
  AdminBooking({required this.booking, required this.userName, required this.userEmail});

  factory AdminBooking.fromJson(Map<String, dynamic> j) => AdminBooking(
        booking: Booking.fromJson(j),
        userName: j['user_name'] ?? '',
        userEmail: j['user_email'] ?? '',
      );
}

/// Tipe kamar beserta jumlah yang terpesan pada satu tanggal
class BookedRoom {
  final int id;
  final String type;
  final int totalRooms;
  final int booked;
  final int available;
  final int pricePerNight;
  final String imageUrl;
  final int hotelId;
  final String hotelName;
  final String hotelCity;
  final List<BookedEntry> bookings;

  BookedRoom({
    required this.id,
    required this.type,
    required this.totalRooms,
    required this.booked,
    required this.available,
    required this.pricePerNight,
    required this.imageUrl,
    required this.hotelId,
    required this.hotelName,
    required this.hotelCity,
    required this.bookings,
  });

  double get occupancy => totalRooms == 0 ? 0 : booked / totalRooms;

  factory BookedRoom.fromJson(Map<String, dynamic> j) => BookedRoom(
        id: toInt(j['id']),
        type: j['type'] ?? '',
        totalRooms: toInt(j['total_rooms']),
        booked: toInt(j['booked']),
        available: toInt(j['available']),
        pricePerNight: toInt(j['price_per_night']),
        imageUrl: j['image_url'] ?? '',
        hotelId: toInt(j['hotel_id']),
        hotelName: j['hotel_name'] ?? '',
        hotelCity: j['hotel_city'] ?? '',
        bookings: (j['bookings'] as List? ?? []).map((e) => BookedEntry.fromJson(e)).toList(),
      );
}

class BookedEntry {
  final int id;
  final String code;
  final String guestName;
  final String guestPhone;
  final String userEmail;
  final int rooms;
  final int guests;
  final DateTime checkIn;
  final DateTime checkOut;
  final BookingStatus status;

  BookedEntry({
    required this.id,
    required this.code,
    required this.guestName,
    required this.guestPhone,
    required this.userEmail,
    required this.rooms,
    required this.guests,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });

  factory BookedEntry.fromJson(Map<String, dynamic> j) => BookedEntry(
        id: toInt(j['id']),
        code: j['booking_code'] ?? '',
        guestName: j['guest_name'] ?? '',
        guestPhone: j['guest_phone'] ?? '',
        userEmail: j['user_email'] ?? '',
        rooms: toInt(j['rooms']),
        guests: toInt(j['guests']),
        checkIn: DateTime.parse('${j['check_in']}'.substring(0, 10)),
        checkOut: DateTime.parse('${j['check_out']}'.substring(0, 10)),
        status: BookingStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => BookingStatus.pending),
      );
}

class BookedRoomsResult {
  final DateTime date;
  final int totalRooms;
  final int totalBooked;
  final List<BookedRoom> rooms;
  BookedRoomsResult({required this.date, required this.totalRooms, required this.totalBooked, required this.rooms});

  factory BookedRoomsResult.fromJson(Map<String, dynamic> j) => BookedRoomsResult(
        date: DateTime.parse('${j['date']}'),
        totalRooms: toInt(j['total_rooms']),
        totalBooked: toInt(j['total_booked']),
        rooms: (j['rooms'] as List? ?? []).map((e) => BookedRoom.fromJson(e)).toList(),
      );
}

/// Ulasan lengkap (dipakai admin & halaman "Ulasan Saya")
class ReviewItem {
  final int id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final int hotelId;
  final String hotelName;
  final String hotelCity;
  final String hotelImage;
  final String roomType;
  final String userName;
  final String userEmail;
  final String bookingCode;

  ReviewItem({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.hotelId,
    required this.hotelName,
    required this.hotelCity,
    this.hotelImage = '',
    this.roomType = '',
    this.userName = '',
    this.userEmail = '',
    this.bookingCode = '',
  });

  factory ReviewItem.fromJson(Map<String, dynamic> j) => ReviewItem(
        id: toInt(j['id']),
        rating: toInt(j['rating']),
        comment: j['comment'],
        createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
        hotelId: toInt(j['hotel_id']),
        hotelName: j['hotel_name'] ?? '',
        hotelCity: j['hotel_city'] ?? '',
        hotelImage: j['hotel_image'] ?? '',
        roomType: j['room_type'] ?? '',
        userName: j['user_name'] ?? '',
        userEmail: j['user_email'] ?? '',
        bookingCode: j['booking_code'] ?? '',
      );
}
