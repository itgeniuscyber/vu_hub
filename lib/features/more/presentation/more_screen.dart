import 'package:flutter/material.dart';

import '../../../core/widgets/section_header.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem(
        Icons.groups,
        'Guild Hub',
        'Verified guild updates and feedback',
      ),
      _MoreItem(
        Icons.location_city,
        'Dept Finder',
        'Departments, offices, and lecturers',
      ),
      _MoreItem(Icons.live_tv, 'VU Live', 'Campus events and stream links'),
      _MoreItem(
        Icons.forum,
        'Community',
        'Public chat, discussions, and posts',
      ),
      _MoreItem(
        Icons.settings,
        'Settings',
        'Theme, notifications, and account',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            const SectionHeader(title: 'More'),
            const SizedBox(height: 8),
            Text(
              'The next VU Hub modules are scaffolded here and ready for implementation.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    minVerticalPadding: 16,
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    subtitle: Text(item.subtitle),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}
