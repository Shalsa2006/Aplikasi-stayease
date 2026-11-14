import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

String rupiah(num value) => _rupiah.format(value);

/// 2026-11-03 -> "Sel, 3 Nov 2026"
String tanggal(DateTime d) => DateFormat('EEE, d MMM yyyy', 'id_ID').format(d);

/// Format yang dikirim ke API
String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

int toInt(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? double.tryParse('$v')?.toInt() ?? 0);

double? toDoubleOrNull(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

/// 2026-11-03 -> "3 Nov"
String tanggalPendek(DateTime d) => DateFormat('d MMM', 'id_ID').format(d);

/// 2026-11-03 14:05 -> "3 Nov 2026, 14:05"
String tanggalJam(DateTime d) => DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(d);

/// "3901234567890123" -> "3901 2345 6789 0123" (lebih mudah dibaca)
String groupDigits(String s, [int size = 4]) {
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && i % size == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}
