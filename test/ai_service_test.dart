import 'package:flutter_test/flutter_test.dart';
import 'package:vu_hub/features/ai_desk/data/ai_service.dart';

void main() {
  test('MockAiService returns source-aware retake guidance', () async {
    final service = MockAiService();

    final response = await service.ask('How do I apply for a retake?');

    expect(response.answer, contains('resits and retakes'));
    expect(response.sources, isNotEmpty);
    expect(response.actions, isNotEmpty);
  });
}
