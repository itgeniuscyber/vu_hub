import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../auth/data/app_session.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../data/campus_event.dart';
import '../data/live_post.dart';
import '../data/live_posts_repository.dart';
import 'zego_live_room_screen.dart';

class VuLiveScreen extends StatefulWidget {
  const VuLiveScreen({super.key});

  @override
  State<VuLiveScreen> createState() => _VuLiveScreenState();
}

class _VuLiveScreenState extends State<VuLiveScreen> {
  final _repository = LivePostsRepository();
  final _pageController = PageController();
  final _commentController = TextEditingController();
  late final Stream<List<LivePost>> _feedStream;
  final Map<String, int> _localLikes = {};
  final Map<String, int> _localGifts = {};
  final Map<String, List<_LiveComment>> _localComments = {};
  final Set<String> _recordedViewIds = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _feedStream = _repository.watchFeed();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: StreamBuilder<List<LivePost>>(
          stream: _feedStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(18, 72, 18, 24),
                child: Column(
                  children: [
                    Expanded(child: LoadingShimmer(height: double.infinity)),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return FirestoreErrorState(
                error: snapshot.error!,
                icon: BoldRounded.videoCamera,
                title: 'Events unavailable',
                fallbackMessage: 'Campus events could not be loaded right now.',
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Container(
                color: Theme.of(context).colorScheme.surface,
                child: const EmptyState(
                  icon: BoldRounded.calendar,
                  title: 'No campus live streams yet',
                  message:
                      'Live streams from the events collection will appear here.',
                ),
              );
            }
            final activeIndex = _currentIndex
                .clamp(0, items.length - 1)
                .toInt();
            if (activeIndex != _currentIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _currentIndex = activeIndex);
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(activeIndex);
                }
              });
            }
            _recordActiveView(items, activeIndex);

            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const PageScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  itemCount: items.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final event = items[index];
                    return _LiveRoomPage(
                      event: event,
                      index: index,
                      total: items.length,
                      isActive: index == activeIndex,
                      likedCount:
                          event.likeCount + (_localLikes[event.id] ?? 0),
                      giftCount: event.giftCount + (_localGifts[event.id] ?? 0),
                      comments: _commentsFor(event),
                      commentController: _commentController,
                      onLike: () => _like(event),
                      onGift: (gift) => _sendGift(event, gift),
                      onSticker: (sticker) => _sendSticker(event, sticker),
                      onShare: () => _shareLivePost(event),
                      onSendComment: () => _sendComment(event, session),
                      onCreate: session.isSignedIn
                          ? () => _openStartLiveSheet(session)
                          : null,
                      onJoinRoom: event.isRealtimeRoom && session.isSignedIn
                          ? () => _openZegoRoom(event, session, isHost: false)
                          : null,
                    );
                  },
                ),
                Positioned(
                  left: 12,
                  top: MediaQuery.paddingOf(context).top + 8,
                  child: IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.28),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                    icon: const FUI(BoldRounded.arrowLeft),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: MediaQuery.paddingOf(context).top + 18,
                  child: _LiveProgressBadge(
                    current: activeIndex + 1,
                    total: items.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_LiveComment> _commentsFor(LivePost event) {
    return [
      ..._seedComments(event),
      ...(_localComments[event.id] ?? const <_LiveComment>[]),
    ];
  }

  void _recordActiveView(List<LivePost> items, int activeIndex) {
    if (activeIndex < 0 || activeIndex >= items.length) return;
    final event = items[activeIndex];
    if (!event.canOpenLiveExperience || _recordedViewIds.contains(event.id)) {
      return;
    }
    _recordedViewIds.add(event.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repository.recordView(event.id).catchError((_) {});
    });
  }

  List<_LiveComment> _seedComments(LivePost event) {
    return [
      _LiveComment('Aisha', 'This session is 🔥'),
      _LiveComment('Brian', 'Can you share the slides after?'),
      _LiveComment('VU Guild', 'Drop your questions here.'),
      _LiveComment(
        'Musa',
        event.isLive ? 'Watching from campus' : 'Waiting for this one',
      ),
    ];
  }

  Future<void> _like(LivePost event) async {
    setState(() {
      _localLikes[event.id] = (_localLikes[event.id] ?? 0) + 1;
    });
    await _repository.like(event.id);
  }

  Future<void> _sendGift(LivePost event, _LiveGift gift) async {
    final session = context.read<AppSession>();
    final name = session.profile?.displayName.split(' ').first ?? 'You';
    setState(() {
      _localGifts[event.id] = (_localGifts[event.id] ?? 0) + gift.value;
      _localComments
          .putIfAbsent(event.id, () => [])
          .add(_LiveComment(name, 'sent ${gift.label} ${gift.symbol}'));
    });
    await _repository.sendGift(
      postId: event.id,
      gift: '${gift.symbol} ${gift.label}',
      value: gift.value,
      displayName: name,
    );
  }

  void _sendSticker(LivePost event, String sticker) {
    setState(() {
      _localComments
          .putIfAbsent(event.id, () => [])
          .add(_LiveComment('You', sticker));
    });
  }

  Future<void> _shareLivePost(LivePost event) async {
    final lines = [
      event.isLive ? 'Join this VU Hub live stream:' : 'Watch this on VU Hub:',
      event.title,
      if (event.description.trim().isNotEmpty) event.description,
      'Host: ${event.hostName}',
      'Location: ${event.location}',
      if (event.primaryVideoUrl?.isNotEmpty == true) event.primaryVideoUrl!,
      if (event.isRealtimeRoom)
        'Open VU Hub > More > VU Live and join "${event.title}".',
    ];

    await SharePlus.instance.share(
      ShareParams(text: lines.join('\n'), subject: event.title),
    );
  }

  Future<void> _sendComment(LivePost event, AppSession session) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final name = session.profile?.displayName.split(' ').first ?? 'You';
    setState(() {
      _localComments
          .putIfAbsent(event.id, () => [])
          .add(_LiveComment(name, text));
      _commentController.clear();
    });
    await _repository.sendComment(
      postId: event.id,
      text: text,
      displayName: name,
    );
  }

  void _openStartLiveSheet(AppSession session) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _StartLiveSheet(session: session),
    );
  }

  void _openZegoRoom(
    LivePost event,
    AppSession session, {
    required bool isHost,
  }) {
    final roomId = event.providerRoomId.trim();
    if (roomId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: session,
          child: ZegoLiveRoomScreen(
            postId: event.id,
            roomId: roomId,
            title: event.title,
            isHost: isHost,
          ),
        ),
      ),
    );
  }
}

