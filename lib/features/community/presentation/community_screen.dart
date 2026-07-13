import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/data/app_session.dart';
import '../data/community_models.dart';
import '../data/community_repository.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: _PublicChatTab()));
  }
}

class CommunityDiscussionsScreen extends StatelessWidget {
  const CommunityDiscussionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CommunityListPage(
      title: 'Discussions',
      subtitle: 'Academic questions and helpful campus threads',
      icon: Icons.question_answer_outlined,
      child: _DiscussionTab(),
    );
  }
}

class CommunityPostsScreen extends StatelessWidget {
  const CommunityPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CommunityListPage(
      title: 'Campus Posts',
      subtitle: 'Student updates, guild posts, and shared moments',
      icon: Icons.dynamic_feed_outlined,
      child: _PostsTab(),
    );
  }
}

class _CommunityListPage extends StatelessWidget {
  const _CommunityListPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.12),
                      scheme.secondary.withValues(alpha: 0.08),
                      scheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.14),
                      child: Icon(icon, color: scheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _PublicChatTab extends StatefulWidget {
  const _PublicChatTab();

  @override
  State<_PublicChatTab> createState() => _PublicChatTabState();
}

class _PublicChatTabState extends State<_PublicChatTab> {
  final _repository = CommunityRepository();
  final _messageController = TextEditingController();
  CommunityMessage? _replyTo;
  PlatformFile? _image;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.size > 8 * 1024 * 1024) {
      _showSnack('Please choose an image below 8 MB.');
      return;
    }
    if (file.bytes == null) {
      _showSnack('The selected image could not be read. Try another one.');
      return;
    }

    setState(() => _image = file);
  }

  Future<void> _send() async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty && _image == null) return;

    setState(() => _isSending = true);
    try {
      await _repository.sendPublicMessage(
        text: text,
        replyTo: _replyTo,
        image: _image,
      );
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _replyTo = null;
        _image = null;
      });
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final currentUserId = session.firebaseUser?.uid;

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF070B15), Color(0xFF0D1830)]
                : const [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomPaint(
          painter: _ChatRoomBackgroundPainter(
            color: isDark
                ? Colors.white.withValues(alpha: 0.045)
                : scheme.primary.withValues(alpha: 0.055),
          ),
          child: Column(
            children: [
              _ChatRoomHeader(currentUserName: session.profile?.displayName),
              Expanded(
                child: StreamBuilder<List<CommunityMessage>>(
                  stream: _repository.watchPublicChat(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                        children: const [
                          LoadingShimmer(height: 84),
                          SizedBox(height: 14),
                          LoadingShimmer(height: 110),
                          SizedBox(height: 14),
                          LoadingShimmer(height: 84),
                        ],
                      );
                    }
                    if (snapshot.hasError) {
                      return FirestoreErrorState(
                        error: snapshot.error!,
                        icon: Icons.forum_outlined,
                        title: 'Public chat unavailable',
                        fallbackMessage:
                            'Messages from the public chat could not be loaded.',
                      );
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'No public chat yet',
                        message:
                            'Messages from `public_chat` will appear here when available.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                      reverse: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final message = items[index];
                        final previousMessage = index == items.length - 1
                            ? null
                            : items[index + 1];
                        final showDateDivider =
                            message.createdAt != null &&
                            (previousMessage == null ||
                                previousMessage.createdAt == null ||
                                !_sameDay(
                                  message.createdAt!,
                                  previousMessage.createdAt!,
                                ));

                        final bubble =
                            _ChatBubble(
                                  message: message,
                                  currentUserId: currentUserId,
                                  onReply: () =>
                                      setState(() => _replyTo = message),
                                )
                                .animate()
                                .fadeIn(duration: 220.ms)
                                .slideX(begin: 0.03, end: 0);

                        if (!showDateDivider) return bubble;
                        return Column(
                          children: [
                            _DateDivider(date: message.createdAt!),
                            const SizedBox(height: 14),
                            bubble,
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              _ChatInputBar(
                controller: _messageController,
                replyTo: _replyTo,
                image: _image,
                isSending: _isSending,
                onCancelReply: () => setState(() => _replyTo = null),
                onRemoveImage: () => setState(() => _image = null),
                onPickImage: _pickImage,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ChatRoomHeader extends StatelessWidget {
  const _ChatRoomHeader({required this.currentUserName});

  final String? currentUserName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF10192B).withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          if (canPop) ...[
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 2),
          ],
          Container(
            width: canPop ? 42 : 48,
            height: canPop ? 42 : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.school_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VU com chat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  currentUserName == null
                      ? 'Public student room'
                      : 'Signed in as $currentUserName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Voice call',
            onPressed: null,
            icon: Icon(Icons.call_outlined, color: scheme.primary),
          ),
          IconButton(
            tooltip: 'Video call',
            onPressed: null,
            icon: Icon(Icons.video_call_outlined, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        DateFormat('EEEE, MMM d, yyyy').format(date),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.currentUserId,
    required this.onReply,
  });

  final CommunityMessage message;
  final String? currentUserId;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isMe = currentUserId != null && message.senderId == currentUserId;

    final bubbleColor = isMe
        ? const Color(0xFF146C94)
        : (isDark ? const Color(0xFF10203A) : Colors.white);

    final textColor = isMe
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);
    final metaColor = isMe
        ? Colors.white70
        : (isDark ? Colors.white54 : Colors.black54);

    return GestureDetector(
      onLongPress: onReply,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _SenderAvatar(message: message),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMe
                        ? const Radius.circular(20)
                        : const Radius.circular(6),
                    bottomRight: isMe
                        ? const Radius.circular(6)
                        : const Radius.circular(20),
                  ),
                  border: Border.all(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.08)
                        : scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.24 : 0.07,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.replyToText != null &&
                          message.replyToText!.trim().isNotEmpty)
                        _InlineReplyCard(
                          name: message.replyToName ?? 'Someone',
                          text: message.replyToText!,
                          isMe: isMe,
                        ),
                      if (message.mediaUrl != null &&
                          message.mediaUrl!.trim().isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: message.mediaUrl!,
                            width: double.infinity,
                            height: 174,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Container(
                              height: 132,
                              color: Colors.black.withValues(alpha: 0.12),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: metaColor,
                              ),
                            ),
                          ),
                        ),
                        if (message.text != 'Shared an image')
                          const SizedBox(height: 10),
                      ],
                      if (message.text.trim().isNotEmpty &&
                          !(message.text == 'Shared an image' &&
                              message.mediaUrl != null))
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor,
                            height: 1.32,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMe
                                      ? 'sent'
                                      : 'sent by: ${message.senderName}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: metaColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!isMe &&
                                    message.senderFaculty != null &&
                                    message.senderFaculty!
                                        .trim()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    message.senderFaculty!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: metaColor.withValues(alpha: 0.82),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            message.createdAt == null
                                ? 'Now'
                                : DateFormat(
                                    'hh:mm a',
                                  ).format(message.createdAt!),
                            style: TextStyle(fontSize: 10, color: metaColor),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: Colors.cyanAccent.withValues(alpha: 0.9),
                            ),
                          ],
                          const SizedBox(width: 2),
                          InkWell(
                            onTap: onReply,
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.reply_rounded,
                                size: 16,
                                color: metaColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 9),
            _SenderAvatar(message: message),
          ],
        ],
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.message});

  final CommunityMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photoUrl = message.senderPhotoUrl;
    return CircleAvatar(
      radius: 21,
      backgroundColor: scheme.primary.withValues(alpha: 0.14),
      backgroundImage: photoUrl == null || photoUrl.trim().isEmpty
          ? null
          : CachedNetworkImageProvider(photoUrl),
      child: photoUrl == null || photoUrl.trim().isEmpty
          ? Text(
              message.senderName.characters.first.toUpperCase(),
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

class _InlineReplyCard extends StatelessWidget {
  const _InlineReplyCard({
    required this.name,
    required this.text,
    required this.isMe,
  });

  final String name;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isMe ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.cyanAccent : scheme.secondary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Replying to: $name',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isMe ? Colors.white : scheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.78)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.replyTo,
    required this.image,
    required this.isSending,
    required this.onCancelReply,
    required this.onRemoveImage,
    required this.onPickImage,
    required this.onSend,
  });

  final TextEditingController controller;
  final CommunityMessage? replyTo;
  final PlatformFile? image;
  final bool isSending;
  final VoidCallback onCancelReply;
  final VoidCallback onRemoveImage;
  final VoidCallback onPickImage;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D1525).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyTo != null)
            _ComposerReplyPreview(message: replyTo!, onClose: onCancelReply),
          if (image != null)
            _ComposerImagePreview(image: image!, onClose: onRemoveImage),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton.filledTonal(
                tooltip: 'Attach image',
                onPressed: isSending ? null : onPickImage,
                icon: const Icon(Icons.image_outlined),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    enabled: !isSending,
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                height: 52,
                child: FilledButton(
                  onPressed: isSending ? null : onSend,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    backgroundColor: scheme.primary,
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerReplyPreview extends StatelessWidget {
  const _ComposerReplyPreview({required this.message, required this.onClose});

  final CommunityMessage message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.senderName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  message.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ComposerImagePreview extends StatelessWidget {
  const _ComposerImagePreview({required this.image, required this.onClose});

  final PlatformFile image;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              image.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          IconButton(
            tooltip: 'Remove image',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ChatRoomBackgroundPainter extends CustomPainter {
  const _ChatRoomBackgroundPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var x = 28.0; x < size.width; x += 82) {
      for (var y = 26.0; y < size.height; y += 74) {
        canvas.drawCircle(Offset(x, y), 7, paint);
        canvas.drawLine(Offset(x + 18, y - 5), Offset(x + 34, y + 9), paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 44, y + 18, 18, 14),
            const Radius.circular(4),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChatRoomBackgroundPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DiscussionTab extends StatelessWidget {
  const _DiscussionTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DiscussionThread>>(
      stream: CommunityRepository().watchDiscussions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              LoadingShimmer(height: 120),
              SizedBox(height: 12),
              LoadingShimmer(height: 120),
            ],
          );
        }
        if (snapshot.hasError) {
          return FirestoreErrorState(
            error: snapshot.error!,
            icon: Icons.question_answer_outlined,
            title: 'Discussions unavailable',
            fallbackMessage: 'Discussion threads are unavailable right now.',
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.question_answer_outlined,
            title: 'No discussions yet',
            message:
                'Discussion threads from the existing collection will appear here.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const SectionHeader(title: 'Academic and community threads'),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DiscussionCard(thread: item)
                    .animate()
                    .fadeIn(duration: 240.ms)
                    .slideX(begin: 0.03, end: 0),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityPost>>(
      stream: CommunityRepository().watchPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              LoadingShimmer(height: 220),
              SizedBox(height: 12),
              LoadingShimmer(height: 220),
            ],
          );
        }
        if (snapshot.hasError) {
          return FirestoreErrorState(
            error: snapshot.error!,
            icon: Icons.dynamic_feed_outlined,
            title: 'Posts unavailable',
            fallbackMessage: 'Community posts could not be loaded.',
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.dynamic_feed_outlined,
            title: 'No community posts yet',
            message:
                'Campus posts from `posts` will appear here once they are available.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _PostCard(
            post: items[index],
          ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.04, end: 0),
        );
      },
    );
  }
}

class _DiscussionCard extends StatelessWidget {
  const _DiscussionCard({required this.thread});

  final DiscussionThread thread;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CommunityTag(
                  label: thread.category,
                  tone: scheme.primary,
                  icon: Icons.sell_outlined,
                ),
                _CommunityTag(
                  label: '${thread.commentCount} replies',
                  tone: scheme.secondary,
                  icon: Icons.mode_comment_outlined,
                ),
                if (thread.isResolved)
                  _CommunityTag(
                    label: 'Resolved',
                    tone: scheme.tertiary,
                    icon: Icons.verified_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(thread.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(thread.body, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Text(
              '${thread.authorName} • ${thread.createdAt == null ? 'Recently' : DateFormat('MMM d').format(thread.createdAt!)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    height: 188,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      height: 188,
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: scheme.outline,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.34),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: _CommunityTag(
                    label: post.category,
                    tone: Colors.white,
                    icon: Icons.local_offer_outlined,
                    lightForeground: false,
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        post.authorName.characters.first.toUpperCase(),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        post.authorName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      post.createdAt == null
                          ? 'Recently'
                          : DateFormat('MMM d').format(post.createdAt!),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(post.caption),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _PostMeta(
                      icon: Icons.favorite_border,
                      label: '${post.likeCount}',
                      tone: scheme.primary,
                    ),
                    _PostMeta(
                      icon: Icons.mode_comment_outlined,
                      label: '${post.commentCount}',
                      tone: scheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTag extends StatelessWidget {
  const _CommunityTag({
    required this.label,
    required this.tone,
    required this.icon,
    this.lightForeground = true,
  });

  final String label;
  final Color tone;
  final IconData icon;
  final bool lightForeground;

  @override
  Widget build(BuildContext context) {
    final foreground = lightForeground ? tone : Colors.white;
    final background = lightForeground
        ? tone.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.18);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: background,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _PostMeta extends StatelessWidget {
  const _PostMeta({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: tone),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
