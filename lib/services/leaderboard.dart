import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Daily leaderboard at `leaderboards/{YYYY-MM-DD}/scores/{uid}`.
/// Score schema (must match firestore.rules from the Godot project):
///   guesses_used: int (1..8)
///   time_ms: int (>0)
///   solved: bool
///   submitted_at: server timestamp (TTL field — auto-expire 30 days)
class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int guessesUsed;
  final int timeMs;
  final bool solved;
  final DateTime submittedAt;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.guessesUsed,
    required this.timeMs,
    required this.solved,
    required this.submittedAt,
  });

  factory LeaderboardEntry.fromDoc(DocumentSnapshot d) {
    final data = d.data() as Map<String, dynamic>? ?? {};
    return LeaderboardEntry(
      uid: d.id,
      displayName:
          (data['display_name'] as String?) ?? 'Player ${d.id.substring(0, 4).toUpperCase()}',
      guessesUsed: (data['guesses_used'] as num?)?.toInt() ?? 99,
      timeMs: (data['time_ms'] as num?)?.toInt() ?? 0,
      solved: (data['solved'] as bool?) ?? false,
      submittedAt: (data['submitted_at'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }
}

class LeaderboardService {
  final _firestore = FirebaseFirestore.instance;

  /// Submit only if better than the existing score (improvement-only).
  /// Returns true if the submission landed.
  Future<bool> submitDaily({
    required String date, // YYYY-MM-DD
    required int guessesUsed,
    required int timeMs,
    required bool solved,
    String? displayName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final ref = _firestore
          .collection('leaderboards')
          .doc(date)
          .collection('scores')
          .doc(user.uid);
      final existing = await ref.get();
      if (existing.exists) {
        final prev = LeaderboardEntry.fromDoc(existing);
        // Better = solved && fewer guesses, or same guesses but faster.
        final isBetter = solved &&
            (!prev.solved ||
                guessesUsed < prev.guessesUsed ||
                (guessesUsed == prev.guessesUsed && timeMs < prev.timeMs));
        if (!isBetter) return false;
      }
      await ref.set({
        'guesses_used': guessesUsed,
        'time_ms': timeMs,
        'solved': solved,
        'submitted_at': FieldValue.serverTimestamp(),
        'display_name': ?displayName,
      });
      return true;
    } catch (e) {
      debugPrint('Leaderboard: submit failed: $e');
      return false;
    }
  }

  /// Top 10 entries for the given date, ordered by guesses_used ASC then time_ms ASC.
  Future<List<LeaderboardEntry>> top(String date) async {
    try {
      final snap = await _firestore
          .collection('leaderboards')
          .doc(date)
          .collection('scores')
          .where('solved', isEqualTo: true)
          .orderBy('guesses_used')
          .orderBy('time_ms')
          .limit(10)
          .get();
      return snap.docs.map(LeaderboardEntry.fromDoc).toList();
    } catch (e) {
      debugPrint('Leaderboard: top failed: $e');
      return [];
    }
  }

  /// Returns total players who submitted today, used for "Better than X%".
  Future<int> playerCount(String date) async {
    try {
      final snap = await _firestore
          .collection('leaderboards')
          .doc(date)
          .collection('scores')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

final leaderboardProvider =
    Provider<LeaderboardService>((_) => LeaderboardService());
