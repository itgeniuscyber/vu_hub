import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';

import '../data/ai_service.dart';

Future<void> showAiInsightSheet({
  required BuildContext context,
  required String title,
  required String prompt,
  AiResourceContext? resource,
  AiPostContext? post,
  String targetLanguage = 'English',
  String mode = 'insight',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AiInsightSheet(
      title: title,
      prompt: prompt,
      resource: resource,
      post: post,
      targetLanguage: targetLanguage,
      mode: mode,
    ),
  );
}

class _AiInsightSheet extends StatefulWidget {
  const _AiInsightSheet({
    required this.title,
    required this.prompt,
    required this.mode,
    required this.targetLanguage,
    this.resource,
    this.post,
  });

  final String title;
  final String prompt;
  final AiResourceContext? resource;
  final AiPostContext? post;
  final String targetLanguage;
  final String mode;

  @override
  State<_AiInsightSheet> createState() => _AiInsightSheetState();
}

class _AiInsightSheetState extends State<_AiInsightSheet> {
  late Future<AiResponse> _response;
  late String _activePrompt;
  late String _targetLanguage;

  @override
  void initState() {
    super.initState();
    _activePrompt = widget.prompt;
    _targetLanguage = widget.targetLanguage;
    _response = _ask(widget.prompt);
  }

  Future<AiResponse> _ask(String prompt, {String? targetLanguage}) {
    return FirebaseAiService().ask(
      prompt,
      resource: widget.resource,
      post: widget.post,
      targetLanguage: targetLanguage ?? _targetLanguage,
      mode: widget.mode,
    );
  }

  void _followUp(String action) {
    final prompt = widget.resource != null
        ? '$action for "${widget.resource!.title}". Use the same extracted paper text and give a clear student study output.'
        : widget.post != null
        ? '$action for the selected VU Feed post "${widget.post!.title}". Use the same post text and give a specific useful answer.'
        : action;
    setState(() {
      _activePrompt = action;
      _response = _ask(prompt);
    });
  }

  void _changeLanguage(String language) {
    final prompt = widget.post == null
        ? 'Answer in $language: ${widget.prompt}'
        : 'Summarize and rewrite this VU Feed post in $language. Keep the meaning accurate, explain any university terms simply, and include what the student should do next.';
    setState(() {
      _targetLanguage = language;
      _activePrompt = language == 'English'
          ? 'Student-friendly summary'
          : 'Translate to $language';
      _response = _ask(prompt, targetLanguage: language);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.sizeOf(context).height * 0.86;
    return SizedBox(
      height: height,
      child: FutureBuilder<AiResponse>(
        future: _response,
        builder: (context, snapshot) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primary.withValues(alpha: 0.14),
                    child: FUI(
                      BoldRounded.magicWand,
                      color: scheme.primary,
                      width: 22,
                      height: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _activePrompt == widget.prompt
                          ? widget.title
                          : _activePrompt,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.post != null) ...[
                _LanguageStrip(
                  selected: _targetLanguage,
                  onSelected: _changeLanguage,
                ),
                const SizedBox(height: 14),
              ],
              if (!snapshot.hasData)
                const _AiLoadingCard()
              else
                _AiResponseCard(response: snapshot.data!, onAction: _followUp)
                    .animate()
                    .fadeIn(duration: 260.ms)
                    .slideY(begin: 0.04, end: 0),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const FUI(BoldRounded.check, width: 18, height: 18),
                label: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AiLoadingCard extends StatelessWidget {
  const _AiLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'VU AI is preparing an insight...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageStrip extends StatelessWidget {
  const _LanguageStrip({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const _languages = [
    'English',
    'Luganda',
    'Swahili',
    'Runyankole',
    'Arabic',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _languages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final language = _languages[index];
          final active = language == selected;
          return ChoiceChip(
            selected: active,
            avatar: FUI(
              active ? SolidRounded.check : BoldRounded.comment,
              width: 15,
              height: 15,
              color: active ? scheme.onPrimaryContainer : scheme.primary,
            ),
            label: Text(language),
            onSelected: (_) => onSelected(language),
          );
        },
      ),
    );
  }
}

class _AiResponseCard extends StatelessWidget {
  const _AiResponseCard({required this.response, required this.onAction});

  final AiResponse response;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(response.answer, style: Theme.of(context).textTheme.bodyLarge),
            if (response.sources.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Sources', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: response.sources
                    .map(
                      (source) => Chip(
                        avatar: FUI(
                          SolidRounded.check,
                          width: 16,
                          height: 16,
                          color: scheme.primary,
                        ),
                        label: Text(source),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (response.actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Suggested next steps',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: response.actions
                    .map(
                      (action) => OutlinedButton(
                        onPressed: () => onAction(action),
                        child: Text(action),
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
