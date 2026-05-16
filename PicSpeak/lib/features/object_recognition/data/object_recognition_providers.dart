import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/mlkit_repository.dart';
import 'mlkit_repository_impl.dart';

final mlKitRepositoryProvider = Provider<MlKitRepository>((ref) {
  final repo = MlKitRepositoryImpl();
  ref.onDispose(() => repo.dispose());
  return repo;
});
