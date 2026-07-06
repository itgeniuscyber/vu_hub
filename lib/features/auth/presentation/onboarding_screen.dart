import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'auth_shared.dart';

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
      icon: Icons.campaign_outlined,
      badge: 'Official Feed',
      title: 'Verified notices, urgent alerts, and trusted campus updates.',
      body:
          'Receive official announcements, guild updates, and urgent alerts from trusted university sources.',
      highlights: ['Pinned notices', 'Urgent alerts', 'Guild updates'],
    ),
    _OnboardingSlide(
      icon: Icons.folder_copy_outlined,
      badge: 'VU Vault',
      title: 'Resources that actually help you study and revise faster.',
      body:
          'Find past papers, course resources, event materials, and study content from the existing VU database.',
      highlights: ['Past papers', 'Shared resources', 'Lecturer uploads'],
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome,
      badge: 'AI Desk',
      title: 'Campus AI support designed for real student questions.',
      body:
          'Ask campus questions, summarize notices, study with Vault resources, and get routed to the right office.',
      highlights: ['Smart routing', 'Study help', 'Source-aware answers'],
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
      body: AuthBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'VU Hub',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 920;
                      final pager = PageView.builder(
                        controller: _controller,
                        itemCount: _slides.length,
                        onPageChanged: (value) => setState(() => _page = value),
                        itemBuilder: (context, index) =>
                            _OnboardingCard(slide: _slides[index]),
                      );
                      if (!wide) return pager;
                      return Row(
                        children: [
                          const Expanded(
                            child: AuthShowcasePanel(
                              eyebrow: 'Modern Student Experience',
                              title:
                                  'A smoother, smarter, more premium campus companion.',
                              subtitle:
                                  'VU Hub brings together verified information, academic resources, live activity, and AI assistance in one student-first mobile experience.',
                              tags: [
                                'Student-first',
                                'Premium UI',
                                'Live campus',
                                'Trusted data',
                              ],
                              highlights: [
                                AuthHighlight(
                                  icon: Icons.dashboard_customize_outlined,
                                  title: 'Everything in one place',
                                  subtitle:
                                      'Move from dashboard to vault, live events, guild updates, and AI support without the app feeling fragmented.',
                                ),
                                AuthHighlight(
                                  icon: Icons.shield_outlined,
                                  title: 'Trust built into the flow',
                                  subtitle:
                                      'Official updates, safe roles, and secure Firebase Authentication keep the student experience polished and reliable.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(width: 430, child: pager),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    ...List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: _page == index ? 30 : 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: _page == index
                              ? scheme.primary
                              : Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => context.go('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Text('Create account'),
                    ),
                    const SizedBox(width: 10),
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
      child: AuthGlassPane(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.secondary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      slide.badge,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    child: Icon(slide.icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    slide.title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(slide.body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: slide.highlights
                  .map((item) => _MiniTag(label: item))
                  .toList(),
            ),
            const SizedBox(height: 18),
            const AuthInfoBanner(
              icon: Icons.phone_android_outlined,
              title: 'Built for mobile flow',
              message:
                  'Large cards, smooth transitions, elegant dark mode, and clearer campus actions make the experience feel newer and more premium.',
            ),
          ],
        ),
      ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.primary.withValues(alpha: 0.08),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.badge,
    required this.title,
    required this.body,
    required this.highlights,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String body;
  final List<String> highlights;
}
