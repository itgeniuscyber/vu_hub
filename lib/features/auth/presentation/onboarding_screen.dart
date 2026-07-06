import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      icon: Icons.campaign,
      title: 'Verified campus feed',
      body:
          'Receive official announcements, guild updates, and urgent alerts from trusted university sources.',
    ),
    _OnboardingSlide(
      icon: Icons.folder_copy,
      title: 'Resources that actually help',
      body:
          'Find past papers, course resources, event materials, and study content from the existing VU database.',
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome,
      title: 'VU AI Desk',
      body:
          'Ask campus questions, summarize notices, study with Vault resources, and get routed to the right office.',
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/vu_auth_hero.png', fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.64),
                  scheme.primary.withValues(alpha: 0.38),
                  scheme.surface.withValues(alpha: 0.92),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Skip'),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemBuilder: (context, index) =>
                          _OnboardingCard(slide: _slides[index]),
                    ),
                  ),
                  Row(
                    children: [
                      ...List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: _page == index ? 28 : 9,
                          height: 9,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: _page == index
                                ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {
                          if (_page == _slides.length - 1) {
                            context.go('/login');
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        icon: Icon(
                          _page == _slides.length - 1
                              ? Icons.login
                              : Icons.arrow_forward,
                        ),
                        label: Text(
                          _page == _slides.length - 1 ? 'Get started' : 'Next',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Card(
        color: scheme.surface.withValues(alpha: 0.9),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: scheme.primary.withValues(alpha: 0.14),
                child: Icon(slide.icon, color: scheme.primary, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                slide.body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
