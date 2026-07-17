import 'package:flutter/material.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final Object icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EmptyStateIcon(icon: icon, color: scheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateIcon extends StatelessWidget {
  const _EmptyStateIcon({required this.icon, required this.color});

  final Object icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = icon;
    if (value is String) {
      return FUI(value, width: 42, height: 42, color: color);
    }
    return Icon(value as IconData, size: 42, color: color);
  }
}
