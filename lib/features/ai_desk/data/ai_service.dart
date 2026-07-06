import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiResponse {
  const AiResponse({
    required this.answer,
    required this.sources,
    required this.actions,
  });

  final String answer;
  final List<String> sources;
  final List<String> actions;

  factory AiResponse.fromMap(Map<String, dynamic> data) {
    return AiResponse(
      answer: _asString(
        data['answer'],
        fallback: 'I could not prepare an answer.',
      ),
      sources: _asStringList(data['sources']),
      actions: _asStringList(data['actions']),
    );
  }

  static String _asString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static List<String> _asStringList(Object? value) {
    if (value is Iterable) {
      return value
          .whereType<Object>()
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

abstract class AiService {
  Future<AiResponse> ask(String prompt);
}

class FirebaseAiService implements AiService {
  FirebaseAiService({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
    AiService? fallback,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
       _auth = auth ?? FirebaseAuth.instance,
       _fallback = fallback ?? MockAiService();

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final AiService _fallback;

  @override
  Future<AiResponse> ask(String prompt) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return _signedOutResponse();
      }
      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        return _signedOutResponse();
      }

      final callable = _functions.httpsCallable('askVuAi');
      final result = await callable.call<Map<String, dynamic>>({
        'prompt': prompt,
        'idToken': idToken,
      });
      return AiResponse.fromMap(Map<String, dynamic>.from(result.data));
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'unauthenticated') {
        return _signedOutResponse();
      }
      if (_shouldUseFallback(error.code)) {
        final local = await _fallback.ask(prompt);
        return AiResponse(
          answer:
              'Live VU AI is not fully connected yet (${error.code}). '
              '${local.answer}',
          sources: ['Local campus guide', ...local.sources],
          actions: ['Configure AI backend', ...local.actions],
        );
      }
      return AiResponse(
        answer:
            'VU AI could not complete that request (${error.code}). Please retry in a moment. If it continues, sign out and sign in again so Firebase can refresh your secure session.',
        sources: const ['VU AI backend'],
        actions: const ['Retry question', 'Sign in again'],
      );
    } catch (_) {
      final local = await _fallback.ask(prompt);
      return AiResponse(
        answer:
            'I could not reach the live AI backend right now. ${local.answer}',
        sources: ['Local campus guide', ...local.sources],
        actions: ['Retry live AI', ...local.actions],
      );
    }
  }

  bool _shouldUseFallback(String code) {
    return code == 'unavailable' ||
        code == 'not-found' ||
        code == 'failed-precondition' ||
        code == 'internal';
  }

  AiResponse _signedOutResponse() {
    return const AiResponse(
      answer:
          'Please sign in again before using live VU AI. The AI backend protects usage with Firebase Authentication, and this request reached the server without a valid signed-in session.',
      sources: ['Firebase Authentication', 'VU AI backend'],
      actions: ['Sign out and sign in again', 'Retry VU AI'],
    );
  }
}

class MockAiService implements AiService {
  @override
  Future<AiResponse> ask(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final lower = prompt.toLowerCase();

    if (lower.contains('retake') || lower.contains('resit')) {
      return const AiResponse(
        answer:
            'For resits and retakes, open Requests & Applications in VClass or contact the Academic Registrar. VU Hub can guide the steps, required documents, and deadlines once the university FAQ collection is connected.',
        sources: ['VClass: Requests & Applications', 'AI FAQ placeholder'],
        actions: ['Open academic requests', 'Find registrar contact'],
      );
    }

    if (lower.contains('summarize announcement') ||
        lower.contains('latest notice') ||
        lower.contains('announcement summary')) {
      return const AiResponse(
        answer:
            'Here is the student-friendly version: identify the key deadline, who is affected, the required action, and the responsible office. Once the Cloud Function AI backend is connected, this card will summarize the exact announcement text automatically.',
        sources: ['VU Feed', 'announcements collection'],
        actions: ['Create action checklist', 'Find contact office'],
      );
    }

    if (lower.contains('summarize resource') ||
        lower.contains('summarize this paper') ||
        lower.contains('study with ai')) {
      return const AiResponse(
        answer:
            'I can turn this resource into revision notes, likely exam questions, flashcards, and a simple topic explanation. The current mock response proves the workflow; production AI should fetch the file text through a secure backend.',
        sources: ['VU Vault', 'past_papers collection'],
        actions: ['Generate flashcards', 'Create revision questions'],
      );
    }

    if (lower.contains('past paper') || lower.contains('study')) {
      return const AiResponse(
        answer:
            'I can help you search VU Vault, summarize a paper, generate revision questions, or create flashcards. Start from a resource card and choose “Study with AI”.',
        sources: ['VU Vault', 'past_papers collection'],
        actions: ['Search VU Vault', 'Generate revision questions'],
      );
    }

    return const AiResponse(
      answer:
          'I can help with campus offices, announcements, VU Vault resources, guild updates, events, VClass routing, and study support. Ask a specific question and I will return an answer with sources.',
      sources: ['VU Hub knowledge base', 'Approved campus data'],
      actions: ['Smart search', 'Ask help desk', 'Summarize announcement'],
    );
  }
}
