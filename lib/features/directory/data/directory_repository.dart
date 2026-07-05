import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';
import 'directory_models.dart';

class DirectoryRepository {
  DirectoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<DirectoryEntry>> watchEntries() {
    return _firestore.collection('departments').limit(50).snapshots().map((
      snapshot,
    ) {
      if (snapshot.docs.isEmpty) {
        return _seedEntries;
      }
      final entries = snapshot.docs
          .map(
            (doc) => DirectoryEntry.fromMap({
              ...asMap(doc.data()),
              'name': asString(doc.data()['name']) ?? doc.id,
            }),
          )
          .toList();
      entries.sort((a, b) => a.department.compareTo(b.department));
      return entries;
    });
  }

  static const List<DirectoryEntry> _seedEntries = [
    DirectoryEntry(
      name: 'Student Support Centre',
      department: 'Student Support',
      role: 'Help Desk',
      email: 'support@vu.ac.zw',
      phone: '+263 242 000 001',
      location: 'Main Campus Reception',
      keywords: ['support', 'help', 'counselling', 'advice'],
    ),
    DirectoryEntry(
      name: 'Academic Registry',
      department: 'Registry',
      role: 'Requests and Applications',
      email: 'registry@vu.ac.zw',
      phone: '+263 242 000 102',
      location: 'Administration Block',
      keywords: ['retake', 'deferment', 'applications', 'records'],
    ),
    DirectoryEntry(
      name: 'Finance Office',
      department: 'Finance',
      role: 'Payments and Statements',
      email: 'finance@vu.ac.zw',
      phone: '+263 242 000 220',
      location: 'Finance Building',
      keywords: ['tuition', 'payments', 'statements', 'fees'],
    ),
    DirectoryEntry(
      name: 'ICT Help Desk',
      department: 'ICT Services',
      role: 'Digital Support',
      email: 'ictsupport@vu.ac.zw',
      phone: '+263 242 000 330',
      location: 'Innovation Hub',
      keywords: ['wifi', 'portal', 'vclass', 'account'],
    ),
  ];
}
