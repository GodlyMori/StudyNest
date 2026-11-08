import 'package:flutter_test/flutter_test.dart';
import 'package:study_nest/main.dart';

void main() {
  testWidgets('StudyNest welcome screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyNestApp());
    expect(find.text('StudyNest'), findsOneWidget);
  });
}
