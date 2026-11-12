import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/ml/attempt_logger.dart';
import 'package:study_nest/screens/quiz/quiz_screen.dart';
import 'package:study_nest/services/attempt_sync_service.dart';

class _FakeRemoteSink implements AttemptRemoteSink {
  @override
  bool isReady;

  bool shouldThrow = false;
  final List<List<Map<String, dynamic>>> uploadedBatches = [];
  final Set<String> serverDedupeIds = {};
  final List<Map<String, dynamic>> serverRows = [];

  _FakeRemoteSink({this.isReady = true});

  @override
  Future<void> upsertAttempts(List<Map<String, dynamic>> rows) async {
    if (shouldThrow) {
      throw Exception('Simulated network error');
    }
    uploadedBatches.add(rows);
    for (final row in rows) {
      final id = row['id'] as String;
      if (serverDedupeIds.add(id)) {
        serverRows.add(row);
      }
    }
  }
}

void main() {
  group('AttemptLogger (V2 Stage 1.1)', () {
    test('logging an answered question produces a valid QuestionAttempt record', () async {
      final storage = InMemoryAttemptStorage();
      final remote = _FakeRemoteSink(isReady: true);
      var seq = 0;
      final fixedTime = DateTime.utc(2026, 11, 12, 12, 0, 0);

      final logger = AttemptLogger(
        storage: storage,
        remoteSink: remote,
        isOnline: () async => true,
        getCurrentUserId: () => 'user-abc',
        clock: () => fixedTime,
        idGenerator: () => 'attempt-${++seq}',
      );

      final attempt = await logger.logAttempt(
        questionId: 'calc_1',
        subject: 'Calculus',
        topic: 'Derivatives',
        correct: true,
        timeTakenMs: 4250,
        hintUsed: false,
      );

      expect(attempt.id, 'attempt-1');
      expect(attempt.userId, 'user-abc');
      expect(attempt.questionId, 'calc_1');
      expect(attempt.subject, 'Calculus');
      expect(attempt.topic, 'Derivatives');
      expect(attempt.correct, isTrue);
      expect(attempt.timeTakenMs, 4250);
      expect(attempt.hintUsed, isFalse);
      expect(attempt.answeredAt, fixedTime);

      expect(remote.serverRows.length, 1);
      expect(remote.serverRows.first['question_id'], 'calc_1');
      expect(remote.serverRows.first['time_taken_ms'], 4250);
      expect(remote.serverRows.first['hint_used'], isFalse);
      expect(await logger.getPendingOutbox(), isEmpty);
    });

    test('guest attempts are stored locally and migrated on registration', () async {
      final storage = InMemoryAttemptStorage();
      final remote = _FakeRemoteSink(isReady: true);
      var seq = 0;
      var tick = 0;

      final logger = AttemptLogger(
        storage: storage,
        remoteSink: remote,
        isOnline: () async => true,
        getCurrentUserId: () => null,
        clock: () => DateTime.utc(2026, 11, 12, 12, 0, ++tick),
        idGenerator: () => 'guest-attempt-${++seq}',
      );

      await logger.logAttempt(
        questionId: 'bio_1',
        subject: 'Biology',
        topic: 'Cell Structure',
        correct: true,
        timeTakenMs: 3100,
        hintUsed: false,
      );
      await logger.logAttempt(
        questionId: 'bio_2',
        subject: 'Biology',
        topic: 'Genetics',
        correct: false,
        timeTakenMs: 7800,
        hintUsed: true,
      );

      expect((await logger.getAttempts(userId: null)).length, 2);
      expect(remote.serverRows, isEmpty);

      final migratedCount = await logger.migrateGuestAttempts('new-user-99');
      expect(migratedCount, 2);
      expect(await logger.getAttempts(userId: null), isEmpty);

      final userAttempts = await logger.getAttempts(userId: 'new-user-99');
      expect(userAttempts.length, 2);
      expect(userAttempts[0].userId, 'new-user-99');
      expect(userAttempts[1].hintUsed, isTrue);

      expect(remote.serverRows.length, 2);
      expect(remote.serverRows[0]['user_id'], 'new-user-99');
      expect(remote.serverRows[0]['question_id'], 'bio_1');
      expect(remote.serverRows[1]['question_id'], 'bio_2');
      expect(await logger.getPendingOutbox(), isEmpty);
    });

    test('offline attempts queue in chronological order and sync without duplicates on retry', () async {
      final storage = InMemoryAttemptStorage();
      final remote = _FakeRemoteSink(isReady: true);
      var online = false;
      var seq = 0;
      var tick = 10;

      final logger = AttemptLogger(
        storage: storage,
        remoteSink: remote,
        isOnline: () async => online,
        getCurrentUserId: () => 'user-offline',
        clock: () => DateTime.utc(2026, 11, 12, 12, 0, tick += 5),
        idGenerator: () => 'offline-${++seq}',
        batchSize: 2,
      );

      await logger.logAttempt(
        questionId: 'phys_1',
        subject: 'Physics',
        topic: 'Mechanics',
        correct: true,
        timeTakenMs: 1200,
        hintUsed: false,
      );
      await logger.logAttempt(
        questionId: 'phys_2',
        subject: 'Physics',
        topic: 'Electromagnetism',
        correct: false,
        timeTakenMs: 5400,
        hintUsed: true,
      );
      await logger.logAttempt(
        questionId: 'phys_3',
        subject: 'Physics',
        topic: 'Mechanics',
        correct: true,
        timeTakenMs: 2100,
        hintUsed: false,
      );

      expect((await logger.getPendingOutbox()).length, 3);
      expect(remote.serverRows, isEmpty);

      // Reconnect, but fail first attempt to verify outbox preserves items
      online = true;
      remote.shouldThrow = true;
      final failedSyncCount = await logger.syncOutbox();
      expect(failedSyncCount, 0);
      expect((await logger.getPendingOutbox()).length, 3);

      // Succeed on retry
      remote.shouldThrow = false;
      final syncedCount = await logger.syncOutbox();
      expect(syncedCount, 3);
      expect(await logger.getPendingOutbox(), isEmpty);
      expect(remote.serverRows.map((r) => r['question_id']).toList(), [
        'phys_1',
        'phys_2',
        'phys_3',
      ]);

      // Calling syncOutbox again is a no-op with zero duplicates
      final repeatSync = await logger.syncOutbox();
      expect(repeatSync, 0);
      expect(remote.serverRows.length, 3);
    });

    testWidgets('QuizScreen logs attempt with hintUsed when Ask Owl for a Hint is tapped', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: QuizScreen(subject: 'Calculus'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Ask Owl for a Hint" on question 1 (calc_1)
      await tester.ensureVisible(find.text('Ask Owl for a Hint'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ask Owl for a Hint'));
      await tester.pumpAndSettle();
      expect(find.text("Owl's Hint"), findsOneWidget);

      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();

      // Answer question 1 correctly ('2x')
      await tester.ensureVisible(find.text('2x'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2x'));
      await tester.pumpAndSettle();

      final attempts = await AttemptSyncService.logger.getAttempts(userId: null);
      expect(attempts.length, 1);
      expect(attempts.first.questionId, 'calc_1');
      expect(attempts.first.subject, 'Calculus');
      expect(attempts.first.topic, 'Derivatives');
      expect(attempts.first.correct, isTrue);
      expect(attempts.first.hintUsed, isTrue);
      expect(attempts.first.timeTakenMs, greaterThanOrEqualTo(0));
    });
  });
}
