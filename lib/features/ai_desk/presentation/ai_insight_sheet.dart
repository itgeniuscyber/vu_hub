import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';

import '../data/ai_service.dart';

Future<void> showAiInsightSheet({
  required BuildContext context,
  required String title,
  required String prompt,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AiInsightSheet(title: title, prompt: prompt),
  );
}

class _AiInsightSheet extends StatefulWidget {
  const _AiInsightSheet({required this.title, required this.prompt});

  final String title;
  final String prompt;

  @override
  State<_AiInsightSheet> createState() => _AiInsightSheetState();
}

class _AiInsightSheetState extends State<_AiInsightSheet> {
  late final Future<AiResponse> _response;

  @override
  void initState() {
    super.initState();
    _response = FirebaseAiService().ask(widget.prompt);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: FutureBuilder<AiResponse>(
        future: _response,
        builder: (context, snapshot) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!snapshot.hasData)
                const _AiLoadingCard()
              else
                _AiResponseCard(response: snapshot.data!)
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

class _AiResponseCard extends StatelessWidget {
  const _AiResponseCard({required this.response});

  final AiResponse response;

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
