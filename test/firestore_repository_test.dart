import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vu_hub/features/auth/data/user_profile.dart';
import 'package:vu_hub/features/community/data/community_repository.dart';
import 'package:vu_hub/features/directory/data/directory_repository.dart';
import 'package:vu_hub/features/directory/data/vu_resource_repository.dart';
import 'package:vu_hub/features/feed/data/announcement_repository.dart';
import 'package:vu_hub/features/live/data/events_repository.dart';
import 'package:vu_hub/features/vault/data/vault_repository.dart';

void main() {
  group('Firestore repository compatibility', () {
    test(
      'AnnouncementRepository reads mixed timestamp field variants',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('announcements').doc('older').set({
          'title': 'Earlier notice',
          'body': 'Existing body field',
          'author': 'Registry',
          'publishedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        });
        await firestore.collection('announcements').doc('newer').set({
          'headline': 'Latest notice',
          'content': 'Existing content field',
          'publishedBy': 'Admin Office',
          'createdAt': Timestamp.fromDate(DateTime(2026, 2, 1)),
          'pinned': true,
        });

        final items = await AnnouncementRepository(
          firestore: firestore,
        ).watchLatest().first;

        expect(items, hasLength(2));
        expect(items.first.title, 'Latest notice');
        expect(items.first.isPinned, isTrue);
        expect(items.first.publishedBy, 'Admin Office');
      },
    );

    test('VaultRepository reads existing past_papers shape', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('past_papers').doc('paper_1').set({
        'subject': 'Data Structures',
        'faculty': 'Engineering',
        'fileType': 'pdf',
        'fileUrl': 'https://example.com/paper.pdf',
        'thumbnailUrl': 'https://example.com/thumb.png',
        'uploadedBy': 'Lecturer Jane',
        'uploadedAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      });

      final items = await VaultRepository(
        firestore: firestore,
      ).watchPastPapers().first;

      expect(items.single.title, 'Data Structures');
      expect(items.single.faculty, 'Engineering');
      expect(items.single.fileUrl, contains('paper.pdf'));
    });

    test(
      'CommunityRepository reads public_chat, discussions, and posts',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('public_chat').doc('msg_1').set({
          'message': 'Hello campus',
          'username': 'Student A',
          'faculty': 'Science And Technology',
          'senderPic': 'https://example.com/avatar.png',
          'replyToSender': 'Student B',
          'replyToMessage': 'Where are the notes?',
          'timestamp': Timestamp.fromDate(DateTime(2026, 2, 3)),
        });
        await firestore.collection('discussions').doc('thread_1').set({
          'topic': 'Exam prep',
          'description': 'How are you revising?',
          'createdByName': 'Student B',
          'replyCount': 4,
        });
        await firestore.collection('posts').doc('post_1').set({
          'content': 'Guild meeting tonight',
          'postedBy': 'Guild Office',
          'likes': 12,
          'comments': 2,
        });

        final repository = CommunityRepository(firestore: firestore);
        final messages = await repository.watchPublicChat().first;
        final discussions = await repository.watchDiscussions().first;
        final posts = await repository.watchPosts().first;

        expect(messages.single.text, 'Hello campus');
        expect(messages.single.senderFaculty, 'Science And Technology');
        expect(messages.single.senderPhotoUrl, contains('avatar.png'));
        expect(messages.single.replyToName, 'Student B');
        expect(messages.single.replyToText, 'Where are the notes?');
        expect(discussions.single.title, 'Exam prep');
        expect(discussions.single.commentCount, 4);
        expect(posts.single.caption, 'Guild meeting tonight');
        expect(posts.single.likeCount, 12);
      },
    );

    test(
      'EventsRepository reads event field aliases and computes status',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('events').doc('event_1').set({
          'name': 'Career Fair',
          'details': 'Meet employers on campus',
          'venue': 'Main Hall',
          'liveUrl': 'https://example.com/live',
          'eventDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 1)),
          ),
          'type': 'Career',
          'featured': true,
        });

        final items = await EventsRepository(
          firestore: firestore,
        ).watchEvents().first;

        expect(items.single.title, 'Career Fair');
        expect(items.single.location, 'Main Hall');
        expect(items.single.isFeatured, isTrue);
      },
    );

    test(
      'VuResourceRepository reads vu_resources compatibility fields',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('vu_resources').doc('resource_1').set({
          'name': 'Exam timetable',
          'summary': 'Semester exam dates',
          'faculty': 'Academic',
          'link': 'https://example.com/exams',
          'group': 'All students',
          'publishedAt': Timestamp.fromDate(DateTime(2026, 4, 1)),
        });

        final items = await VuResourceRepository(
          firestore: firestore,
        ).watchResources().first;

        expect(items.single.title, 'Exam timetable');
        expect(items.single.url, contains('exams'));
        expect(items.single.audience, 'All students');
      },
    );

    test('DirectoryRepository reads rich department routing fields', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('departments').doc('ict').set({
        'name': 'ICT Help Desk',
        'office': 'ICT Services',
        'position': 'Digital Support',
        'email': 'ict@vu.ac.zw',
        'phoneNumber': '+256 700 000 000',
        'officeLocation': 'Innovation Hub',
        'category': 'Digital',
        'description': 'Helps students with VClass and Wi-Fi.',
        'officeHours': 'Mon-Fri, 8:00 AM - 5:00 PM',
        'services': ['VClass help', 'Wi-Fi support'],
        'keywords': ['vclass', 'wifi'],
      });

      final items = await DirectoryRepository(
        firestore: firestore,
      ).watchEntries().first;

      expect(items.single.name, 'ICT Help Desk');
      expect(items.single.routeLabel, 'Digital');
      expect(items.single.services, contains('VClass help'));
      expect(items.single.officeHours, contains('Mon-Fri'));
    });

    test('UserProfile parses roles without reading password fields', () {
      final profile = UserProfile.fromFirestore('uid_1', {
        'role': 'admin',
        'displayName': 'Admin User',
        'email': 'admin@vu.ac.zw',
        'password': 'legacy-plain-text-field-that-must-be-ignored',
      });

      expect(profile.uid, 'uid_1');
      expect(profile.role, AppUserRole.admin);
      expect(profile.displayName, 'Admin User');
      expect(profile.email, 'admin@vu.ac.zw');
    });
  });
}