class _LiveComment {
  const _LiveComment(this.name, this.text);

  final String name;
  final String text;
}

class _LiveGift {
  const _LiveGift(this.symbol, this.label, this.value);

  final String symbol;
  final String label;
  final int value;
}

const _liveGifts = [
  _LiveGift('🎓', 'Scholar Cap', 5),
  _LiveGift('💎', 'Diamond', 20),
  _LiveGift('🏆', 'Trophy', 50),
];

class _LiveRoomPage extends StatelessWidget {
  const _LiveRoomPage({
    required this.event,
    required this.index,
    required this.total,
    required this.isActive,
    required this.likedCount,
    required this.giftCount,
    required this.comments,
    required this.commentController,
    required this.onLike,
    required this.onGift,
    required this.onSticker,
    required this.onShare,
    required this.onSendComment,
    required this.onCreate,
    required this.onJoinRoom,
  });

  final LivePost event;
  final int index;
  final int total;
  final bool isActive;
  final int likedCount;
  final int giftCount;
  final List<_LiveComment> comments;
  final TextEditingController commentController;
  final VoidCallback onLike;
  final ValueChanged<_LiveGift> onGift;
  final ValueChanged<String> onSticker;
  final VoidCallback onShare;
  final VoidCallback onSendComment;
  final VoidCallback? onCreate;
  final VoidCallback? onJoinRoom;

