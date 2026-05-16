import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class LabelMapRepository {
  String? translate(String enLabel);
  Future<void> loadMap();
}

class LabelMapRepositoryImpl implements LabelMapRepository {
  Map<String, String> _map = {};

  @override
  Future<void> loadMap() async {
    final jsonString = await rootBundle.loadString('assets/labels_es.json');
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    _map = decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  String? translate(String enLabel) {
    return _map[enLabel];
  }
}

final labelMapProvider = FutureProvider<LabelMapRepository>((ref) async {
  final repository = LabelMapRepositoryImpl();
  await repository.loadMap();
  return repository;
});
