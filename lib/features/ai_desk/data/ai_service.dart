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
