import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:study_nest/screens/profile/settings_screen.dart';
import 'package:study_nest/services/group_service.dart';
import 'package:study_nest/services/supabase_service.dart';

class MockSearchSupabaseClient implements SupabaseClient {
  final Map<String, List<Map<String, dynamic>>> tables;
  bool shouldFailUpdate;
  Map<String, dynamic>? lastUpdateData;
  String? lastUpdateId;

  MockSearchSupabaseClient({
    required this.tables,
    this.shouldFailUpdate = false,
  });

  @override
  SupabaseQueryBuilder from(String table) {
    return MockSearchTableBuilder(
      table: table,
      client: this,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSearchTableBuilder implements SupabaseQueryBuilder {
  final String table;
  final MockSearchSupabaseClient client;

  MockSearchTableBuilder({
    required this.table,
    required this.client,
  });

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String? columns]) {
    final list = List<Map<String, dynamic>>.from(client.tables[table] ?? []);
    return MockSearchFilterBuilder(
      data: list,
      client: client,
      isUpdate: false,
    );
  }

  @override
  PostgrestFilterBuilder update(dynamic values, {bool defaultToNull = true}) {
    client.lastUpdateData = Map<String, dynamic>.from(values as Map);
    return MockSearchFilterBuilder(
      data: client.tables[table] ?? [],
      client: client,
      isUpdate: true,
      updateValues: client.lastUpdateData,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSearchFilterBuilder
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;
  final MockSearchSupabaseClient client;
  final bool isUpdate;
  final Map<String, dynamic>? updateValues;

  MockSearchFilterBuilder({
    required this.data,
    required this.client,
    required this.isUpdate,
    this.updateValues,
  });

  Future<List<Map<String, dynamic>>> get _future {
    if (isUpdate && client.shouldFailUpdate) {
      return Future<List<Map<String, dynamic>>>.error(
        Exception('Simulated Supabase update failure'),
      );
    }
    return Future<List<Map<String, dynamic>>>.value(data);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    if (isUpdate) {
      if (column == 'id') {
        client.lastUpdateId = value.toString();
        // Update in-memory row
        for (final row in data) {
          if (row['id'] == value) {
            row.addAll(updateValues ?? {});
          }
        }
      }
      return this;
    }

    final filtered = data.where((row) => row[column] == value).toList();
    return MockSearchFilterBuilder(
      data: filtered,
      client: client,
      isUpdate: false,
    );
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> ilike(
    String column,
    String pattern,
  ) {
    final cleanPattern = pattern.replaceAll('%', '').toLowerCase();
    final filtered = data.where((row) {
      final val = (row[column] ?? '').toString().toLowerCase();
      return val.contains(cleanPattern);
    }).toList();
    return MockSearchFilterBuilder(
      data: filtered,
      client: client,
      isUpdate: false,
    );
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> limit(
    int count, {
    String? referencedTable,
  }) {
    final limited = data.take(count).toList();
    return MockSearchTransformBuilder(limited);
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return MockSingleTransformBuilder(data.isNotEmpty ? data.first : null);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<List<Map<String, dynamic>>> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<List<Map<String, dynamic>>> timeout(
    Duration timeLimit, {
    FutureOr<List<Map<String, dynamic>>> Function()? onTimeout,
  }) {
    return _future.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
    FutureOr<void> Function() action,
  ) {
    return _future.whenComplete(action);
  }

  @override
  Stream<List<Map<String, dynamic>>> asStream() => Stream.value(data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSearchTransformBuilder
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;

  MockSearchTransformBuilder(this.data);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return Future.value(data).then(onValue, onError: onError);
  }

  @override
  Future<List<Map<String, dynamic>>> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return Future.value(data).catchError(onError, test: test);
  }

  @override
  Future<List<Map<String, dynamic>>> timeout(
    Duration timeLimit, {
    FutureOr<List<Map<String, dynamic>>> Function()? onTimeout,
  }) {
    return Future.value(data).timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
    FutureOr<void> Function() action,
  ) {
    return Future.value(data).whenComplete(action);
  }

  @override
  Stream<List<Map<String, dynamic>>> asStream() => Stream.value(data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSingleTransformBuilder
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final Map<String, dynamic>? data;

  MockSingleTransformBuilder(this.data);

  Future<Map<String, dynamic>?> get _future =>
      Future<Map<String, dynamic>?>.value(data);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Map<String, dynamic>? value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<Map<String, dynamic>?> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<Map<String, dynamic>?> timeout(
    Duration timeLimit, {
    FutureOr<Map<String, dynamic>?> Function()? onTimeout,
  }) {
    return _future.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<Map<String, dynamic>?> whenComplete(
    FutureOr<void> Function() action,
  ) {
    return _future.whenComplete(action);
  }

  @override
  Stream<Map<String, dynamic>?> asStream() => Stream.value(data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testUserId = '00000000-0000-4000-8000-000000000001';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SupabaseService.instance.mockClient = null;
    SupabaseService.instance.mockCurrentUser = null;
    SupabaseService.instance.initializedForTesting = false;
  });

  tearDown(() {
    SupabaseService.instance.mockClient = null;
    SupabaseService.instance.mockCurrentUser = null;
    SupabaseService.instance.initializedForTesting = false;
  });

  group('Migration file verification', () {
    test('migration file exists and contains alter table with boolean not null default false', () {
      final migrationFile = File(
        'supabase/migrations/20261127000000_v2_stage7_hide_from_search.sql',
      );
      expect(migrationFile.existsSync(), isTrue,
          reason: 'Migration file 20261127000000_v2_stage7_hide_from_search.sql must exist');

      final content = migrationFile.readAsStringSync().toLowerCase();
      expect(content, contains('alter table public.profiles'));
      expect(content, contains('hidden_from_search'));
      expect(content, contains('boolean not null default false'));
    });
  });

  group('Search filter: searchUsers excludes hidden users', () {
    test('searchUsers includes users with hidden_from_search = false and excludes true', () async {
      final tables = <String, List<Map<String, dynamic>>>{
        'profiles': [
          {
            'id': 'user-visible-1',
            'display_name': 'Maya Santos',
            'subjects': ['Calculus'],
            'level': 'Level 5',
            'hidden_from_search': false,
          },
          {
            'id': 'user-hidden-2',
            'display_name': 'Maya Hidden',
            'subjects': ['Biology'],
            'level': 'Level 4',
            'hidden_from_search': true,
          },
        ],
      };

      SupabaseService.instance.mockClient = MockSearchSupabaseClient(tables: tables);
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      final results = await GroupService.searchUsers('Maya');

      expect(results.any((u) => u.name == 'Maya Santos'), isTrue,
          reason: 'Visible user with hidden_from_search = false must appear in results');
      expect(results.any((u) => u.name == 'Maya Hidden'), isFalse,
          reason: 'Hidden user with hidden_from_search = true must be excluded from results');
    });
  });

  group('Settings toggle: Hide me from search', () {
    testWidgets('guest user: toggle is disabled with guest explanation subtitle', (WidgetTester tester) async {
      SupabaseService.instance.mockCurrentUser = null;
      SupabaseService.instance.initializedForTesting = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('hide_from_search_switch'));
      expect(switchFinder, findsOneWidget);

      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.onChanged, isNull,
          reason: 'Switch must be disabled for guest users');
      expect(find.text('Available for signed-in accounts'), findsOneWidget);
    });

    testWidgets('signed-in user: tapping flips value and calls Supabase updateProfile', (WidgetTester tester) async {
      final tables = <String, List<Map<String, dynamic>>>{
        'profiles': [
          {
            'id': testUserId,
            'display_name': 'Alvin Legarbes',
            'subjects': ['Calculus'],
            'level': 'Level 5',
            'hidden_from_search': false,
          },
        ],
      };

      final client = MockSearchSupabaseClient(tables: tables);
      SupabaseService.instance.mockClient = client;
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('hide_from_search_switch'));
      expect(switchFinder, findsOneWidget);

      // Initial state is false
      var switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);

      // Tap switch to turn ON (hide me from search)
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify Supabase update was called with hidden_from_search: true
      expect(client.lastUpdateData, isNotNull);
      expect(client.lastUpdateData!['hidden_from_search'], isTrue);
      expect(client.lastUpdateId, equals(testUserId));

      // Switch is now true
      switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('signed-in user: failed update reverts toggle and shows error SnackBar', (WidgetTester tester) async {
      final tables = <String, List<Map<String, dynamic>>>{
        'profiles': [
          {
            'id': testUserId,
            'display_name': 'Alvin Legarbes',
            'subjects': ['Calculus'],
            'level': 'Level 5',
            'hidden_from_search': false,
          },
        ],
      };

      final client = MockSearchSupabaseClient(
        tables: tables,
        shouldFailUpdate: true, // Trigger update failure
      );
      SupabaseService.instance.mockClient = client;
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('hide_from_search_switch'));
      expect(switchFinder, findsOneWidget);

      var switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);

      // Tap to toggle
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Switch must be reverted to false
      switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse,
          reason: 'Switch must revert to previous value on failed update');

      // Error SnackBar displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Failed to update privacy setting'), findsOneWidget);
    });
  });
}
