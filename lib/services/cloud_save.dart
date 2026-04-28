import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_state.dart';

/// Cloud save: mirrors the local PlayerState to Firestore at users/{uid}/save.
///
/// Conflict rule (matches the Godot decision): on launch, whichever side has
/// the higher [PlayerState.totalXpEarned] wins entirely. No field-by-field
/// merge — total_xp_earned is monotonically increasing and the best single
/// proxy for "which device has the most real progress."
///
/// Push is rate-limited to 1 write per 10 seconds.
class CloudSaveService {
  CloudSaveService(this._ref);
  final Ref _ref;
  final _firestore = FirebaseFirestore.instance;
  DateTime? _lastPushAt;
  bool _pendingPush = false;
  Timer? _pendingTimer;

  /// Pull on app launch — call after auth ensures a UID is present.
  /// If cloud has higher total_xp_earned, hydrate local. Otherwise leave local.
  Future<void> pull() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      final cloudXp = (data['totalXpEarned'] as num?)?.toInt() ?? 0;
      final local = _ref.read(playerProvider);
      if (cloudXp > local.totalXpEarned) {
        try {
          final hydrated = PlayerState.fromJson(Map<String, dynamic>.from(data));
          _ref.read(playerProvider.notifier).hydrate(hydrated);
        } catch (e) {
          debugPrint('CloudSave: hydrate failed: $e');
        }
      }
    } catch (e) {
      debugPrint('CloudSave: pull failed: $e');
    }
  }

  /// Push the local PlayerState to Firestore. Rate-limited to 10s; if a push
  /// is requested during the cooldown, [_pendingPush] is set so the next
  /// allowed write happens.
  Future<void> push() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    if (_lastPushAt != null &&
        now.difference(_lastPushAt!) < const Duration(seconds: 10)) {
      _pendingPush = true;
      // Cancel any existing timer to prevent multiple concurrent retries.
      _pendingTimer?.cancel();
      _pendingTimer = Timer(const Duration(seconds: 10), () {
        if (_pendingPush) {
          _pendingPush = false;
          push();
        }
      });
      return;
    }
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _lastPushAt = now;
    try {
      final state = _ref.read(playerProvider);
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(state.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSave: push failed: $e');
    }
  }
}

final cloudSaveProvider = Provider<CloudSaveService>(CloudSaveService.new);
