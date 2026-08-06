import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/utils/retry_with_backoff.dart';

class FcmTokenHandler {
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _maxGetTokenAttempts = 3;
  static const _maxSaveAttempts = 3;

  StreamSubscription<String>? _tokenSubscription;

  FcmTokenHandler({
    required FirebaseMessaging messaging,
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _messaging = messaging,
        _auth = auth,
        _firestore = firestore;

  /// Initializes the FCM token handler.
  /// Gets the current token and listens for refreshes.
  Future<void> init() async {
    // Get current token with bounded retry
    final token = await _getTokenWithRetry();
    if (token != null) {
      await _saveToken(token);
    }

    // Listen for token refreshes.
    // Note: stream `onError` only captures errors emitted BY the stream, not
    // exceptions thrown by the data handler, so wrap the handler body itself.
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      (token) {
        _saveToken(token).catchError((e) {
          // ignore: avoid_print
          print('[FcmTokenHandler] token refresh save error: $e');
        });
      },
      onError: (Object e) {
        // ignore: avoid_print
        print('[FcmTokenHandler] onTokenRefresh stream error: $e');
      },
    );
  }

  /// Gets the FCM token with bounded retry and exponential backoff.
  Future<String?> _getTokenWithRetry() async {
    try {
      return await retryWithBackoff<String?>(
        () => _messaging.getToken(),
        maxAttempts: _maxGetTokenAttempts,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[FcmTokenHandler] Failed to get FCM token after $_maxGetTokenAttempts attempts: $e');
      return null;
    }
  }

  /// Saves the FCM token to Firestore under users/{uid}/fcmToken.
  /// Silent failure if no user is logged in.
  Future<void> _saveToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      // No user logged in, silently skip
      return;
    }

    try {
      await retryWithBackoff<void>(
        () => _firestore.collection('users').doc(user.uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        ),
        maxAttempts: _maxSaveAttempts,
      );
    } catch (e) {
      // Silent failure - log warning but don't crash
      // ignore: avoid_print
      print('[FcmTokenHandler] Failed to save FCM token after $_maxSaveAttempts attempts: $e');
    }
  }

  /// Cancels the token refresh listener.
  void dispose() {
    _tokenSubscription?.cancel();
  }
}
