import 'package:flutter_test/flutter_test.dart';
import 'package:study_nest/data/quiz_questions.dart';

void main() {
  test('All 40 questions across 4 subjects have valid difficulty (1..3) and unique IDs', () {
    final all = [
      ...QuizQuestionBank.calculusQuestions,
      ...QuizQuestionBank.biologyQuestions,
      ...QuizQuestionBank.historyQuestions,
      ...QuizQuestionBank.physicsQuestions,
    ];

    expect(QuizQuestionBank.calculusQuestions.length, 10);
    expect(QuizQuestionBank.biologyQuestions.length, 10);
    expect(QuizQuestionBank.historyQuestions.length, 10);
    expect(QuizQuestionBank.physicsQuestions.length, 10);
    expect(all.length, 40);

    final ids = <String>{};
    for (final q in all) {
      expect(ids.add(q.id), isTrue, reason: 'Duplicate question id: ${q.id}');
      expect(q.difficulty, inInclusiveRange(1, 3), reason: 'Invalid difficulty on ${q.id}');
    }
  });
}
