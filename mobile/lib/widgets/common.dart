import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/booking.dart';
import '../models/hotel.dart';
import '../providers/favorite_provider.dart';

/// Gambar hotel/kamar. Mendukung foto dari aplikasi ("assets/images/...")
/// maupun URL internet ("https://..."), lengkap dengan placeholder & fallback.
class NetImage extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  final BorderRadius? radius;

  const NetImage(this.url, {super.key, this.height, this.width, this.radius});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height,
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFEDE7FF), Color(0xFFFFE4F1)]),
      ),
      child: const Icon(Icons.hotel_rounded, size: 40, color: AppTheme.primary),
    );
    Widget img;
    if (url.isEmpty) {
      img = fallback;
    } else if (url.startsWith('assets/')) {
      img = Image.asset(url, height: height, width: width, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    } else {
      img = Image.network(
        url,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (c, child, p) => p == null ? child : fallback,
      );
    }
    return ClipRRect(borderRadius: radius ?? BorderRadius.zero, child: img);
  }
}

/// Tombol dengan latar gradasi warna.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Gradient gradient;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.gradient = AppTheme.mainGradient,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled ? AppTheme.softShadow(AppTheme.pink) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 52,
              child: Center(
                child: loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
                        Flexible(
                          child: Text(label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ikon hati untuk menambah/menghapus hotel dari daftar Disukai.
class FavoriteButton extends StatelessWidget {
  final Hotel hotel;
  final double size;
  const FavoriteButton({super.key, required this.hotel, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>().isFavorite(hotel.id);
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          try {
            final nowFav = await context.read<FavoriteProvider>().toggle(hotel);
            if (context.mounted) showSnack(context, nowFav ? '❤️ ${hotel.name} disukai' : 'Dihapus dari Disukai');
          } catch (e) {
            if (context.mounted) showSnack(context, '$e', error: true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(fav),
              color: fav ? AppTheme.pink : AppTheme.muted,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu putih dengan sudut membulat & bayangan lembut.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin});

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.softShadow(),
        ),
        child: Material(type: MaterialType.transparency, child: child),
      );
}

/// Ikon dalam kotak berwarna (untuk menu & judul bagian)
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBadge(this.icon, this.color, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: size),
      );
}

class StarRow extends StatelessWidget {
  final int star;
  const StarRow(this.star, {super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(star, (_) => const Icon(Icons.star_rounded, size: 15, color: AppTheme.accent)),
      );
}

/// 5 bintang (penuh/kosong) sesuai rating 1–5
class RatingStars extends StatelessWidget {
  final int rating;
  final double size;
  const RatingStars(this.rating, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: AppTheme.accent),
        ),
      );
}

class StatusChip extends StatelessWidget {
  final BookingStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      BookingStatus.pending => (const Color(0xFFFFF0DB), const Color(0xFFC2410C)),
      BookingStatus.paid => (const Color(0xFFD6F7EC), const Color(0xFF047857)),
      BookingStatus.cancelled => (const Color(0xFFFFE1EA), const Color(0xFFBE123C)),
      BookingStatus.completed => (const Color(0xFFEDE7FF), AppTheme.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Tampilan error dengan tombol coba lagi.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const IconBadge(Icons.cloud_off_rounded, AppTheme.pink, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
          ]),
        ),
      );
}

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFE11D48) : AppTheme.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ));
}
