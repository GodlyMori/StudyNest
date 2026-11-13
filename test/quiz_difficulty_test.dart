import 'package:flutter_test/flutter_test.dart';
import 'package:study_nest/data/quiz_questions.dart';

void main() {
  test('All 100 questions across 4 subjects have valid difficulty (1..3) and unique IDs', () {
    final all = [
      ...QuizQuestionBank.calculusQuestions,
      ...QuizQuestionBank.biologyQuestions,
      ...QuizQuestionBank.historyQuestions,
      ...QuizQuestionBank.physicsQuestions,
    ];

    expect(QuizQuestionBank.calculusQuestions.length, 25);
    expect(QuizQuestionBank.biologyQuestions.length, 25);
    expect(QuizQuestionBank.historyQuestions.length, 25);
    expect(QuizQuestionBank.physicsQuestions.length, 25);
    expect(all.length, 100);

    final ids = <String>{};
    for (final q in all) {
      expect(ids.add(q.id), isTrue, reason: 'Duplicate question id: ${q.id}');
      expect(q.difficulty, inInclusiveRange(1, 3), reason: 'Invalid difficulty on ${q.id}');
    }
  });

  test('Correct-answer positions are balanced across options A, B, C, D (no option > 35%)', () {
    final all = [
      ...QuizQuestionBank.calculusQuestions,
      ...QuizQuestionBank.biologyQuestions,
      ...QuizQuestionBank.historyQuestions,
      ...QuizQuestionBank.physicsQuestions,
    ];

    expect(all.length, 100);

    final counts = [0, 0, 0, 0];
    for (final q in all) {
      expect(q.options.length, 4, reason: '${q.id} must have exactly 4 options');
      expect(q.correctOptionIndex, inInclusiveRange(0, 3));
      counts[q.correctOptionIndex]++;
    }

    // No single option holds more than 35% of the 100 questions (max 35)
    for (int i = 0; i < 4; i++) {
      final percentage = (counts[i] / all.length) * 100;
      expect(
        percentage,
        lessThanOrEqualTo(35.0),
        reason: 'Option index $i holds $percentage% (> 35%) of correct answers',
      );
    }
  });
}
