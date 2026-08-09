import 'package:firebase_auth/firebase_auth.dart';

String get currentUserId {
  try {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  } catch (_) {
    return '';
  }
}
