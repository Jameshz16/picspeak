import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GalleryItem {
  final String id;
  final String enLabel;
  final String esLabel;
  final String category;
  final String? imageUrl;
  final DateTime scannedAt;
  final int reviewCount;

  GalleryItem({
    required this.id,
    required this.enLabel,
    required this.esLabel,
    required this.category,
    this.imageUrl,
    required this.scannedAt,
    this.reviewCount = 0,
  });

  factory GalleryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryItem(
      id: doc.id,
      enLabel: data['enLabel'] ?? '',
      esLabel: data['esLabel'] ?? '',
      category: data['category'] ?? 'objects',
      imageUrl: data['imageUrl'],
      scannedAt: (data['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }
}

class GalleryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GalleryRepository(this._firestore, this._auth);

  Stream<List<GalleryItem>> getGalleryItems() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('scanned_objects')
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GalleryItem.fromFirestore(doc))
            .toList());
  }

  Stream<List<GalleryItem>> getGalleryByCategory(String category) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('scanned_objects')
        .where('category', isEqualTo: category)
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GalleryItem.fromFirestore(doc))
            .toList());
  }
}

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final galleryItemsProvider = StreamProvider<List<GalleryItem>>((ref) {
  return ref.watch(galleryRepositoryProvider).getGalleryItems();
});
