import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../data/vault_repository.dart';
import '../data/vault_resource.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'VU Vault'),
              const SizedBox(height: 8),
              Text(
                'Past papers, resources, policies, and study materials from the existing Firebase database.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search past papers and resources',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: StreamBuilder<List<VaultResource>>(
                  stream: VaultRepository().watchPastPapers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return EmptyState(
                        icon: Icons.warning_amber,
                        title: 'Could not load VU Vault',
                        message: snapshot.error.toString(),
                      );
                    }
                    final resources = (snapshot.data ?? [])
                        .where(
                          (item) =>
                              _query.isEmpty ||
                              item.title.toLowerCase().contains(
                                _query.toLowerCase(),
                              ) ||
                              item.faculty.toLowerCase().contains(
                                _query.toLowerCase(),
                              ),
                        )
                        .toList();
                    if (resources.isEmpty) {
                      return const EmptyState(
                        icon: Icons.folder_copy_outlined,
                        title: 'No matching resources',
                        message:
                            'Your existing past papers will appear here when Firestore returns them.',
                      );
                    }
                    return ListView.separated(
                      itemCount: resources.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _VaultResourceCard(resource: resources[index])
                            .animate()
                            .fadeIn(duration: 280.ms)
                            .slideY(begin: 0.04, end: 0);
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
}

class _VaultResourceCard extends StatelessWidget {
  const _VaultResourceCard({required this.resource});

  final VaultResource resource;

  Future<void> _openResource() async {
    final uri = Uri.tryParse(resource.fileUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 70,
                height: 86,
                color: scheme.primary.withValues(alpha: 0.12),
                child: resource.thumbnailUrl == null
                    ? Icon(Icons.picture_as_pdf, color: scheme.primary)
                    : CachedNetworkImage(
                        imageUrl: resource.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            Icon(Icons.picture_as_pdf, color: scheme.primary),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(resource.faculty),
                  const SizedBox(height: 4),
                  Text(
                    '${resource.fileType.toUpperCase()} • ${resource.uploadedBy}'
                    '${resource.uploadedAt == null ? '' : ' • ${DateFormat.MMMd().format(resource.uploadedAt!)}'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: resource.fileUrl.isEmpty
                            ? null
                            : _openResource,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Study with AI'),
                      ),
                    ],
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
