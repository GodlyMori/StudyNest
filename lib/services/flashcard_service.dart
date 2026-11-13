import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';
import '../ml/sm2_scheduler.dart';
import 'network_service.dart';
import 'supabase_service.dart';

class FlashcardService {
  FlashcardService._();

  static const String guestFlashcardsKey = 'guest_flashcards';
  static const String userFlashcardsPrefix = 'user_flashcards_';

  static String _storageKey([String? userId]) {
    final uid = userId ?? SupabaseService.instance.currentUser?.id;
    return uid == null ? guestFlashcardsKey : '$userFlashcardsPrefix$uid';
  }

  /// Loads all flashcards for the current user (or guest).
  static Future<List<Flashcard>> getAllFlashcards({String? userId}) async {
    final uid = userId ?? SupabaseService.instance.currentUser?.id;
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(uid);
    final raw = prefs.getString(key);

    var localCards = <Flashcard>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        localCards = decoded
            .map((item) => Flashcard.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error decoding local flashcards: $e');
      }
    }

    // Try syncing from Supabase if signed in and online
    if (uid != null &&
        SupabaseService.instance.isInitialized &&
        await NetworkService.isOnline()) {
      try {
        final response = await SupabaseService.instance.client
            .from('flashcards')
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false);

        final remoteCards = (response as List)
            .map((row) => Flashcard.fromSupabaseRow(Map<String, dynamic>.from(row as Map)))
            .toList();

        // Merge: remote wins on conflict or merge by id
        final map = {for (final c in localCards) c.id: c};
        for (final rc in remoteCards) {
          map[rc.id] = rc;
        }
        final merged = map.values.toList();
        await _saveLocally(merged, uid);
        return merged;
      } catch (e) {
        debugPrint('Flashcard remote load failed (using local cache): $e');
      }
    }

    return localCards;
  }

  /// Returns flashcards for a specific material.
  static Future<List<Flashcard>> getFlashcardsForMaterial(
    String materialId, {
    String? userId,
  }) async {
    final all = await getAllFlashcards(userId: userId);
    return all.where((c) => c.materialId == materialId).toList();
  }

  /// Returns all flashcards that are due for review.
  static Future<List<Flashcard>> getDueFlashcards({
    DateTime? now,
    String? userId,
  }) async {
    final all = await getAllFlashcards(userId: userId);
    return all.where((c) => c.isDue(now)).toList();
  }

  /// Saves one or more flashcards (insert or update).
  static Future<void> saveFlashcards(
    List<Flashcard> cards, {
    String? userId,
  }) async {
    if (cards.isEmpty) return;
    final uid = userId ?? SupabaseService.instance.currentUser?.id;
    final all = await getAllFlashcards(userId: uid);

    final cardMap = {for (final c in all) c.id: c};
    for (final card in cards) {
      cardMap[card.id] = card;
    }
    final updatedList = cardMap.values.toList();
    await _saveLocally(updatedList, uid);

    // Sync to Supabase
    if (uid != null &&
        SupabaseService.instance.isInitialized &&
        await NetworkService.isOnline()) {
      try {
        final rows = cards.map((c) => c.toSupabaseRow(uid)).toList();
        await SupabaseService.instance.client.from('flashcards').upsert(rows);
      } catch (e) {
        debugPrint('Flashcard remote upsert failed (cached locally): $e');
      }
    }
  }

  /// Records an SM-2 review for a specific flashcard.
  /// [quality]: 0 to 5 (SM-2 scale: 0-2 failure, 3-5 success).
  static Future<Flashcard?> recordReview({
    required String cardId,
    required int quality,
    DateTime? reviewedAt,
    String? userId,
  }) async {
    final uid = userId ?? SupabaseService.instance.currentUser?.id;
    final all = await getAllFlashcards(userId: uid);
    final index = all.indexWhere((c) => c.id == cardId);
    if (index == -1) return null;

    final current = all[index];
    final schedule = Sm2Scheduler.scheduleNext(
      ease: current.ease,
      intervalDays: current.intervalDays,
      repetitions: current.repetitions,
      quality: quality,
      reviewedAt: reviewedAt,
    );

    final updated = current.copyWith(
      ease: schedule.ease,
      intervalDays: schedule.intervalDays,
      repetitions: schedule.repetitions,
      nextReviewAt: schedule.nextReviewAt,
      updatedAt: (reviewedAt ?? DateTime.now()).toUtc(),
    );

    all[index] = updated;
    await _saveLocally(all, uid);

    if (uid != null &&
        SupabaseService.instance.isInitialized &&
        await NetworkService.isOnline()) {
      try {
        await SupabaseService.instance.client
            .from('flashcards')
            .upsert(updated.toSupabaseRow(uid));
      } catch (e) {
        debugPrint('Flashcard review sync failed: $e');
      }
    }

    return updated;
  }

  /// Deletes a flashcard by id.
  static Future<void> deleteFlashcard(String cardId, {String? userId}) async {
    final uid = userId ?? SupabaseService.instance.currentUser?.id;
    final all = await getAllFlashcards(userId: uid);
    all.removeWhere((c) => c.id == cardId);
    await _saveLocally(all, uid);

    if (uid != null &&
        SupabaseService.instance.isInitialized &&
        await NetworkService.isOnline()) {
      try {
        await SupabaseService.instance.client
            .from('flashcards')
            .delete()
            .eq('id', cardId)
            .eq('user_id', uid);
      } catch (e) {
        debugPrint('Flashcard delete failed remotely: $e');
      }
    }
  }

  static Future<void> _saveLocally(List<Flashcard> cards, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(userId);
    final raw = jsonEncode(cards.map((c) => c.toJson()).toList());
    await prefs.setString(key, raw);
  }

  /// Resets local flashcard storage (for testing).
  @visibleForTesting
  static Future<void> clearAll({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(userId));
  }
}
