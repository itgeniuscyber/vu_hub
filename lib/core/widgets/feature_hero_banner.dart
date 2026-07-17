import 'package:flutter/material.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';

class FeatureHeroBanner extends StatelessWidget {
  const FeatureHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.scheme,
    this.imageAsset,
    this.badge,
    this.trailing,
    this.height = 196,
  });

  final String title;
  final String subtitle;
  final Object icon;
  final ColorScheme scheme;
  final String? imageAsset;
  final String? badge;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageAsset != null)
              Image.asset(imageAsset!, fit: BoxFit.cover)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.92),
                      scheme.secondary.withValues(alpha: 0.88),
                      scheme.tertiary.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.16),
                      scheme.primary.withValues(alpha: 0.52),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        child: _HeroIcon(icon: icon),
                      ),
                      const SizedBox(width: 12),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Text(
                            badge!,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      const Spacer(),
                      trailing ?? const SizedBox.shrink(),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.icon});

  final Object icon;

  @override
  Widget build(BuildContext context) {
    final value = icon;
    if (value is String) {
      return FUI(value, color: Colors.white, width: 20, height: 20);
    }
    return Icon(value as IconData, color: Colors.white);
  }
}
