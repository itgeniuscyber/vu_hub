class AiResponse {
  const AiResponse({
    required this.answer,
    required this.sources,
    required this.actions,
  });

  final String answer;
  final List<String> sources;
  final List<String> actions;
}

abstract class AiService {
  Future<AiResponse> ask(String prompt);
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