  Future<void> _openStream() async {
    if (event.isRealtimeRoom) {
      onJoinRoom?.call();
      return;
    }
    final url = event.primaryVideoUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final live = event.isLive;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: _LivePostMediaBackground(post: event, isActive: isActive),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.86),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          top: MediaQuery.paddingOf(context).top + 68,
          child: _LiveTopBar(event: event),
        ),
        Positioned(
          right: 14,
          bottom: 132,
          child: _LiveActionRail(
            likeCount: likedCount,
            giftCount: giftCount,
            onLike: onLike,
            onGift: onGift,
            onShare: onShare,
            onCreate: onCreate,
          ),
        ),
        Positioned(
          left: 18,
          right: 88,
          bottom: 128,
          child: _LiveInfoPanel(
            event: event,
            live: live,
            onOpenStream: _openStream,
          ),
        ),
        Positioned(
          left: 18,
          right: 88,
          bottom: 84,
          child: _StickerRail(onSticker: onSticker),
        ),
        Positioned(
          left: 18,
          right: 88,
          bottom: 184,
          child: _LiveCommentOverlay(comments: comments),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: MediaQuery.paddingOf(context).bottom + 14,
          child: _LiveComposer(
            controller: commentController,
            onSend: onSendComment,
          ),
        ),
      ],
    );
  }
}

class _LivePostMediaBackground extends StatefulWidget {
  const _LivePostMediaBackground({required this.post, required this.isActive});

  final LivePost post;
  final bool isActive;

  @override
  State<_LivePostMediaBackground> createState() =>
      _LivePostMediaBackgroundState();
}

class _LivePostMediaBackgroundState extends State<_LivePostMediaBackground> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _isPausedByUser = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant _LivePostMediaBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    final videoChanged = oldWidget.post.videoUrl != widget.post.videoUrl;
    final activeChanged = oldWidget.isActive != widget.isActive;

    if (videoChanged) {
      _releaseController();
    }

    if (!widget.isActive) {
      if (activeChanged || videoChanged) {
        _isPausedByUser = false;
        _releaseController();
      }
      return;
    }

    if (videoChanged || activeChanged || _controller == null) {
      _initializeVideo();
    } else {
      if (!_isPausedByUser) _controller?.play();
    }
  }

  Future<void> _initializeVideo() async {
    final url = widget.post.videoUrl;
    if (!widget.isActive || _initializing || url == null || url.isEmpty) {
      return;
    }

    setState(() => _initializing = true);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1);
      if (!_isPausedByUser) await controller.play();
      if (!mounted || !widget.isActive) {
        await controller.dispose();
        return;
      }
      await _releaseController();
      if (!mounted || !widget.isActive) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _releaseController() async {
    final controller = _controller;
    _controller = null;
    _initializing = false;
    await controller?.pause();
    await controller?.dispose();
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (!widget.isActive ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
      if (mounted) setState(() => _isPausedByUser = true);
      return;
    }
    await controller.play();
    if (mounted) setState(() => _isPausedByUser = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _togglePlayback,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
            if (_isPausedByUser)
              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.36),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const FUI(
                    BoldRounded.play,
                    color: Colors.white,
                    width: 36,
                    height: 36,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.isActive ? () => _initializeVideo() : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _LivePostCover(post: widget.post),
          if (widget.isActive && _initializing)
            Center(
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.36),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LivePostCover extends StatelessWidget {
  const _LivePostCover({required this.post});

  final LivePost post;

  @override
  Widget build(BuildContext context) {
    final cover = post.coverUrl;
    if (cover == null || cover.isEmpty) {
      return Image.asset(
        'assets/images/vu_default_card.png',
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: cover,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) =>
          Image.asset('assets/images/vu_default_card.png', fit: BoxFit.cover),
    );
  }
}

class _LiveTopBar extends StatelessWidget {
  const _LiveTopBar({required this.event});

  final LivePost event;

  @override
  Widget build(BuildContext context) {
    final live = event.isLive;
    final visibleViews = event.playCount > 0
        ? event.playCount
        : event.viewerCount;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white24,
          backgroundImage:
              event.hostAvatarUrl == null || event.hostAvatarUrl!.isEmpty
              ? null
              : CachedNetworkImageProvider(event.hostAvatarUrl!),
          child: event.hostAvatarUrl == null || event.hostAvatarUrl!.isEmpty
              ? const FUI(BoldRounded.school, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.hostName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                event.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.76)),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Follow'),
        ),
        const SizedBox(width: 8),
        _LiveGlassChip(
          icon: BoldRounded.eye,
          label: _formatCount(visibleViews),
        ),
        const SizedBox(width: 8),
        _LiveGlassChip(
          icon: live ? SolidRounded.circle : BoldRounded.clock,
          label: live ? 'Live' : _livePostDateLabel(event),
          color: live ? const Color(0xFFFF2D55) : Colors.white,
        ),
      ],
    );
  }
}

