import '../utils/format.dart';

enum BookingStatus { pending, paid, cancelled, completed }

enum PaymentMethod { va, qris }

/// Biaya layanan — sama persis dengan perhitungan di backend (bookingController.js)
int serviceFeeFor(PaymentMethod m, int total) => m == PaymentMethod.va ? 4000 : (total * 0.007).ceil();

const vaBanks = ['BCA', 'BNI', 'BRI', 'MANDIRI'];

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
        BookingStatus.pending => 'Menunggu Pembayaran',
        BookingStatus.paid => 'Lunas',
        BookingStatus.cancelled => 'Dibatalkan',
        BookingStatus.completed => 'Selesai',
      };
}

class Booking {
  final int id;
  final String code;
  final int roomId;
  final int hotelId;
  final String hotelName;
  final String hotelCity;
  final String hotelAddress;
  final String hotelImage;
  final String roomType;
  final int pricePerNight;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int rooms;
  final int nights;
  final int totalPrice;
  final String guestName;
  final String guestPhone;
  final String? notes;
  final BookingStatus status;
  final bool hasReview;
  final DateTime createdAt;

  // ---- pembayaran ----
  final DateTime? paidAt;
  final PaymentMethod? paymentMethod;
  final String? paymentBank;
  final String? vaNumber;
  final String? qrisRef;
  final int serviceFee;
  final int? paymentAmount;
  final DateTime? paymentExpiresAt;
  final String? receiptNumber;

  Booking({
    required this.id,
    required this.code,
    required this.roomId,
    required this.hotelId,
    required this.hotelName,
    required this.hotelCity,
    required this.hotelAddress,
    required this.hotelImage,
    required this.roomType,
    required this.pricePerNight,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    this.rooms = 1,
    required this.nights,
    required this.totalPrice,
    required this.guestName,
    required this.guestPhone,
    this.notes,
    required this.status,
    required this.hasReview,
    required this.createdAt,
    this.paidAt,
    this.paymentMethod,
    this.paymentBank,
    this.vaNumber,
    this.qrisRef,
    this.serviceFee = 0,
    this.paymentAmount,
    this.paymentExpiresAt,
    this.receiptNumber,
  });

  /// Tagihan (VA/QRIS) sudah dibuat dan belum kedaluwarsa
  bool get hasActiveInvoice =>
      status == BookingStatus.pending &&
      paymentMethod != null &&
      (paymentExpiresAt == null || paymentExpiresAt!.isAfter(DateTime.now()));

  bool get hasReceipt => receiptNumber != null && (status == BookingStatus.paid || status == BookingStatus.completed);

  String get paymentLabel => switch (paymentMethod) {
        PaymentMethod.va => 'Virtual Account ${paymentBank ?? ''}'.trim(),
        PaymentMethod.qris => 'QRIS',
        null => '-',
      };

  bool get canPay => status == BookingStatus.pending;
  bool get canCancel =>
      (status == BookingStatus.pending || status == BookingStatus.paid) && checkIn.isAfter(DateTime.now());
  bool get canReview => (status == BookingStatus.paid || status == BookingStatus.completed) && !hasReview;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: toInt(j['id']),
        code: j['booking_code'] ?? '',
        roomId: toInt(j['room_id']),
        hotelId: toInt(j['hotel_id']),
        hotelName: j['hotel_name'] ?? '',
        hotelCity: j['hotel_city'] ?? '',
        hotelAddress: j['hotel_address'] ?? '',
        hotelImage: j['hotel_image'] ?? '',
        roomType: j['room_type'] ?? '',
        pricePerNight: toInt(j['price_per_night']),
        checkIn: DateTime.parse('${j['check_in']}'.substring(0, 10)),
        checkOut: DateTime.parse('${j['check_out']}'.substring(0, 10)),
        guests: toInt(j['guests']),
        rooms: j['rooms'] == null ? 1 : toInt(j['rooms']),
        nights: toInt(j['nights']),
        totalPrice: toInt(j['total_price']),
        guestName: j['guest_name'] ?? '',
        guestPhone: j['guest_phone'] ?? '',
        notes: j['notes'],
        status: BookingStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => BookingStatus.pending),
        hasReview: j['has_review'] == true,
        createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
        paidAt: j['paid_at'] == null ? null : DateTime.tryParse('${j['paid_at']}'),
        paymentMethod: PaymentMethod.values.where((m) => m.name == j['payment_method']).firstOrNull,
        paymentBank: j['payment_bank'],
        vaNumber: j['va_number'],
        qrisRef: j['qris_ref'],
        serviceFee: toInt(j['service_fee']),
        paymentAmount: j['payment_amount'] == null ? null : toInt(j['payment_amount']),
        paymentExpiresAt: j['payment_expires_at'] == null ? null : DateTime.tryParse('${j['payment_expires_at']}'),
        receiptNumber: j['receipt_number'],
      );
}
