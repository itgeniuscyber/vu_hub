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
            (doc) => DirectoryEntry.fromMap(doc.id, {
              ...asMap(doc.data()),
              'name': asString(doc.data()['name']) ?? doc.id,
            }),
          )
          .toList();
      entries.sort((a, b) {
        final route = a.routeLabel.compareTo(b.routeLabel);
        if (route != 0) return route;
        return a.department.compareTo(b.department);
      });
      return entries;
    });
  }

  static const List<DirectoryEntry> _seedEntries = [
    DirectoryEntry(
      id: 'student_support',
      name: 'Student Support Centre',
      department: 'Student Support',
      role: 'Help Desk',
      email: 'support@vu.ac.zw',
      phone: '+263 242 000 001',
      location: 'Main Campus Reception',
      category: 'Support',
      description:
          'First stop for general student support, welfare questions, guidance, and routing to the right office.',
      officeHours: 'Mon-Fri, 8:00 AM - 5:00 PM',
      services: ['General help', 'Student welfare', 'Office routing'],
      keywords: ['support', 'help', 'counselling', 'advice', 'welfare'],
    ),
    DirectoryEntry(
      id: 'academic_registry',
      name: 'Academic Registry',
      department: 'Registry',
      role: 'Requests and Applications',
      email: 'registry@vu.ac.zw',
      phone: '+263 242 000 102',
      location: 'Administration Block',
      category: 'Academic',
      description:
          'Handles academic records, retakes, resits, deferment, programme changes, and formal student applications.',
      officeHours: 'Mon-Fri, 8:00 AM - 5:00 PM',
      services: ['Retakes and resits', 'Academic records', 'Applications'],
      keywords: [
        'retake',
        'resit',
        'deferment',
        'applications',
        'records',
        'transcript',
      ],
    ),
    DirectoryEntry(
      id: 'finance_office',
      name: 'Finance Office',
      department: 'Finance',
      role: 'Payments and Statements',
      email: 'finance@vu.ac.zw',
      phone: '+263 242 000 220',
      location: 'Finance Building',
      category: 'Finance',
      description:
          'Supports tuition payments, financial statements, fee balances, receipts, and payment-related clarifications.',
      officeHours: 'Mon-Fri, 8:00 AM - 4:30 PM',
      services: ['Tuition payments', 'Statements', 'Receipts'],
      keywords: ['tuition', 'payments', 'statements', 'fees', 'balance'],
    ),
    DirectoryEntry(
      id: 'ict_help_desk',
      name: 'ICT Help Desk',
      department: 'ICT Services',
      role: 'Digital Support',
      email: 'ictsupport@vu.ac.zw',
      phone: '+263 242 000 330',
      location: 'Innovation Hub',
      category: 'Digital',
      description:
          'Helps with VClass, student portal access, Wi-Fi, email accounts, and campus digital services.',
      officeHours: 'Mon-Fri, 8:00 AM - 5:00 PM',
      services: ['VClass help', 'Portal access', 'Wi-Fi support'],
      keywords: ['wifi', 'portal', 'vclass', 'account', 'password', 'email'],
    ),
    DirectoryEntry(
      id: 'faculty_office',
      name: 'Faculty Office',
      department: 'Academic Faculties',
      role: 'Faculty Administration',
      email: 'faculty@vu.ac.zw',
      phone: '+263 242 000 410',
      location: 'Faculty Administration Block',
      category: 'Faculty',
      description:
          'Routes students to faculty administrators, heads of department, lecturers, and academic unit support.',
      officeHours: 'Mon-Fri, 8:30 AM - 5:00 PM',
      services: ['Lecturer routing', 'Department support', 'Academic advising'],
      keywords: ['faculty', 'lecturer', 'department', 'hod', 'course unit'],
    ),
  ];
}
