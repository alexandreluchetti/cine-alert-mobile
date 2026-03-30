import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A sleek, modern CineAlert logo mark.
///
/// [size] controls the outer container side-length.
/// Use [showText] to control whether the "CineAlert" wordmark is shown below
/// (useful for the large login variant vs. compact AppBar variant).
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
    final iconSize = size * 0.50;
    final badgeSize = size * 0.30;
    final radius = size * 0.26;

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
              // --- Outer glow ring ---
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.30),
                      blurRadius: size * 0.35,
                      spreadRadius: size * 0.04,
                    ),
                  ],
                ),
              ),

              // --- Gradient background tile ---
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF5C518), // accent
                      Color(0xFFD4920A), // warm deep gold
                    ],
                  ),
                ),
              ),

              // --- Subtle inner top-left shine ---
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: size * 0.55,
                  height: size * 0.45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(radius),
                      bottomRight: Radius.circular(size * 0.5),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // --- Film-reel icon (main) ---
              Icon(
                Icons.local_movies_rounded,
                size: iconSize,
                color: Colors.black.withOpacity(0.88),
              ),

              // --- Bell badge (bottom-right) ---
              Positioned(
                bottom: size * 0.04,
                right: size * 0.04,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.40),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_rounded,
                    size: badgeSize * 0.58,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 14),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFF5C518), Color(0xFFFFE066)],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text(
              'CineAlert',
              style: TextStyle(
                color: Colors.white, // masked by shader
                fontSize: size * 0.40,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Seus filmes. Seus horários.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: size * 0.175,
              fontFamily: 'Inter',
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}
