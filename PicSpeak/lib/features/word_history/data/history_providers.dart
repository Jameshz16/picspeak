import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  throw UnimplementedError(
    'Override this provider with an initialized HistoryRepository',
  );
});

final historyListProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.loadAll();
});
