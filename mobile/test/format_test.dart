import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stayease/models/booking.dart';
import 'package:stayease/utils/format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('format rupiah', () {
    expect(rupiah(550000).replaceAll(' ', ' '), 'Rp 550.000');
  });

  test('format tanggal untuk API', () {
    expect(apiDate(DateTime(2026, 11, 3)), '2026-11-03');
  });

  test('toInt aman untuk string/null', () {
    expect(toInt('12'), 12);
    expect(toInt(null), 0);
    expect(toInt(4.0), 4);
  });

  test('kelompok digit nomor VA', () {
    expect(groupDigits('390120002994743'), '3901 2000 2994 743');
  });

  test('biaya layanan VA & QRIS sama dengan backend', () {
    expect(serviceFeeFor(PaymentMethod.va, 1100000), 4000);
    expect(serviceFeeFor(PaymentMethod.qris, 1100000), 7700);
  });
}
