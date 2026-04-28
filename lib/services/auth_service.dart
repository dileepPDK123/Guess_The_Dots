import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Firebase auth + cloud-save bridge.
///
/// Strategy: anonymous on first launch; Google/Apple sign-in *links* to the
/// existing anon UID so progress is preserved (matches the design handoff
/// + decisions.md from the Godot project).
///
/// All methods are silent — they never crash the app on failure. Errors
/// surface as null returns or `false` flags.
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Stream<User?> get userChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> ensureAnonymous() async {
    if (_auth.currentUser != null) return _auth.currentUser;
    try {
      final cred = await _auth.signInAnonymously();
      return cred.user;
    } catch (e) {
      debugPrint('Auth: ensureAnonymous failed: $e');
      return null;
    }
  }

  Future<bool> linkWithGoogle() async {
    try {
      final google = GoogleSignIn.instance;
      await google.initialize();
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return false;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final user = _auth.currentUser;
      if (user == null) {
        await _auth.signInWithCredential(credential);
      } else {
        await user.linkWithCredential(credential);
      }
      return true;
    } catch (e) {
      debugPrint('Auth: linkWithGoogle failed: $e');
      return false;
    }
  }

  Future<bool> linkWithApple() async {
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauth = OAuthProvider('apple.com').credential(
        idToken: cred.identityToken,
        accessToken: cred.authorizationCode,
      );
      final user = _auth.currentUser;
      if (user == null) {
        await _auth.signInWithCredential(oauth);
      } else {
        await user.linkWithCredential(oauth);
      }
      return true;
    } catch (e) {
      debugPrint('Auth: linkWithApple failed: $e');
      return false;
    }
  }

  /// GDPR delete: 1) anonymise last 30 days of leaderboard scores,
  /// 2) delete the user save doc, 3) delete the auth user.
  Future<bool> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return true;
    try {
      // 1) anonymise leaderboard scores
      final now = DateTime.now().toUtc();
      for (var i = 0; i < 30; i++) {
        final d = now.subtract(Duration(days: i));
        final dateStr =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        try {
          await _firestore
              .collection('leaderboards')
              .doc(dateStr)
              .collection('scores')
              .doc(user.uid)
              .delete();
        } catch (_) {}
      }
      // 2) delete cloud save
      try {
        await _firestore.collection('users').doc(user.uid).delete();
      } catch (_) {}
      // 3) delete auth user
      await user.delete();
      return true;
    } catch (e) {
      debugPrint('Auth: deleteAccount failed: $e');
      return false;
    }
  }
}

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final currentUserProvider = StreamProvider<User?>(
  (ref) => ref.read(authServiceProvider).userChanges,
);
