import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:study_nest/services/group_service.dart';
import 'package:study_nest/services/supabase_service.dart';

class MockSupabaseClient implements SupabaseClient {
  final Map<String, List<Map<String, dynamic>>> tables;
  final Set<String> failingSelectTables;
  final Set<String> failingInsertTables;

  MockSupabaseClient({
    required this.tables,
    this.failingSelectTables = const {},
    this.failingInsertTables = const {},
  });

  @override
  SupabaseQueryBuilder from(String table) {
    return MockTableBuilder(
      table: table,
      tables: tables,
      failSelect: failingSelectTables.contains(table),
      failInsert: failingInsertTables.contains(table),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTableBuilder implements SupabaseQueryBuilder {
  final String table;
  final Map<String, List<Map<String, dynamic>>> tables;
  final bool failSelect;
  final bool failInsert;

  MockTableBuilder({
    required this.table,
    required this.tables,
    required this.failSelect,
    required this.failInsert,
  });

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String? columns]) {
    if (failSelect) {
      return MockFilterBuilder(null, shouldThrow: true);
    }
    return MockFilterBuilder(tables[table] ?? []);
  }

  @override
  PostgrestFilterBuilder insert(dynamic values, {bool defaultToNull = true}) {
    if (failInsert) {
      return MockFilterBuilder(null, shouldThrow: true);
    }
    final list = tables.putIfAbsent(table, () => []);
    if (values is List) {
      list.addAll(values.cast<Map<String, dynamic>>());
    } else if (values is Map) {
      list.add(Map<String, dynamic>.from(values));
    }
    return MockFilterBuilder([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFilterBuilder
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>>? data;
  final bool shouldThrow;

  MockFilterBuilder(this.data, {this.shouldThrow = false});

  Future<List<Map<String, dynamic>>> get _future => shouldThrow
      ? Future<List<Map<String, dynamic>>>.error(
          Exception('Simulated Supabase error'))
      : Future<List<Map<String, dynamic>>>.value(
          data ?? <Map<String, dynamic>>[]);

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = true,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    if (shouldThrow) {
      return MockTransformBuilder(null, shouldThrow: true);
    }
    return MockTransformBuilder(data ?? <Map<String, dynamic>>[]);
  }

  @override
  Stream<List<Map<String, dynamic>>> asStream() {
    if (shouldThrow) return Stream.error(Exception('Simulated Supabase error'));
    return Stream.value(data ?? <Map<String, dynamic>>[]);
  }

  @override
  Future<List<Map<String, dynamic>>> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTransformBuilder
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>>? data;
  final bool shouldThrow;

  MockTransformBuilder(this.data, {this.shouldThrow = false});

  Future<List<Map<String, dynamic>>> get _future => shouldThrow
      ? Future<List<Map<String, dynamic>>>.error(
          Exception('Simulated Supabase error'))
      : Future<List<Map<String, dynamic>>>.value(
          data ?? <Map<String, dynamic>>[]);

  @override
  Stream<List<Map<String, dynamic>>> asStream() {
    if (shouldThrow) return Stream.error(Exception('Simulated Supabase error'));
    return Stream.value(data ?? <Map<String, dynamic>>[]);
  }

  @override
  Future<List<Map<String, dynamic>>> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testUserId = '00000000-0000-4000-8000-000000000001';
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GroupService.resetToDefaults();
    SupabaseService.instance.mockClient = null;
    SupabaseService.instance.mockCurrentUser = null;
    SupabaseService.instance.initializedForTesting = false;
  });

  tearDown(() async {
    SupabaseService.instance.mockClient = null;
    SupabaseService.instance.mockCurrentUser = null;
    SupabaseService.instance.initializedForTesting = false;
  });

  group('Signed-in user - reads from Supabase source of truth', () {
    test('fetches groups from Supabase, derives memberCount and isJoined', () async {
      final tables = <String, List<Map<String, dynamic>>>{
        'groups': [
          {
            'id': '11111111-1111-4111-8111-111111111111',
            'name': 'Calculus Masters',
            'subject': 'Calculus',
            'description': 'Advanced calc prep',
            'created_by': testUserId,
            'is_public': true,
          },
          {
            'id': '22222222-2222-4222-8222-222222222222',
            'name': 'Bio Explorers',
            'subject': 'Biology',
            'description': 'Cell biology study',
            'created_by': 'another-user',
            'is_public': true,
          },
        ],
        'group_members': [
          {
            'group_id': '11111111-1111-4111-8111-111111111111',
            'user_id': testUserId,
            'role': 'admin',
          },
          {
            'group_id': '11111111-1111-4111-8111-111111111111',
            'user_id': 'peer-user-1',
            'role': 'member',
          },
          {
            'group_id': '22222222-2222-4222-8222-222222222222',
            'user_id': 'peer-user-2',
            'role': 'admin',
          },
        ],
      };

      SupabaseService.instance.mockClient = MockSupabaseClient(tables: tables);
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      final myGroups = await GroupService.getMyGroups();
      expect(myGroups.length, equals(1));
      expect(myGroups.first.name, equals('Calculus Masters'));
      expect(myGroups.first.isJoined, isTrue);
      expect(myGroups.first.memberCount, equals(2));

      final discoverGroups = await GroupService.getDiscoverGroups();
      expect(discoverGroups.length, equals(1));
      expect(discoverGroups.first.name, equals('Bio Explorers'));
      expect(discoverGroups.first.isJoined, isFalse);
      expect(discoverGroups.first.memberCount, equals(1));
    });

    test('fresh install with empty Supabase returns empty list (never seeds defaultGroups)', () async {
      final tables = <String, List<Map<String, dynamic>>>{
        'groups': [],
        'group_members': [],
      };

      SupabaseService.instance.mockClient = MockSupabaseClient(tables: tables);
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      final myGroups = await GroupService.getMyGroups();
      final discoverGroups = await GroupService.getDiscoverGroups();

      expect(myGroups, isEmpty);
      expect(discoverGroups, isEmpty);
    });

    test('falls back to offline cache on Supabase query error', () async {
      // 1. Initial successful sync
      final tables = <String, List<Map<String, dynamic>>>{
        'groups': [
          {
            'id': '11111111-1111-4111-8111-111111111111',
            'name': 'Physics Elite',
            'subject': 'Physics',
            'description': 'Mechanics prep',
            'created_by': testUserId,
            'is_public': true,
          },
        ],
        'group_members': [
          {
            'group_id': '11111111-1111-4111-8111-111111111111',
            'user_id': testUserId,
            'role': 'admin',
          },
        ],
      };

      SupabaseService.instance.mockClient = MockSupabaseClient(tables: tables);
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      final initial = await GroupService.getMyGroups();
      expect(initial.length, equals(1));

      // 2. Now simulate network failure
      SupabaseService.instance.mockClient = MockSupabaseClient(
        tables: tables,
        failingSelectTables: {'groups'},
      );

      final cached = await GroupService.getMyGroups();
      expect(cached.length, equals(1));
      expect(cached.first.name, equals('Physics Elite'));
    });

    test('fresh install with Supabase query error returns empty list', () async {
      SupabaseService.instance.mockClient = MockSupabaseClient(
        tables: {},
        failingSelectTables: {'groups'},
      );
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      final myGroups = await GroupService.getMyGroups();
      expect(myGroups, isEmpty);
    });
  });

  group('Signed-in user - writes to Supabase', () {
    test('createGroup inserts into Supabase groups and group_members first with UUID', () async {
      final tables = <String, List<Map<String, dynamic>>>{
        'groups': [],
        'group_members': [],
      };

      SupabaseService.instance.mockClient = MockSupabaseClient(tables: tables);
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      final group = await GroupService.createGroup(
        name: 'New Supabase Group',
        subject: 'Calculus',
        description: 'Testing UUID group creation',
      );

      expect(uuidRegex.hasMatch(group.id), isTrue,
          reason: 'Group ID must be a valid RFC-4122 v4 UUID');
      expect(group.isJoined, isTrue);
      expect(group.memberCount, equals(1));

      // Verify Supabase groups table row
      expect(tables['groups']!.length, equals(1));
      final groupRow = tables['groups']!.first;
      expect(groupRow['id'], equals(group.id));
      expect(groupRow['name'], equals('New Supabase Group'));
      expect(groupRow['subject'], equals('Calculus'));
      expect(groupRow['created_by'], equals(testUserId));

      // Verify Supabase group_members table row
      expect(tables['group_members']!.length, equals(1));
      final memberRow = tables['group_members']!.first;
      expect(memberRow['group_id'], equals(group.id));
      expect(memberRow['user_id'], equals(testUserId));
      expect(memberRow['role'], equals('admin'));

      // Verify local cache updated
      final myGroups = await GroupService.getMyGroups();
      expect(myGroups.length, equals(1));
      expect(myGroups.first.id, equals(group.id));
    });

    test('createGroup rethrows and does NOT modify cache when Supabase insert fails', () async {
      final tables = <String, List<Map<String, dynamic>>>{
        'groups': [],
        'group_members': [],
      };

      SupabaseService.instance.mockClient = MockSupabaseClient(
        tables: tables,
        failingInsertTables: {'groups'},
      );
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      expect(
        () => GroupService.createGroup(
          name: 'Failing Group',
          subject: 'Calculus',
          description: 'Should fail',
        ),
        throwsA(isA<Exception>()),
      );

      // Verify Supabase tables and local cache are empty
      expect(tables['groups'] ?? [], isEmpty);
      expect(tables['group_members'] ?? [], isEmpty);
    });

    test('joinGroup inserts into Supabase group_members first and updates cache', () async {
      const targetGroupId = '33333333-3333-4333-8333-333333333333';
      final tables = <String, List<Map<String, dynamic>>>{
        'groups': [
          {
            'id': targetGroupId,
            'name': 'Open Group',
            'subject': 'History',
            'description': 'History buffs',
            'created_by': 'other-user',
            'is_public': true,
          },
        ],
        'group_members': [
          {
            'group_id': targetGroupId,
            'user_id': 'other-user',
            'role': 'admin',
          },
        ],
      };

      SupabaseService.instance.mockClient = MockSupabaseClient(tables: tables);
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      // Discover group initially
      final discoverBefore = await GroupService.getDiscoverGroups();
      expect(discoverBefore.length, equals(1));
      expect(discoverBefore.first.isJoined, isFalse);
      expect(discoverBefore.first.memberCount, equals(1));

      // Join group
      await GroupService.joinGroup(targetGroupId);

      // Verify Supabase insert
      final newMembers = tables['group_members']!
          .where((m) => m['group_id'] == targetGroupId && m['user_id'] == testUserId)
          .toList();
      expect(newMembers.length, equals(1));
      expect(newMembers.first['role'], equals('member'));

      // Verify local cache updated
      final myGroupsAfter = await GroupService.getMyGroups();
      expect(myGroupsAfter.length, equals(1));
      expect(myGroupsAfter.first.isJoined, isTrue);
      expect(myGroupsAfter.first.memberCount, equals(2));
    });

    test('joinGroup rethrows and does NOT modify cache when Supabase insert fails', () async {
      const targetGroupId = '33333333-3333-4333-8333-333333333333';
      final tables = <String, List<Map<String, dynamic>>>{
        'groups': [
          {
            'id': targetGroupId,
            'name': 'Open Group',
            'subject': 'History',
            'description': 'History buffs',
            'created_by': 'other-user',
            'is_public': true,
          },
        ],
        'group_members': [],
      };

      SupabaseService.instance.mockClient = MockSupabaseClient(
        tables: tables,
        failingInsertTables: {'group_members'},
      );
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      // Populate cache first
      await GroupService.getDiscoverGroups();

      expect(
        () => GroupService.joinGroup(targetGroupId),
        throwsA(isA<Exception>()),
      );

      // Verify member is NOT joined in cache
      final discover = await GroupService.getDiscoverGroups();
      expect(discover.first.isJoined, isFalse);
    });

    test('inviteUser generates RFC-4122 v4 UUID for invite id', () async {
      final tables = <String, List<Map<String, dynamic>>>{
        'group_invites': [],
      };

      SupabaseService.instance.mockClient = MockSupabaseClient(tables: tables);
      SupabaseService.instance.mockCurrentUser = const User(
        id: testUserId,
        email: 'test@example.com',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-11-01',
      );
      SupabaseService.instance.initializedForTesting = true;

      await GroupService.inviteUser(
        groupId: '33333333-3333-4333-8333-333333333333',
        groupName: 'Calculus Masters',
        inviteeId: 'invitee-uuid-4444',
        inviteeName: 'Alex Peer',
      );

      expect(tables['group_invites']!.length, equals(1));
      final inviteRow = tables['group_invites']!.first;
      final inviteId = inviteRow['id'] as String;
      expect(uuidRegex.hasMatch(inviteId), isTrue,
          reason: 'Invite ID must be a valid RFC-4122 v4 UUID, not inv_<timestamp>');
    });
  });

  group('Guest user - local-only fallback', () {
    test('fresh install seeds defaultGroups to prefs and returns them', () async {
      SupabaseService.instance.mockCurrentUser = null;
      SupabaseService.instance.initializedForTesting = false;

      final myGroups = await GroupService.getMyGroups();
      expect(myGroups.length, equals(2)); // Calculus Crew & Bio Study Squad are default joined
      expect(myGroups.any((g) => g.id == 'group_calc_crew'), isTrue);

      final discover = await GroupService.getDiscoverGroups();
      expect(discover.length, equals(2)); // History Buffs & Physics Pioneers are default unjoined
    });

    test('createGroup creates group locally without touching Supabase', () async {
      SupabaseService.instance.mockCurrentUser = null;
      SupabaseService.instance.initializedForTesting = false;

      final group = await GroupService.createGroup(
        name: 'Guest Group',
        subject: 'Calculus',
        description: 'Local guest group',
      );

      expect(group.id, startsWith('group_'));
      expect(group.isJoined, isTrue);

      final myGroups = await GroupService.getMyGroups();
      expect(myGroups.any((g) => g.id == group.id), isTrue);
    });

    test('joinGroup updates local group without touching Supabase', () async {
      SupabaseService.instance.mockCurrentUser = null;
      SupabaseService.instance.initializedForTesting = false;

      await GroupService.joinGroup('group_history_buffs');

      final myGroups = await GroupService.getMyGroups();
      final historyBuffs = myGroups.firstWhere((g) => g.id == 'group_history_buffs');
      expect(historyBuffs.isJoined, isTrue);
      expect(historyBuffs.memberCount, equals(16)); // was 15, incremented to 16
    });
  });
}
