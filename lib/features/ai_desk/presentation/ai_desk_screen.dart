import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import '../data/ai_service.dart';

class AiDeskScreen extends StatefulWidget {
  const AiDeskScreen({super.key});

  @override
  State<AiDeskScreen> createState() => _AiDeskScreenState();
}

class _AiDeskScreenState extends State<AiDeskScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _service = FirebaseAiService();
  final List<_ChatMessage> _messages = const [
    _ChatMessage(
      isUser: false,
      text:
          'Welcome to VU AI Desk. Ask me about campus offices, VClass sections, past papers, announcements, events, or study support.',
      sources: ['VU Hub'],
    ),
  ].toList();
  bool _isThinking = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? quickPrompt]) async {
    final prompt = (quickPrompt ?? _controller.text).trim();
    if (prompt.isEmpty || _isThinking) return;
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: prompt));
      _isThinking = true;
      _controller.clear();
    });
    _scrollToBottom();
    final response = await _service.ask(prompt);
    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          isUser: false,
          text: response.answer,
          sources: response.sources,
          actions: response.actions,
        ),
      );
      _isThinking = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _AiHeader(scheme: scheme),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _AiToolCard(
                    title: 'Smart search',
                    subtitle: 'Find notices, events, and resources',
                    icon: Icons.travel_explore,
                    color: scheme.primary,
                    onTap: () => _send(
                      'Search campus help for exam timetable and latest notices',
                    ),
                  ),
                  _AiToolCard(
                    title: 'Study assist',
                    subtitle: 'Summaries, flashcards, revision help',
                    icon: Icons.menu_book_outlined,
                    color: scheme.secondary,
                    onTap: () =>
                        _send('Create revision questions from a past paper'),
                  ),
                  _AiToolCard(
                    title: 'Route me',
                    subtitle: 'Find the right office or process',
                    icon: Icons.hub_outlined,
                    color: const Color(0xFF8B5CF6),
                    onTap: () =>
                        _send('Where should I go for retake applications?'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _QuickPrompt(
                    label: 'How do I apply for a retake?',
                    onTap: _send,
                  ),
                  _QuickPrompt(label: 'Find past papers for DSA', onTap: _send),
                  _QuickPrompt(label: 'Summarize latest notice', onTap: _send),
                  _QuickPrompt(label: 'Where do I get support?', onTap: _send),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  color: scheme.surfaceContainerLow,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.8),
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: _messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isThinking && index == _messages.length) {
                      return const _TypingBubble();
                    }
                    return _MessageBubble(message: _messages[index])
                        .animate()
                        .fadeIn(duration: 220.ms)
                        .slideY(begin: 0.04, end: 0);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              hintText: 'Ask VU AI Desk...',
                              prefixIcon: Icon(Icons.auto_awesome),
                              filled: false,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _send,
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(18),
                            backgroundColor: scheme.primary,
                            shadowColor: scheme.primary.withValues(alpha: 0.4),
                            elevation: 4,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Icon(
                              _isThinking
                                  ? Icons.hourglass_top
                                  : Icons.send_rounded,
                              key: ValueKey(_isThinking),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _AiHeader extends StatelessWidget {
  const _AiHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary, const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.36),
                      ),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 32,
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(0.94, 0.94),
                    end: const Offset(1.04, 1.04),
                    duration: 1400.ms,
                  ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VU AI Desk',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Campus helpdesk, smart search, summaries, and study support.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _MiniInfo(label: 'Mode', value: 'Campus AI'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniInfo(label: 'Sources', value: 'Verified'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniInfo(label: 'Tone', value: 'Friendly'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 380.ms).slideY(begin: -0.06, end: 0);
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _QuickPrompt extends StatelessWidget {
  const _QuickPrompt({required this.label, required this.onTap});

  final String label;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: const Icon(Icons.bolt, size: 18),
        label: Text(label),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        side: BorderSide.none,
        onPressed: () => onTap(label),
      ),
    );
  }
}

class _AiToolCard extends StatelessWidget {
  const _AiToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(left: 16, right: 2, bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.16),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final align = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isUser ? scheme.primary : scheme.surface;
    final textColor = message.isUser ? Colors.white : scheme.onSurface;
    return Align(
      alignment: align,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: message.isUser
              ? null
              : Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: textColor, height: 1.35),
            ),
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.sources
                    .map(
                      (source) => Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(source),
                        avatar: const Icon(Icons.verified, size: 16),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (message.actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.actions
                    .map(
                      (action) =>
                          OutlinedButton(onPressed: () {}, child: Text(action)),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ThinkingDots(),
              const SizedBox(width: 10),
              Text(
                'VU AI is thinking...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThinkingDots extends StatelessWidget {
  const _ThinkingDots();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) =>
            Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: index * 120),
                )
                .then()
                .fadeOut(duration: 400.ms),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
    this.sources = const [],
    this.actions = const [],
  });

  final bool isUser;
  final String text;
  final List<String> sources;
  final List<String> actions;
}
