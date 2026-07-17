import 'package:flutter/material.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final Object icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricIcon(icon: icon, color: color),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({required this.icon, required this.color});

  final Object icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = icon;
    if (value is String) {
      return FUI(value, color: color, width: 24, height: 24);
    }
    return Icon(value as IconData, color: color);
  }
}
