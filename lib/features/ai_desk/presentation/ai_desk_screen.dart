import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';
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
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _messages.length + (_isThinking ? 1 : 0) + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AiHeader(scheme: scheme),
                        SizedBox(
                          height: 160,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _AiToolCard(
                                title: 'Smart search',
                                subtitle: 'Find notices, events, and resources',
                                icon: BoldRounded.map,
                                color: scheme.primary,
                                onTap: () => _send(
                                  'Search campus help for exam timetable and latest notices',
                                ),
                              ),
                              _AiToolCard(
                                title: 'Study assist',
                                subtitle:
                                    'Summaries, flashcards, revision help',
                                icon: BoldRounded.book,
                                color: scheme.secondary,
                                onTap: () => _send(
                                  'Create revision questions from a past paper',
                                ),
                              ),
                              _AiToolCard(
                                title: 'Route me',
                                subtitle: 'Find the right office or process',
                                icon: BoldRounded.network,
                                color: const Color(0xFF8B5CF6),
                                onTap: () => _send(
                                  'Where should I go for retake applications?',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _QuickPrompt(
                                label: 'How do I apply for a retake?',
                                onTap: _send,
                              ),
                              _QuickPrompt(
                                label: 'Find past papers for DSA',
                                onTap: _send,
                              ),
                              _QuickPrompt(
                                label: 'Summarize latest notice',
                                onTap: _send,
                              ),
                              _QuickPrompt(
                                label: 'Where do I get support?',
                                onTap: _send,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }

                  final msgIndex = index - 1;
                  if (_isThinking && msgIndex == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _TypingBubble(),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _MessageBubble(message: _messages[msgIndex])
                        .animate()
                        .fadeIn(duration: 220.ms)
                        .slideY(begin: 0.04, end: 0),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 5,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                hintText: 'Ask VU AI Desk...',
                                hintStyle: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _send,
                            style: FilledButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                              backgroundColor: scheme.primary,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: FUI(
                                _isThinking
                                    ? BoldRounded.menuDots
                                    : BoldRounded.arrowUp,
                                key: ValueKey(_isThinking),
                                color: scheme.onPrimary,
                                width: 22,
                                height: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                    child: const FUI(
                      BoldRounded.headSideThinking,
                      color: Colors.white,
                      width: 28,
                      height: 28,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VU AI Desk',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Campus helpdesk, smart search, summaries, and study support.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        avatar: FUI(
          BoldRounded.magicWand,
          width: 16,
          height: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
  final String icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(left: 16, right: 2, bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: FUI(icon, color: color, width: 18, height: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
    final color = message.isUser ? scheme.primary : scheme.surfaceContainerHigh;
    final textColor = message.isUser ? scheme.onPrimary : scheme.onSurface;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomLeft: Radius.circular(message.isUser ? 24 : 8),
      bottomRight: Radius.circular(message.isUser ? 8 : 24),
    );

    return Align(
      alignment: align,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: textColor, height: 1.5, fontSize: 15),
            ),
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.sources
                    .map(
                      (source) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FUI(
                              SolidRounded.check,
                              width: 14,
                              height: 14,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              source,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (message.actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.actions
                    .map(
                      (action) => FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          action,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
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
