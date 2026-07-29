import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';
import '../../auth/data/user_profile.dart';
import '../../feed/data/announcement.dart';
import '../../guild/data/guild_repository.dart';
import '../../live/data/live_post.dart';

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<AdminOverview> watchOverview() {
    return _firestore
        .collection('announcements')
        .limit(80)
        .snapshots()
        .asyncMap((announcements) async {
          final guild = await _firestore
              .collection('guild_posts')
              .limit(80)
              .get();
          final live = await _firestore
              .collection('live_posts')
              .limit(80)
              .get();
          final users = await _firestore.collection('users').limit(120).get();
          final liveItems = live.docs.map(LivePost.fromDoc).toList();
          return AdminOverview(
            feedPosts: announcements.docs.length,
            guildNotices: guild.docs.length,
            liveItems: live.docs.length,
            liveNow: liveItems
                .where((item) => item.status == LivePostStatus.live)
                .length,
            users: users.docs.length,
          );
        });
  }

  Stream<List<Announcement>> watchAnnouncements() {
    return _firestore.collection('announcements').limit(80).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(Announcement.fromDoc).toList();
      items.sort(
        (a, b) => _sortDate(b.createdAt).compareTo(_sortDate(a.createdAt)),
      );
      return items;
    });
  }

  Stream<List<GuildNotice>> watchGuildNotices() {
    return _firestore.collection('guild_posts').limit(80).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(GuildNotice.fromDoc).toList();
      items.sort(
        (a, b) => _sortDate(b.createdAt).compareTo(_sortDate(a.createdAt)),
      );
      return items;
    });
  }

  Stream<List<LivePost>> watchLivePosts() {
    return _firestore.collection('live_posts').limit(80).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(LivePost.fromDoc).toList();
      items.sort((a, b) {
        final left = b.startedAt ?? b.createdAt;
        final right = a.startedAt ?? a.createdAt;
        return _sortDate(left).compareTo(_sortDate(right));
      });
      return items;
    });
  }

  Stream<List<AdminUserAccount>> watchUsers() {
    return _firestore.collection('users').limit(150).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(AdminUserAccount.fromDoc).toList();
      items.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return items;
    });
  }

  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    required String category,
    required bool isPinned,
  }) async {
    await _firestore.collection('announcements').doc(id).update({
      'title': title.trim(),
      'content': content.trim(),
      'body': content.trim(),
      'category': category.trim().isEmpty ? 'General' : category.trim(),
      'isPinned': isPinned,
      'pinned': isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnnouncement(String id) {
    return _firestore.collection('announcements').doc(id).delete();
  }

  Future<void> updateGuildNotice({
    required String id,
    required String title,
    required String body,
    required String category,
    required String priority,
    required bool isPinned,
  }) async {
    await _firestore.collection('guild_posts').doc(id).update({
      'title': title.trim(),
      'body': body.trim(),
      'content': body.trim(),
      'category': category.trim().isEmpty ? 'Guild' : category.trim(),
      'priority': priority.trim().isEmpty ? 'normal' : priority.trim(),
      'isPinned': isPinned,
      'pinned': isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteGuildNotice(String id) {
    return _firestore.collection('guild_posts').doc(id).delete();
  }

  Future<void> updateLivePost({
    required String id,
    required String title,
    required String description,
    required String status,
  }) async {
    final payload = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'body': description.trim(),
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'ended') {
      payload['endedAt'] = FieldValue.serverTimestamp();
    }
    await _firestore.collection('live_posts').doc(id).update(payload);
  }

  Future<void> deleteLivePost(String id) {
    return _firestore.collection('live_posts').doc(id).delete();
  }

  Future<void> updateUserRole({
    required String uid,
    required AppUserRole role,
  }) async {
    final roleKey = UserProfile.roleKey(role);
    await _firestore.collection('users').doc(uid).update({
      'role': roleKey,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  DateTime _sortDate(DateTime? date) => date ?? DateTime(1970);
}

class AdminOverview {
  const AdminOverview({
    required this.feedPosts,
    required this.guildNotices,
    required this.liveItems,
    required this.liveNow,
    required this.users,
  });

  final int feedPosts;
  final int guildNotices;
  final int liveItems;
  final int liveNow;
  final int users;
}

class AdminUserAccount {
  const AdminUserAccount({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.faculty,
    required this.regNo,
    required this.createdAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final AppUserRole role;
  final String faculty;
  final String regNo;
  final DateTime? createdAt;

  factory AdminUserAccount.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final profile = UserProfile.fromFirestore(doc.id, data);
    return AdminUserAccount(
      uid: doc.id,
      displayName: profile.displayName,
      email: profile.email,
      role: profile.role,
      faculty: profile.faculty,
      regNo: profile.regNo,
      createdAt: firstDate(data, ['createdAt', 'timestamp', 'joinedAt']),
    );
  }
}
