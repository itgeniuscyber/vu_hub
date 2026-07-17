import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardingSlide(
      imageAsset: 'assets/images/p6.jpeg',
      title: 'Get Better Grades',
      body:
          'Access past papers, verified resources, and study materials curated specifically for your course.',
      fit: BoxFit.cover,
      alignment: Alignment.center,
      badges: [
        _SlideBadge(
          icon: BoldRounded.magicWand,
          label: 'Vault',
          value: '+200%',
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: 30, bottom: 40),
        ),
        _SlideBadge(
          icon: BoldRounded.school,
          label: 'Study',
          value: 'Smart',
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 30, top: 80),
        ),
      ],
    ),
    _OnboardingSlide(
      imageAsset: 'assets/images/gal-no-bg.png',
      title: 'Your Campus is First',
      body:
          'Stay updated with official announcements, guild notices, and urgent alerts directly from verified university sources.',
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      badges: [
        _SlideBadge(
          icon: BoldRounded.megaphone,
          label: 'Alerts',
          value: 'Live',
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: 40, top: 40),
        ),
      ],
    ),
    _OnboardingSlide(
      imageAsset: 'assets/images/smart-ai-gal.jpg',
      title: 'Welcome to VU Hub',
      body:
          'The ultimate campus app. AI assistance, live event tracking, and everything you need in one seamless experience.',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      badges: [
        _SlideBadge(
          icon: BoldRounded.apps,
          label: 'VU Hub',
          value: 'Pro',
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 40, bottom: 60),
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // We want a clean, premium background (white in light mode, dark in dark mode)
    final bgColor = isDark ? scheme.surface : Colors.white;
    final onBgColor = isDark ? Colors.white : Colors.black;

    // Use AnnotatedRegion to ensure status bar text is visible
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Column(
                  children: [
                    // Top Image Area (60% of screen)
                    Expanded(
                      flex: 60,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background color for images with no background
                          if (slide.imageAsset.contains('no-bg'))
                            Container(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.5,
                              ),
                            ),

                          // Image
                          Image.asset(
                            slide.imageAsset,
                            fit: slide.fit,
                            alignment: slide.alignment,
                          ).animate().fadeIn(duration: 500.ms),

                          // Gradient fade at the bottom to blend into the text area
                          Positioned(
                            bottom:
                                -1, // slight overlap to prevent bleeding lines
                            left: 0,
                            right: 0,
                            height: 120,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    bgColor.withValues(alpha: 0),
                                    bgColor,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Floating Badges
                          ...slide.badges.map((badge) {
                            return Align(
                              alignment: badge.alignment,
                              child: Padding(
                                padding: badge.padding,
                                child:
                                    _FloatingBadge(
                                      icon: badge.icon,
                                      label: badge.label,
                                      value: badge.value,
                                    ).animate().scale(
                                      delay: 300.ms,
                                      curve: Curves.easeOutBack,
                                    ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Bottom Text Area (40% of screen)
                    Expanded(
                      flex: 40,
                      child: Container(
                        width: double.infinity,
                        color: bgColor,
                        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slide.title,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: onBgColor,
                                    height: 1.2,
                                  ),
                            ).animate().slideX(begin: 0.05, end: 0).fadeIn(),
                            const SizedBox(height: 16),
                            Text(
                                  slide.body,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                        height: 1.5,
                                      ),
                                )
                                .animate()
                                .slideX(begin: 0.05, end: 0, delay: 100.ms)
                                .fadeIn(delay: 100.ms),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Top bar with Logo and Skip button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Image.asset(
                        'assets/images/vu_hub_logo.png',
                        height: 40,
                      ).animate().fadeIn(duration: 500.ms),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(foregroundColor: onBgColor),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Area
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Custom Page Indicator
                      Row(
                        children: List.generate(_slides.length, (index) {
                          final active = _page == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.only(right: 6),
                            height: 6,
                            width: active ? 28 : 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? onBgColor
                                  : onBgColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),

                      // Next / Get Started Button
                      GestureDetector(
                        onTap: () {
                          if (_page == _slides.length - 1) {
                            context.go('/login');
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          height: 64,
                          padding: EdgeInsets.symmetric(
                            horizontal: _page == _slides.length - 1 ? 24 : 0,
                          ),
                          width: _page == _slides.length - 1 ? 160 : 64,
                          decoration: BoxDecoration(
                            color: onBgColor,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: onBgColor.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _page == _slides.length - 1
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Get Started',
                                        style: TextStyle(
                                          color: bgColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      FUI(
                                        BoldRounded.arrowRight,
                                        color: bgColor,
                                        width: 20,
                                        height: 20,
                                      ),
                                    ],
                                  )
                                : FUI(
                                    BoldRounded.arrowRight,
                                    color: bgColor,
                                    width: 28,
                                    height: 28,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: FUI(icon, color: Colors.white, width: 14, height: 14),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideBadge {
  const _SlideBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.alignment,
    required this.padding,
  });

  final String icon;
  final String label;
  final String value;
  final Alignment alignment;
  final EdgeInsets padding;
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.imageAsset,
    required this.title,
    required this.body,
    required this.fit,
    required this.alignment,
    this.badges = const [],
  });

  final String imageAsset;
  final String title;
  final String body;
  final BoxFit fit;
  final Alignment alignment;
  final List<_SlideBadge> badges;
}
