import 'package:flutter/material.dart';

/// Palet warna StayEase: ungu–pink–oranye dengan aksen emas.
/// Ganti nilai di sini untuk mengubah warna seluruh aplikasi.
class AppTheme {
  static const Color primary = Color(0xFF6C3CE1); // ungu
  static const Color pink = Color(0xFFF0428F);
  static const Color orange = Color(0xFFFF8A3D);
  static const Color accent = Color(0xFFF5B83D); // emas untuk bintang & harga
  static const Color sky = Color(0xFF2BB6F0);
  static const Color mint = Color(0xFF1DBF94);
  static const Color ink = Color(0xFF1E1B3A); // teks utama
  static const Color muted = Color(0xFF7C7A99); // teks sekunder
  static const Color bg = Color(0xFFF6F4FF); // latar lavender lembut
  static const Color price = Color(0xFFE8590C);

  /// Gradasi utama (header, tombol, kartu kode booking)
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B2EDB), Color(0xFFB13BD6), Color(0xFFF0428F)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0428F), Color(0xFFFF8A3D)],
  );

  static const LinearGradient coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2BB6F0), Color(0xFF6C3CE1)],
  );

  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1DBF94), Color(0xFF2BB6F0)],
  );

  /// Gradasi khusus mode admin (biru tua → ungu) agar beda dari tampilan pengguna
  static const LinearGradient adminGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2A5F), Color(0xFF2E4FC7), Color(0xFF6C3CE1)],
  );
  static const Color admin = Color(0xFF2E4FC7);

  /// Warna-warni untuk chip kota / fasilitas / ikon menu
  static const List<Color> rainbow = [primary, pink, orange, sky, mint, Color(0xFF9B5DE5), Color(0xFFE5A100)];

  static Color pickColor(int i) => rainbow[i % rainbow.length];

  static List<BoxShadow> softShadow([Color color = primary]) => [
        BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 8)),
      ];

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: pink,
      tertiary: orange,
      surface: Colors.white,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE6E1F7)),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: primary, width: 1.6)),
        prefixIconColor: primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.12),
        elevation: 8,
        shadowColor: primary.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? primary : muted),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
      ),
    );
  }
}