class _LiveInfoPanel extends StatelessWidget {
  const _LiveInfoPanel({
    required this.event,
    required this.live,
    required this.onOpenStream,
  });

  final LivePost event;
  final bool live;
  final VoidCallback onOpenStream;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          event.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          event.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.84)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
              label: event.location,
              icon: BoldRounded.mapMarker,
              maxWidth: 190,
            ),
            _Pill(
              label: _livePostDateLabel(event),
              icon: BoldRounded.clock,
              maxWidth: 160,
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: !event.canOpenLiveExperience ? null : onOpenStream,
          style: FilledButton.styleFrom(
            backgroundColor: live ? const Color(0xFFFF2D55) : Colors.white,
            foregroundColor: live ? Colors.white : Colors.black,
            minimumSize: const Size(0, 44),
          ),
          icon: FUI(
            event.isRealtimeRoom
                ? BoldRounded.videoCamera
                : live
                ? BoldRounded.play
                : BoldRounded.link,
            width: 18,
            height: 18,
          ),
          label: Text(
            event.isRealtimeRoom
                ? 'Join Live'
                : live
                ? 'Watch stream'
                : 'Open stream',
          ),
        ),
      ],
    );
  }
}

class _LiveActionRail extends StatelessWidget {
  const _LiveActionRail({
    required this.likeCount,
    required this.giftCount,
    required this.onLike,
    required this.onGift,
    required this.onShare,
    required this.onCreate,
  });

  final int likeCount;
  final int giftCount;
  final VoidCallback onLike;
  final ValueChanged<_LiveGift> onGift;
  final VoidCallback onShare;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onCreate != null) ...[
          _RoundLiveAction(
            icon: BoldRounded.add,
            label: 'Create',
            color: const Color(0xFFFF2D55),
            onTap: onCreate!,
          ),
          const SizedBox(height: 14),
        ],
        _RoundLiveAction(
          icon: BoldRounded.heart,
          label: _formatCount(likeCount),
          color: const Color(0xFFFF2D55),
          onTap: onLike,
        ),
        const SizedBox(height: 14),
        _GiftMenu(giftCount: giftCount, onGift: onGift),
        const SizedBox(height: 14),
        _RoundLiveAction(
          icon: BoldRounded.share,
          label: 'Share',
          color: Colors.white,
          onTap: onShare,
        ),
      ],
    );
  }
}

class _GiftMenu extends StatelessWidget {
  const _GiftMenu({required this.giftCount, required this.onGift});

  final int giftCount;
  final ValueChanged<_LiveGift> onGift;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_LiveGift>(
      color: Colors.black.withValues(alpha: 0.86),
      onSelected: onGift,
      itemBuilder: (context) => _liveGifts
          .map(
            (gift) => PopupMenuItem(
              value: gift,
              child: Text(
                '${gift.symbol} ${gift.label}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      child: _RoundLiveActionShell(
        icon: BoldRounded.gift,
        label: _formatCount(giftCount),
        color: const Color(0xFFFFC857),
      ),
    );
  }
}

class _RoundLiveAction extends StatelessWidget {
  const _RoundLiveAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: _RoundLiveActionShell(icon: icon, label: label, color: color),
    );
  }
}

