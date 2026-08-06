import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenHandler {
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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
    // Get current token
    final token = await _messaging.getToken();
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

  /// Saves the FCM token to Firestore under users/{uid}/fcmToken.
  /// Silent failure if no user is logged in.
  Future<void> _saveToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      // No user logged in, silently skip
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (e) {
      // Silent failure - log warning but don't crash
      // ignore: avoid_print
      print('[FcmTokenHandler] Failed to save FCM token: $e');
    }
  }

  /// Cancels the token refresh listener.
  void dispose() {
    _tokenSubscription?.cancel();
  }
}
