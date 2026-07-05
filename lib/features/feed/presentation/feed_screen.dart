import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/firestore_error_message.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../ai_desk/presentation/ai_insight_sheet.dart';
import '../../auth/data/app_session.dart';
import '../data/announcement.dart';
import '../data/announcement_repository.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedCategory = 'All';

  static const _categories = [
    'All',
    'General',
    'Academic',
    'Events',
    'Guild',
    'Urgent',
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'VU Feed',
                action: session.canPublishAnnouncements
                    ? FilledButton.icon(
                        onPressed: () => _openPublisher(context, session),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Publish'),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Official notices, guild updates, and urgent campus communication.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _CategoryBar(
                selected: _selectedCategory,
                onSelected: (value) =>
                    setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<Announcement>>(
                  stream: AnnouncementRepository().watchLatest(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return FirestoreErrorState(
                        error: snapshot.error!,
                        title: 'Could not load announcements',
                        fallbackMessage:
                            'The announcements feed is unavailable right now.',
                      );
                    }
                    final items = (snapshot.data ?? [])
                        .where(
                          (item) =>
                              _selectedCategory == 'All' ||
                              item.category == _selectedCategory,
                        )
                        .toList();
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.campaign_outlined,
                        title: 'No official notices yet',
                        message:
                            'Announcements will appear here when the collection has matching items.',
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _AnnouncementCard(item: items[index])
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.05, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPublisher(BuildContext context, AppSession session) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AnnouncementComposerSheet(session: session),
    );
    if (!context.mounted || result != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement published successfully.')),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _FeedScreenState._categories
            .map(
              (label) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: label == selected,
                  label: Text(label),
                  onSelected: (_) => onSelected(label),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AnnouncementComposerSheet extends StatefulWidget {
  const _AnnouncementComposerSheet({required this.session});

  final AppSession session;

  @override
  State<_AnnouncementComposerSheet> createState() =>
      _AnnouncementComposerSheetState();
}

class _AnnouncementComposerSheetState
    extends State<_AnnouncementComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = 'General';
  bool _isPinned = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final profile = widget.session.profile;
    try {
      await AnnouncementRepository().publishAnnouncement(
        title: _titleController.text,
        content: _contentController.text,
        category: _category,
        publishedBy:
            profile?.displayName ??
            widget.session.firebaseUser?.email ??
            'VU Admin',
        authorId: widget.session.firebaseUser?.uid ?? '',
        isPinned: _isPinned,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeFirestoreError(
              error,
              fallback: 'We could not publish this announcement.',
            ),
          ),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publish announcement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a title'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Content'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter announcement content'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _FeedScreenState._categories
                  .where((item) => item != 'All')
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _category = value ?? 'General'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pin this announcement'),
              value: _isPinned,
              onChanged: (value) => setState(() => _isPinned = value),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isSaving ? null : _publish,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_outlined),
              label: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(item.category)),
                const Spacer(),
                if (item.isPinned) Icon(Icons.push_pin, color: scheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(item.content, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => showAiInsightSheet(
                context: context,
                title: 'Announcement summary',
                prompt:
                    'Summarize announcement "${item.title}". Category: ${item.category}. Content: ${item.content}',
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Summarize'),
            ),
          ],
        ),
      ),
    );
  }
}
