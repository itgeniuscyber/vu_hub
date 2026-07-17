import 'package:flutter/material.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';

import '../utils/firestore_error_message.dart';
import 'empty_state.dart';

class FirestoreErrorState extends StatelessWidget {
  const FirestoreErrorState({
    super.key,
    required this.error,
    this.title = 'Could not load content',
    this.icon = BoldRounded.cloudDisabled,
    this.fallbackMessage = 'Please try again in a moment.',
  });

  final Object error;
  final String title;
  final Object icon;
  final String fallbackMessage;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      message: describeFirestoreError(error, fallback: fallbackMessage),
    );
  }
}
