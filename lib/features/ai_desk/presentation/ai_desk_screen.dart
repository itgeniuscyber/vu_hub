import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/ai_service.dart';

class AiDeskScreen extends StatefulWidget {
  const AiDeskScreen({super.key});

  @override
  State<AiDeskScreen> createState() => _AiDeskScreenState();
}

class _AiDeskScreenState extends State<AiDeskScreen> {
  final _controller = TextEditingController();
  final _service = MockAiService();
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
              height: 56,
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
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _send,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.send),
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

class _AiHeader extends StatelessWidget {
  const _AiHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary, const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
                width: 56,
                height: 56,
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
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
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
    ).animate().fadeIn(duration: 380.ms).slideY(begin: -0.06, end: 0);
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
        onPressed: () => onTap(label),
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
          borderRadius: BorderRadius.circular(8),
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
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
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