class _RoundLiveActionShell extends StatelessWidget {
  const _RoundLiveActionShell({
    required this.icon,
    required this.label,
    required this.color,
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: FUI(icon, color: color, width: 20, height: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StickerRail extends StatelessWidget {
  const _StickerRail({required this.onSticker});

  final ValueChanged<String> onSticker;

  @override
  Widget build(BuildContext context) {
    const stickers = ['👏', '🔥', '🎉', '💙'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stickers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => InkWell(
          onTap: () => onSticker(stickers[index]),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Text(stickers[index], style: const TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

class _LiveCommentOverlay extends StatelessWidget {
  const _LiveCommentOverlay({required this.comments});

  final List<_LiveComment> comments;

  @override
  Widget build(BuildContext context) {
    final visible = comments.length > 4
        ? comments.sublist(comments.length - 4)
        : comments;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: visible
          .map(
            (comment) => Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.black.withValues(alpha: 0.34),
                ),
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${comment.name}  ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: comment.text,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LiveComposer extends StatelessWidget {
  const _LiveComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Comment...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          onPressed: onSend,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFEC3BCE),
            foregroundColor: Colors.white,
          ),
          icon: const FUI(BoldRounded.paperPlane, width: 20, height: 20),
        ),
      ],
    );
  }
}

class _LiveGlassChip extends StatelessWidget {
  const _LiveGlassChip({
    required this.icon,
    required this.label,
    this.color = Colors.white,
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FUI(icon, color: color, width: 15, height: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveProgressBadge extends StatelessWidget {
  const _LiveProgressBadge({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return _LiveGlassChip(icon: BoldRounded.arrowUp, label: '$current/$total');
  }
}

class _StartLiveSheet extends StatefulWidget {
  const _StartLiveSheet({required this.session});

  final AppSession session;

  @override
  State<_StartLiveSheet> createState() => _StartLiveSheetState();
}

class _StartLiveSheetState extends State<_StartLiveSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _streamController = TextEditingController();
  final _locationController = TextEditingController(
    text: 'Victoria University',
  );
  final _categoryController = TextEditingController(text: 'Campus Live');
  final _coverController = TextEditingController();
  _LiveCreateMode _mode = _LiveCreateMode.external;
  PlatformFile? _videoFile;
  PlatformFile? _coverFile;
  bool _saving = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';
  LiveUploadCancelToken? _uploadCancelToken;

  @override
  void dispose() {
    _uploadCancelToken?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _streamController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _coverController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    if (_saving) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: false,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.size > 150 * 1024 * 1024) {
      _showSnack('Choose a video below 150 MB.');
      return;
    }
    if (file.path == null && file.bytes == null) {
      _showSnack('This video could not be opened from its location.');
      return;
    }
    setState(() => _videoFile = file);
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    setState(() => _coverFile = result.files.single);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Add a title first.');
      return;
    }
    if (_mode == _LiveCreateMode.external &&
        _streamController.text.trim().isEmpty) {
      _showSnack('Add a stream link first.');
      return;
    }
    if (_mode == _LiveCreateMode.shortVideo && _videoFile == null) {
      _showSnack('Choose a short video first.');
      return;
    }

    setState(() {
      _saving = true;
      _uploadProgress = 0;
      _uploadStatus = _mode == _LiveCreateMode.shortVideo
          ? 'Preparing upload...'
          : 'Saving...';
      _uploadCancelToken = _mode == _LiveCreateMode.shortVideo
          ? LiveUploadCancelToken()
          : null;
    });
    try {
      final repository = LivePostsRepository();
      final description = _descriptionController.text.isEmpty
          ? 'Live campus stream'
          : _descriptionController.text;
      final hostName = widget.session.profile?.displayName ?? 'VU Host';
      CameraLiveRoom? cameraRoom;

      switch (_mode) {
        case _LiveCreateMode.external:
          await repository.createExternalLive(
            title: _titleController.text,
            description: description,
            playbackUrl: _streamController.text,
            location: _locationController.text,
            category: _categoryController.text,
            hostName: hostName,
            coverUrl: _coverController.text,
          );
        case _LiveCreateMode.shortVideo:
          await repository.createShortVideo(
            title: _titleController.text,
            description: description,
            category: _categoryController.text,
            location: _locationController.text,
            hostName: hostName,
            video: _videoFile!,
            cover: _coverFile,
            cancelToken: _uploadCancelToken,
            onStatus: (status) {
              if (!mounted) return;
              setState(() => _uploadStatus = status);
            },
            onProgress: (progress) {
              if (!mounted) return;
              setState(() => _uploadProgress = progress.clamp(0, 1).toDouble());
            },
          );
        case _LiveCreateMode.camera:
          cameraRoom = await repository.createZegoCameraLive(
            title: _titleController.text,
            description: description,
            category: _categoryController.text,
            location: _locationController.text,
            hostName: hostName,
          );
      }

      if (!mounted) return;
      final navigator = Navigator.of(context);
      Navigator.pop(context);
      _showSnack(
        _mode == _LiveCreateMode.camera
            ? 'Camera live room is ready.'
            : 'Live post created.',
      );
      if (cameraRoom != null) {
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => ChangeNotifierProvider.value(
              value: widget.session,
              child: ZegoLiveRoomScreen(
                postId: cameraRoom!.postId,
                roomId: cameraRoom.roomId,
                title: _titleController.text.trim(),
                isHost: true,
              ),
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showSnack('$error');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadProgress = 0;
          _uploadStatus = '';
          _uploadCancelToken = null;
        });
      }
    }
  }

  void _cancelUpload() {
    _uploadCancelToken?.cancel();
    setState(() => _uploadStatus = 'Cancelling upload...');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create VU Live content',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Create an external live, upload a short video, or prepare a real camera broadcast room for a streaming provider.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<_LiveCreateMode>(
              segments: const [
                ButtonSegment(
                  value: _LiveCreateMode.external,
                  icon: FUI(BoldRounded.link),
                  label: Text('Link'),
                ),
                ButtonSegment(
                  value: _LiveCreateMode.shortVideo,
                  icon: FUI(BoldRounded.play),
                  label: Text('Video'),
                ),
                ButtonSegment(
                  value: _LiveCreateMode.camera,
                  icon: FUI(BoldRounded.videoCamera),
                  label: Text('Camera'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (value) =>
                  setState(() => _mode = value.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            if (_mode == _LiveCreateMode.external)
              TextField(
                controller: _streamController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Stream link'),
              ),
            if (_mode == _LiveCreateMode.shortVideo)
              _PickedFileButton(
                icon: BoldRounded.file,
                label: _videoFile == null
                    ? 'Choose short video'
                    : '${_videoFile!.name} • ${_formatFileSize(_videoFile!.size)}',
                onPressed: _pickVideo,
              ),
            if (_mode == _LiveCreateMode.camera) const _ProviderNotice(),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            if (_mode == _LiveCreateMode.external)
              TextField(
                controller: _coverController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Cover image URL'),
              )
            else if (_mode == _LiveCreateMode.shortVideo)
              _PickedFileButton(
                icon: BoldRounded.picture,
                label: _coverFile?.name ?? 'Choose optional cover image',
                onPressed: _pickCover,
              ),
            const SizedBox(height: 18),
            if (_saving && _mode == _LiveCreateMode.shortVideo) ...[
              LinearProgressIndicator(
                value: _uploadProgress == 0 ? null : _uploadProgress,
              ),
              const SizedBox(height: 8),
              Text(
                _uploadStatus.isEmpty
                    ? 'Publishing video...'
                    : '$_uploadStatus • ${(_uploadProgress * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _cancelUpload,
                  icon: const FUI(BoldRounded.cross),
                  label: const Text('Cancel upload'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FUI(
                        _mode == _LiveCreateMode.shortVideo
                            ? BoldRounded.upload
                            : BoldRounded.videoCamera,
                        width: 18,
                        height: 18,
                      ),
                label: Text(
                  _mode == _LiveCreateMode.shortVideo
                      ? 'Publish video'
                      : _mode == _LiveCreateMode.camera
                      ? 'Prepare camera live'
                      : 'Go live',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LiveCreateMode { external, shortVideo, camera }

String _formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}

class _PickedFileButton extends StatelessWidget {
  const _PickedFileButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: FUI(icon, width: 18, height: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
    );
  }
}

class _ProviderNotice extends StatelessWidget {
  const _ProviderNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.primary.withValues(alpha: 0.09),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          FUI(
            BoldRounded.videoCamera,
            color: scheme.primary,
            width: 22,
            height: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This creates a real camera broadcast room. VU Hub stores the live post in Firebase and opens the streaming SDK as the host.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _LiveHeroCard extends StatelessWidget {
  const _LiveHeroCard({
    required this.event,
    required this.totalCount,
    required this.liveCount,
    required this.scheme,
  });

  final CampusEvent event;
  final int totalCount;
  final int liveCount;
  final ColorScheme scheme;

  Future<void> _openStream() async {
    final url = event.streamUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 216,
        child: Stack(
          children: [
            Positioned.fill(child: _EventImage(event: event)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      scheme.primary.withValues(alpha: 0.36),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GlassBadge(
                        label: event.status == CampusEventStatus.live
                            ? 'Live now'
                            : event.isFeatured
                            ? 'Featured'
                            : 'Next big event',
                        icon: event.status == CampusEventStatus.live
                            ? BoldRounded.videoCamera
                            : BoldRounded.magicWand,
                        pulse: event.status == CampusEventStatus.live,
                      ),
                      _GlassBadge(
                        label: event.category,
                        icon: BoldRounded.hastag,
                      ),
                      _GlassBadge(
                        label: '$liveCount live',
                        icon: BoldRounded.videoCamera,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Campus energy, all in one place',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        label: _dateLabel(event, short: false),
                        icon: BoldRounded.clock,
                        maxWidth: 150,
                      ),
                      _Pill(
                        label: event.location,
                        icon: BoldRounded.mapMarker,
                        maxWidth: 180,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              event.streamUrl == null ||
                                  event.streamUrl!.isEmpty
                              ? null
                              : _openStream,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 42),
                          ),
                          icon: FUI(
                            event.status == CampusEventStatus.live
                                ? BoldRounded.videoCamera
                                : BoldRounded.link,
                            width: 18,
                            height: 18,
                          ),
                          label: Text(
                            event.status == CampusEventStatus.live
                                ? 'Join now'
                                : 'Open stream',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: () {},
                        icon: const FUI(BoldRounded.bellRing),
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

// ignore: unused_element
class _InsightStrip extends StatelessWidget {
  const _InsightStrip({
    required this.liveCount,
    required this.upcomingCount,
    required this.completedCount,
  });

  final int liveCount;
  final int upcomingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            icon: SolidRounded.circle,
            label: 'Live',
            value: '$liveCount',
            color: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InsightCard(
            icon: BoldRounded.calendar,
            label: 'Upcoming',
            value: '$upcomingCount',
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InsightCard(
            icon: BoldRounded.confetti,
            label: 'Completed',
            value: '$completedCount',
            color: scheme.tertiary,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final String icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.14),
              child: FUI(icon, color: color, width: 18, height: 18),
            ),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StreamLounge extends StatelessWidget {
  const _StreamLounge({required this.items});

  final List<CampusEvent> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Campus stream lounge'),
        const SizedBox(height: 4),
        Text(
          'A live-style showcase for sessions, premieres, and moments happening around campus.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                SizedBox(width: 240, child: _StreamCard(event: items[index])),
          ),
        ),
      ],
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.event});

  final CampusEvent event;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(
        'assets/images/vu_default_card.png',
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) =>
          Image.asset('assets/images/vu_default_card.png', fit: BoxFit.cover),
    );
  }
}

// ignore: unused_element
class _EventSection extends StatelessWidget {
  const _EventSection({
    required this.title,
    required this.subtitle,
    required this.items,
    // ignore: unused_element_parameter
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final List<CampusEvent> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  child: FUI(
                    BoldRounded.calendar,
                    color: Theme.of(context).colorScheme.primary,
                    width: 22,
                    height: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No events in this state right now.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          ...items.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: compact
                  ? _CompactEventTile(event: event)
                  : _EventTile(event: event),
            ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.04, end: 0),
          ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final CampusEvent event;

  Future<void> _openStream() async {
    final url = event.streamUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final label = switch (event.status) {
      CampusEventStatus.live => 'Live now',
      CampusEventStatus.completed => 'Completed',
      CampusEventStatus.upcoming => 'Upcoming',
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 176,
                width: double.infinity,
                child: _EventImage(event: event),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.46),
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
                child: _GlassBadge(
                  label: label,
                  icon: event.status == CampusEventStatus.live
                      ? BoldRounded.videoCamera
                      : BoldRounded.clock,
                  pulse: event.status == CampusEventStatus.live,
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: _GlassBadge(
                  label: event.category,
                  icon: BoldRounded.hastag,
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SoftMetaPill(
                      icon: BoldRounded.clock,
                      label: _dateLabel(event, short: true),
                      maxWidth: 150,
                    ),
                    _SoftMetaPill(
                      icon: BoldRounded.mapMarker,
                      label: event.location,
                      maxWidth: 210,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            event.streamUrl == null || event.streamUrl!.isEmpty
                            ? null
                            : _openStream,
                        icon: FUI(
                          event.status == CampusEventStatus.live
                              ? BoldRounded.videoCamera
                              : BoldRounded.link,
                          width: 18,
                          height: 18,
                        ),
                        label: Text(
                          event.status == CampusEventStatus.live
                              ? 'Join now'
                              : 'Open stream',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: () {},
                      icon: const FUI(BoldRounded.bellRing),
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

class _CompactEventTile extends StatelessWidget {
  const _CompactEventTile({required this.event});

  final CampusEvent event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 72,
                height: 86,
                child: _EventImage(event: event),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  _SoftMetaPill(
                    icon: BoldRounded.clock,
                    label: _dateLabel(event, short: true),
                    maxWidth: 140,
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

class _StreamCard extends StatelessWidget {
  const _StreamCard({required this.event});

  final CampusEvent event;

  Future<void> _openStream() async {
    final url = event.streamUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final live = event.status == CampusEventStatus.live;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(child: _EventImage(event: event)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    scheme.primary.withValues(alpha: 0.22),
                    Colors.black.withValues(alpha: 0.74),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassBadge(
                  label: live ? 'Streaming' : 'Showcase',
                  icon: live ? BoldRounded.videoCamera : BoldRounded.play,
                  pulse: live,
                ),
                const Spacer(),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  event.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        event.streamUrl == null || event.streamUrl!.isEmpty
                        ? null
                        : _openStream,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: scheme.primary,
                    ),
                    icon: FUI(
                      live ? BoldRounded.play : BoldRounded.link,
                      width: 18,
                      height: 18,
                    ),
                    label: Text(live ? 'Watch now' : 'Preview stream'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, this.maxWidth = 180});

  final String label;
  final String icon;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FUI(icon, width: 16, height: 16, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftMetaPill extends StatelessWidget {
  const _SoftMetaPill({
    required this.icon,
    required this.label,
    this.maxWidth = 180,
  });

  final String icon;
  final String label;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: scheme.surfaceContainerHighest,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FUI(icon, width: 16, height: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({
    required this.label,
    required this.icon,
    this.pulse = false,
  });

  final String label;
  final String icon;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FUI(icon, color: Colors.white, width: 16, height: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );

    if (!pulse) return badge;
    return badge
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(begin: 0.82, end: 1);
  }
}

String _dateLabel(CampusEvent event, {required bool short}) {
  final start = event.startTime;
  if (start == null) return 'Date TBC';

  final now = DateTime.now();
  final sameDay =
      start.year == now.year &&
      start.month == now.month &&
      start.day == now.day;
  if (sameDay) {
    final diff = start.difference(now);
    if (diff.inMinutes > 0 && diff.inHours < 12) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      if (hours > 0) {
        return 'Starts in ${hours}h ${minutes}m';
      }
      return 'Starts in ${diff.inMinutes}m';
    }
    return short
        ? 'Today • ${DateFormat('HH:mm').format(start)}'
        : 'Today at ${DateFormat('HH:mm').format(start)}';
  }
  return short
      ? DateFormat('MMM d • HH:mm').format(start)
      : DateFormat('EEE, MMM d • HH:mm').format(start);
}

String _livePostDateLabel(LivePost post) {
  final start = post.startedAt ?? post.createdAt;
  if (post.status == LivePostStatus.published) return 'Short video';
  if (post.status == LivePostStatus.processing) return 'Processing';
  if (post.status == LivePostStatus.ended) return 'Replay';
  if (start == null) return 'Scheduled';

  final now = DateTime.now();
  final sameDay =
      start.year == now.year &&
      start.month == now.month &&
      start.day == now.day;
  if (sameDay) return DateFormat('HH:mm').format(start);
  return DateFormat('MMM d').format(start);
}

String _formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return '$value';
}
