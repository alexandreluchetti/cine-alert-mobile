import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CineAlertLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const CineAlertLogo({
    super.key,
    this.size = 72,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.46;
    final badgeSize = size * 0.30;
    final radius = size * 0.24;
    final badgeRadius = badgeSize * 0.26;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Ambient glow
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.22),
                      blurRadius: size * 0.50,
                      spreadRadius: size * 0.02,
                    ),
                  ],
                ),
              ),

              // Background — flat gradient, no gloss
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD740),
                      Color(0xFFF5C518),
                      Color(0xFFC48A00),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                  border: Border.all(
                    color: Color(0x1FFFFFFF),
                    width: 1.0,
                  ),
                ),
              ),

              // Film icon
              Icon(
                Icons.movie_filter_rounded,
                size: iconSize,
                color: const Color(0xFF1A1A1A),
              ),

              // Bell badge — rounded rectangle
              Positioned(
                bottom: size * 0.04,
                right: size * 0.04,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(badgeRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_rounded,
                    size: badgeSize * 0.60,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD740), Color(0xFFF5C518)],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text(
              'CineAlert',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
