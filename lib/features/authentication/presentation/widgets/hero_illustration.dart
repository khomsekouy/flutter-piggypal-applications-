import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';

class HeroBadge {
  const HeroBadge({
    required this.icon,
    required this.color,
    this.alignment = Alignment.topRight,
  });
  final IconData icon;
  final Color color;
  final Alignment alignment;
}

class HeroIllustration extends StatelessWidget {
  const HeroIllustration({
    required this.icon,
    super.key,
    this.badges = const [],
    this.size = 190,
  });

  final IconData icon;
  final List<HeroBadge> badges;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.glow(AppColors.primaryGreen),
            ),
          ),
          Container(
            width: size * 0.52,
            height: size * 0.52,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: size * 0.26),
          ),
          for (final badge in badges)
            Align(
              alignment: badge.alignment,
              child: Container(
                width: size * 0.19,
                height: size * 0.19,
                decoration: BoxDecoration(
                  color: badge.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                ),
                child: Icon(badge.icon, color: Colors.black, size: size * 0.1),
              ),
            ),
        ],
      ),
    );
  }
}
