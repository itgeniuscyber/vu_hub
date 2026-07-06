import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/firestore_error_message.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../../ai_desk/presentation/ai_insight_sheet.dart';
import '../../auth/data/app_session.dart';
import '../data/vault_repository.dart';
import '../data/vault_resource.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  String _query = '';
  String _faculty = 'All';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.watch<AppSession>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: scheme.surfaceContainer,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: scheme.primary.withValues(alpha: 0.14),
                      child: Icon(
                        Icons.folder_copy_outlined,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VU Vault',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Past papers and study materials mapped safely from the existing `past_papers` collection.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (session.canUploadResources) ...[
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => _openUploader(context, session),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Upload'),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search past papers, faculties, and subjects',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: StreamBuilder<List<VaultResource>>(
                  stream: VaultRepository().watchPastPapers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView(
                        children: const [
                          LoadingShimmer(height: 152),
                          SizedBox(height: 12),
                          LoadingShimmer(height: 152),
                          SizedBox(height: 12),
                          LoadingShimmer(height: 152),
                        ],
                      );
                    }
                    if (snapshot.hasError) {
                      return FirestoreErrorState(
                        error: snapshot.error!,
                        title: 'Could not load VU Vault',
                        fallbackMessage:
                            'Past papers and resources are unavailable right now.',
                      );
                    }
                    final allResources = snapshot.data ?? [];
                    final faculties = {
                      'All',
                      ...allResources
                          .map((item) => item.faculty)
                          .where((item) => item.isNotEmpty),
                    }.toList();
                    final resources = allResources.where((item) {
                      final matchesQuery =
                          _query.isEmpty ||
                          item.title.toLowerCase().contains(
                            _query.toLowerCase(),
                          ) ||
                          item.faculty.toLowerCase().contains(
                            _query.toLowerCase(),
                          ) ||
                          item.uploadedBy.toLowerCase().contains(
                            _query.toLowerCase(),
                          );
                      final matchesFaculty =
                          _faculty == 'All' || item.faculty == _faculty;
                      return matchesQuery && matchesFaculty;
                    }).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Browse by faculty'),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: faculties.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final label = faculties[index];
                              return ChoiceChip(
                                selected: _faculty == label,
                                label: Text(label),
                                onSelected: (_) =>
                                    setState(() => _faculty = label),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${resources.length} resources available',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: resources.isEmpty
                              ? const EmptyState(
                                  icon: Icons.folder_copy_outlined,
                                  title: 'No matching resources',
                                  message:
                                      'Try a different faculty filter or broader search term.',
                                )
                              : ListView.separated(
                                  itemCount: resources.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    return _VaultResourceCard(
                                          resource: resources[index],
                                        )
                                        .animate()
                                        .fadeIn(duration: 280.ms)
                                        .slideY(begin: 0.04, end: 0);
                                  },
                                ),
                        ),
                      ],
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

  Future<void> _openUploader(BuildContext context, AppSession session) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VaultUploadSheet(session: session),
    );
    if (!context.mounted || result != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resource uploaded successfully.')),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 74,
                height: 96,
                color: scheme.primary.withValues(alpha: 0.12),
                child: resource.thumbnailUrl == null
                    ? Image.asset(
                        'assets/images/vu_default_card.png',
                        fit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        imageUrl: resource.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Image.asset(
                          'assets/images/vu_default_card.png',
                          fit: BoxFit.cover,
                        ),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(resource.faculty)),
                      Chip(label: Text(resource.fileType.toUpperCase())),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Uploaded by ${resource.uploadedBy}'
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
                        onPressed: () => showAiInsightSheet(
                          context: context,
                          title: 'Study with AI',
                          prompt:
                              'Summarize resource "${resource.title}" from ${resource.faculty}. File type: ${resource.fileType}. Study with AI.',
                        ),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Summarize'),
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

class _VaultUploadSheet extends StatefulWidget {
  const _VaultUploadSheet({required this.session});

  final AppSession session;

  @override
  State<_VaultUploadSheet> createState() => _VaultUploadSheetState();
}

class _VaultUploadSheetState extends State<_VaultUploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _facultyController = TextEditingController();
  final _externalUrlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();

  PlatformFile? _selectedFile;
  PlatformFile? _selectedThumbnail;
  String _fileType = 'pdf';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _facultyController.dispose();
    _externalUrlController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      type: FileType.custom,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() {
      _selectedFile = file;
      final extension = file.extension?.toLowerCase();
      if (extension != null && extension.isNotEmpty) {
        _fileType = extension;
      }
    });
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      type: FileType.custom,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    setState(() => _selectedThumbnail = result.files.single);
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_selectedFile?.bytes == null || _selectedFile!.bytes!.isEmpty) &&
        _externalUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a file or provide an external resource URL.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final profile = widget.session.profile;
    try {
      await VaultRepository().uploadPastPaper(
        title: _titleController.text,
        faculty: _facultyController.text,
        uploadedBy:
            profile?.displayName ??
            widget.session.firebaseUser?.email ??
            'VU Staff',
        uploaderId: widget.session.firebaseUser?.uid ?? '',
        fileType: _fileType,
        fileName: _selectedFile?.name ?? 'resource.$_fileType',
        fileBytes: _selectedFile?.bytes,
        externalFileUrl: _externalUrlController.text,
        thumbnailUrl: _thumbnailUrlController.text,
        thumbnailBytes: _selectedThumbnail?.bytes,
        thumbnailFileName: _selectedThumbnail?.name,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeFirestoreError(
              error,
              fallback: 'We could not upload this resource.',
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload VU Vault resource',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Subject or title',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a resource title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _facultyController,
                decoration: const InputDecoration(labelText: 'Faculty'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter the faculty'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _fileType,
                decoration: const InputDecoration(labelText: 'File type'),
                items: const [
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'docx', child: Text('DOCX')),
                  DropdownMenuItem(value: 'pptx', child: Text('PPTX')),
                ],
                onChanged: (value) =>
                    setState(() => _fileType = value ?? 'pdf'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _selectedFile == null ? 'Pick file' : _selectedFile!.name,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickThumbnail,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  _selectedThumbnail == null
                      ? 'Pick thumbnail image'
                      : _selectedThumbnail!.name,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _externalUrlController,
                decoration: const InputDecoration(
                  labelText: 'External file URL',
                  hintText: 'Optional if you upload a file directly',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _thumbnailUrlController,
                decoration: const InputDecoration(
                  labelText: 'Thumbnail URL',
                  hintText: 'Optional preview image',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSaving ? null : _upload,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: const Text('Upload resource'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
