import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/hotel.dart';
import '../utils/format.dart';
import 'common.dart';

class HotelCard extends StatelessWidget {
  final Hotel hotel;
  final VoidCallback onTap;
  final int colorIndex;
  const HotelCard({super.key, required this.hotel, required this.onTap, this.colorIndex = 0});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tint = AppTheme.pickColor(colorIndex);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow(tint),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              NetImage(hotel.imageUrl, height: 190, width: double.infinity),
              // gradasi gelap di bawah foto agar teks terbaca
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                      stops: const [0.5, 1],
                    ),
                  ),
                ),
              ),
              Positioned(top: 12, right: 12, child: FavoriteButton(hotel: hotel)),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.place_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(hotel.city, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Row(children: [
                  StarRow(hotel.star),
                  const Spacer(),
                  if (hotel.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Text('★ ${hotel.rating!.toStringAsFixed(1)}',
                          style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                ]),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hotel.name,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(hotel.address,
                    style: t.bodySmall?.copyWith(color: AppTheme.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(children: [
                  Text(
                    hotel.rating != null ? '${hotel.reviewCount} ulasan' : 'Belum ada ulasan',
                    style: t.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                  const Spacer(),
                  Text('mulai ', style: t.bodySmall?.copyWith(color: AppTheme.muted)),
                  ShaderMask(
                    shaderCallback: (r) => AppTheme.warmGradient.createShader(r),
                    child: Text(rupiah(hotel.minPrice),
                        style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                  Text('/mlm', style: t.bodySmall?.copyWith(color: AppTheme.muted)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
