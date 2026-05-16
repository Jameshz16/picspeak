import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/flashcard_repository.dart';

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  throw UnimplementedError(
    'Override this provider with an initialized FlashcardRepository',
  );
});
