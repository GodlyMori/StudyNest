import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/screens/profile/delete_account_screen.dart';
import 'package:study_nest/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SupabaseService.instance.functionsInvoker = null;
    SupabaseService.instance.mockClient = null;
    SupabaseService.instance.mockCurrentUser = null;
    SupabaseService.instance.signOutHandler = null;
    SupabaseService.instance.initializedForTesting = false;
  });

  tearDown(() {
    SupabaseService.instance.functionsInvoker = null;
    SupabaseService.instance.mockClient = null;
    SupabaseService.instance.mockCurrentUser = null;
    SupabaseService.instance.signOutHandler = null;
    SupabaseService.instance.initializedForTesting = false;
  });

  group('Task 6.1: Delete Account Edge Function wiring', () {
    test('deleteAccount calls delete-account function with target userId and succeeds on 200', () async {
      SupabaseService.instance.initializedForTesting = true;

      String? invokedFunction;
      Map<String, dynamic>? invokedBody;
      bool signedOut = false;

      SupabaseService.instance.functionsInvoker = (functionName, {body}) async {
        invokedFunction = functionName;
        invokedBody = body;
        return FunctionResponse(
          data: {'message': 'User deleted successfully'},
          status: 200,
        );
      };
      SupabaseService.instance.signOutHandler = () async {
        signedOut = true;
      };

      await SupabaseService.instance.deleteAccount('test-user-uuid-1234');

      expect(invokedFunction, equals('delete-account'));
      expect(invokedBody, equals({'userId': 'test-user-uuid-1234'}));
      expect(signedOut, isTrue);
    });

    test('deleteAccount throws Exception and does not pretend success when function returns non-200', () async {
      SupabaseService.instance.initializedForTesting = true;
      bool signedOut = false;

      SupabaseService.instance.functionsInvoker = (functionName, {body}) async {
        return FunctionResponse(
          data: {'error': 'Failed to delete user in auth.users'},
          status: 500,
        );
      };
      SupabaseService.instance.signOutHandler = () async {
        signedOut = true;
      };

      expect(
        () => SupabaseService.instance.deleteAccount('test-user-uuid-1234'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to delete user identity in auth.users'),
        )),
      );
      expect(signedOut, isFalse);
    });

    test('deleteAccount propagates error when functions client throws', () async {
      SupabaseService.instance.initializedForTesting = true;
      bool signedOut = false;

      SupabaseService.instance.functionsInvoker = (functionName, {body}) async {
        throw const FunctionException(
          status: 500,
          details: 'Internal Server Error',
          reasonPhrase: 'Error',
        );
      };
      SupabaseService.instance.signOutHandler = () async {
        signedOut = true;
      };

      expect(
        () => SupabaseService.instance.deleteAccount('test-user-uuid-1234'),
        throwsA(isA<FunctionException>()),
      );
      expect(signedOut, isFalse);
    });

    testWidgets('DeleteAccountScreen retains data and shows error SnackBar if deleteAccount throws', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', 'Student Test');
      await prefs.setString('offline_notes', 'Important content');

      SupabaseService.instance.initializedForTesting = true;
      SupabaseService.instance.mockCurrentUser = const User(
        id: 'mock-user-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-26T00:00:00Z',
      );

      SupabaseService.instance.functionsInvoker = (functionName, {body}) async {
        return FunctionResponse(
          data: {'error': 'Service role deletion failed'},
          status: 500,
        );
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: DeleteAccountScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.widgetWithText(ElevatedButton, 'Permanently Delete Account');
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Deletion failed: user stays on DeleteAccountScreen
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
      // Local preferences NOT wiped
      expect(prefs.getString('user_name'), equals('Student Test'));
      expect(prefs.getString('offline_notes'), equals('Important content'));
      // Error SnackBar displayed
      expect(find.textContaining('Failed to delete account:'), findsOneWidget);
    });
  });
}
