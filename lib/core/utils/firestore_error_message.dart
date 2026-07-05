import 'package:firebase_core/firebase_core.dart';

String describeFirestoreError(
  Object error, {
  String fallback = 'We could not load data right now.',
}) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to access this content with the current account.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Check your connection and try again.';
      case 'unauthenticated':
        return 'Please sign in again to continue.';
      case 'failed-precondition':
        return 'This data is not available yet because Firebase needs additional setup.';
      case 'not-found':
        return 'The requested content could not be found.';
      case 'cancelled':
        return 'The request was cancelled before Firebase could finish.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : fallback;
    }
  }
  return fallback;
}
