import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/data/study_materials.dart';
import 'package:study_nest/ml/flashcard_parser.dart';
import 'package:study_nest/ml/sm2_scheduler.dart';
import 'package:study_nest/models/flashcard.dart';
import 'package:study_nest/screens/materials/make_flashcards_screen.dart';
import 'package:study_nest/screens/materials/material_detail_screen.dart';
import 'package:study_nest/screens/planner/planner_screen.dart';
import 'package:study_nest/services/flashcard_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FlashcardParser (Pure Dart)', () {
    test('parses semicolon & colon separated timeline facts', () {
      const content =
          '1939: Outbreak of war with Poland invasion; 1941: Pearl Harbor; 1944: D-Day Normandy landings; 1945: Victory in Europe and Pacific.';
      final cards = FlashcardParser.parse(content, title: 'WW2 Timeline');

      expect(cards.length, greaterThanOrEqualTo(3));
      expect(cards.any((c) => c.front.contains('1939') && c.back.contains('Poland')), isTrue);
      expect(cards.any((c) => c.front.contains('1941') && c.back.contains('Pearl Harbor')), isTrue);
    });

    test('parses parenthesized terms and definitions', () {
      const content =
          'Eukaryotic cells contain membrane-bound organelles: Nucleus (houses DNA), Mitochondria (ATP production), Ribosomes (protein synthesis).';
      final cards = FlashcardParser.parse(content, title: 'Cell Structure');

      expect(cards.length, greaterThanOrEqualTo(3));
      expect(cards.any((c) => c.front == 'Nucleus' && c.back == 'houses DNA'), isTrue);
      expect(cards.any((c) => c.front == 'Mitochondria' && c.back == 'ATP production'), isTrue);
      expect(cards.any((c) => c.front == 'Ribosomes' && c.back == 'protein synthesis'), isTrue);
    });

    test('parses mathematical formulas and rules', () {
      const content =
          "Key formulas: d/dx(c) = 0, Product rule: (uv)' = u'v + uv', Quotient rule: (u/v)' = (u'v - uv')/v².";
      final cards = FlashcardParser.parse(content, title: 'Derivatives');

      expect(cards.isNotEmpty, isTrue);
      expect(cards.any((c) => c.front.contains('Product rule')), isTrue);
    });

    test('fallback generates candidate cards from plain sentences', () {
      const content =
          'Integration formulas for trigonometric, exponential, and polynomial functions.';
      final cards = FlashcardParser.parse(content, title: 'Calculus Integrals');

      expect(cards.length, 1);
      expect(cards.first.front, 'Calculus Integrals');
      expect(cards.first.back, content);
    });
  });

  group('FlashcardService & SM-2 Scheduling', () {
    test('saves flashcards and retrieves them locally', () async {
      await FlashcardService.clearAll();
      final now = DateTime.utc(2026, 11, 13, 10, 0);
      final card = Flashcard(
        id: 'test_card_1',
        materialId: 'mat_cell_structure',
        front: 'Nucleus',
        back: 'houses DNA',
        createdAt: now,
        updatedAt: now,
        nextReviewAt: now,
      );

      await FlashcardService.saveFlashcards([card]);
      final retrieved = await FlashcardService.getFlashcardsForMaterial('mat_cell_structure');
      expect(retrieved.length, 1);
      expect(retrieved.first.front, 'Nucleus');
      expect(retrieved.first.isDue(now), isTrue);
    });

    test('recordReview updates SM-2 schedule', () async {
      await FlashcardService.clearAll();
      final now = DateTime.utc(2026, 11, 13, 10, 0);
      final card = Flashcard(
        id: 'sm2_card_1',
        materialId: 'mat_ww2_timeline',
        front: '1939',
        back: 'Poland invasion',
        ease: Sm2Scheduler.initialEase,
        intervalDays: 0,
        repetitions: 0,
        createdAt: now,
        updatedAt: now,
        nextReviewAt: now,
      );

      await FlashcardService.saveFlashcards([card]);

      // Grade 4 review
      final updated = await FlashcardService.recordReview(
        cardId: 'sm2_card_1',
        quality: 4,
        reviewedAt: now,
      );

      expect(updated, isNotNull);
      expect(updated!.repetitions, 1);
      expect(updated.intervalDays, Sm2Scheduler.firstIntervalDays);
      expect(updated.nextReviewAt, now.add(const Duration(days: 1)));
      expect(updated.isDue(now), isFalse);
    });
  });

  group('Flashcard UI Tests', () {
    testWidgets('MaterialDetailScreen renders Make Flashcards action', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final material = StudyMaterialBank.defaultMaterials.first;
      await tester.pumpWidget(
        MaterialApp(
          home: MaterialDetailScreen(material: material),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('make_flashcards_button')), findsOneWidget);
      expect(find.text('Make Flashcards'), findsOneWidget);
    });

    testWidgets('MakeFlashcardsScreen displays candidate cards and allows saving', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await FlashcardService.clearAll();
      final material = StudyMaterialBank.getById('mat_cell_structure')!;

      await tester.pumpWidget(
        MaterialApp(
          home: MakeFlashcardsScreen(material: material),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Make Flashcards'), findsOneWidget);
      expect(find.byKey(const Key('save_flashcards_button')), findsOneWidget);

      // Verify candidate cards were populated
      expect(find.text('Nucleus'), findsOneWidget);
      expect(find.text('houses DNA'), findsOneWidget);

      // Tap Save
      await tester.tap(find.byKey(const Key('save_flashcards_button')));
      await tester.pumpAndSettle();

      // Check saved
      final saved = await FlashcardService.getFlashcardsForMaterial('mat_cell_structure');
      expect(saved.isNotEmpty, isTrue);
    });

    testWidgets('PlannerScreen displays due flashcards in Reviews Due section', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await FlashcardService.clearAll();
      final now = DateTime.now().toUtc();
      final dueCard = Flashcard(
        id: 'due_card_test',
        materialId: 'mat_cell_structure',
        front: 'Mitochondria',
        back: 'ATP production',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        nextReviewAt: now.subtract(const Duration(hours: 1)),
      );
      await FlashcardService.saveFlashcards([dueCard]);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlannerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reviews due'), findsOneWidget);
      expect(find.byKey(const Key('due_flashcards_card')), findsOneWidget);
      expect(find.text('Flashcards (1 due)'), findsOneWidget);
    });
  });
}
