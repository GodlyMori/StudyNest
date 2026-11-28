import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bug C: group_members RLS recursion fix migration verification', () {
    const migrationPath = 'supabase/migrations/20261128000000_v2_group_members_rls_recursion_fix.sql';

    test('Migration file exists', () {
      final file = File(migrationPath);
      expect(file.existsSync(), isTrue, reason: 'Migration file $migrationPath should exist');
    });

    test('Migration defines security definer helper functions', () {
      final content = File(migrationPath).readAsStringSync();

      expect(content.contains('create or replace function public.is_group_member(p_group_id uuid)'), isTrue);
      expect(content.contains('create or replace function public.is_group_member(p_group_id text)'), isTrue);
      expect(content.contains('create or replace function public.shares_group_with(p_other_user_id uuid)'), isTrue);
      expect(content.contains('security definer'), isTrue);
      expect(content.contains('set search_path = public'), isTrue);
    });

    test('group_members SELECT policy does not recursively query group_members directly', () {
      final content = File(migrationPath).readAsStringSync();

      // Find the policy creation block for group_members
      final policyStart = content.indexOf('create policy "Users can view group members"');
      expect(policyStart, isNonNegative);

      final nextPolicy = content.indexOf('create policy "Users can view public or joined groups"', policyStart);
      expect(nextPolicy, isNonNegative);

      final groupMembersPolicy = content.substring(policyStart, nextPolicy);

      // Must use is_group_member helper to avoid recursion
      expect(groupMembersPolicy.contains('public.is_group_member'), isTrue);

      // Must NOT contain direct recursive subquery on group_members
      expect(groupMembersPolicy.contains('select 1 from public.group_members'), isFalse);
      expect(groupMembersPolicy.contains('from public.group_members my_gm'), isFalse);
    });

    test('Audited group-scoped policies are safely updated', () {
      final content = File(migrationPath).readAsStringSync();

      // Audited tables
      expect(content.contains('on public.groups'), isTrue);
      expect(content.contains('on public.group_messages'), isTrue);
      expect(content.contains('on public.quiz_scores'), isTrue);
      expect(content.contains('on public.group_challenges'), isTrue);
      expect(content.contains('on public.challenge_attempts'), isTrue);
    });

    test('group_messages INSERT policy uses sender_id column', () {
      final content = File(migrationPath).readAsStringSync();

      final policyStart = content.indexOf('create policy "Group members can send messages"');
      expect(policyStart, isNonNegative);

      final nextPolicy = content.indexOf('drop policy if exists "Authenticated users can view quiz scores for leaderboards"', policyStart);
      expect(nextPolicy, isNonNegative);

      final insertPolicy = content.substring(policyStart, nextPolicy);

      expect(insertPolicy.contains('sender_id'), isTrue);
      expect(insertPolicy.contains('user_id = auth.uid()'), isFalse);
    });
  });
}
