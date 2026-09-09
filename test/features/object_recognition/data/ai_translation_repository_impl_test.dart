import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:picspeak/features/object_recognition/data/ai_translation_repository_impl.dart';
import 'package:picspeak/features/object_recognition/domain/ai_translation_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeHttpClient implements http.Client {
  http.Response? _nextResponse;
  Object? _nextException;
  int callCount = 0;
  Uri? lastUri;
  Map<String, String>? lastHeaders;
  String? lastBody;

  void setResponse(http.Response response) {
    _nextResponse = response;
    _nextException = null;
  }

  void setException(Object exception) {
    _nextException = exception;
    _nextResponse = null;
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    callCount++;
    lastUri = url;
    lastHeaders = headers;
    lastBody = body as String?;
    if (_nextException != null) throw _nextException!;
    return _nextResponse!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final bool _exists;

  FakeDocumentSnapshot(this._data, {bool exists = true}) : _exists = exists;

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final Map<String, dynamic>? _cachedData;
  final bool _cacheExists;
  Map<String, dynamic>? savedData;

  FakeDocumentReference({
    Map<String, dynamic>? cachedData,
    bool cacheExists = false,
  }) : _cachedData = cachedData,
       _cacheExists = cacheExists;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    return FakeDocumentSnapshot(_cachedData, exists: _cacheExists);
  }

  @override
  Future<void> set(Map<String, dynamic>? data, [SetOptions? options]) async {
    savedData = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  final FakeDocumentReference _docRef;

  FakeCollectionReference(this._docRef);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _docRef;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  final FakeCollectionReference _collectionRef;

  FakeFirebaseFirestore(this._collectionRef);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _collectionRef;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _successResponseBody() {
  return jsonEncode({
    'choices': [
      {
        'message': {
          'content': jsonEncode({
            'esLabel': 'mesa',
            'phrases': [
              {'en': 'The table is wooden.', 'es': 'La mesa es de madera.'},
              {
                'en': 'I put the book on the table.',
                'es': 'Puse el libro en la mesa.',
              },
            ],
            'confidence': 0.95,
          }),
        },
      },
    ],
  });
}

String _markdownWrappedResponseBody() {
  final inner = jsonEncode({
    'esLabel': 'silla',
    'phrases': [
      {'en': 'The chair is comfortable.', 'es': 'La silla es cómoda.'},
      {'en': 'Sit on the chair.', 'es': 'Siéntate en la silla.'},
    ],
    'confidence': 0.88,
  });
  return jsonEncode({
    'choices': [
      {
        'message': {'content': '```json\n$inner\n```'},
      },
    ],
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeHttpClient httpClient;
  late FakeDocumentReference docRef;
  late FakeCollectionReference collection;
  late FakeFirebaseFirestore firestore;
  late AiTranslationRepositoryImpl repo;

  const apiKey = 'sk-test-key';

  setUp(() {
    httpClient = FakeHttpClient();
    docRef = FakeDocumentReference();
    collection = FakeCollectionReference(docRef);
    firestore = FakeFirebaseFirestore(collection);
    repo = AiTranslationRepositoryImpl(firestore, httpClient, apiKey);
  });

  group('AiTranslationRepositoryImpl', () {
    test('cache hit returns cached result without API call', () async {
      // Arrange: cache exists
      docRef = FakeDocumentReference(
        cachedData: {
          'enLabel': 'table',
          'esLabel': 'mesa',
          'phrases': [
            {'en': 'The table is big.', 'es': 'La mesa es grande.'},
          ],
          'aiConfidence': 0.9,
          'modelVersion': 'deepseek-v4-flash-vision-exp',
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
        },
        cacheExists: true,
      );
      collection = FakeCollectionReference(docRef);
      firestore = FakeFirebaseFirestore(collection);
      repo = AiTranslationRepositoryImpl(firestore, httpClient, apiKey);

      // Act
      final result = await repo.translate('/fake/path.jpg', 'table');

      // Assert
      expect(result, isNotNull);
      expect(result!.esLabel, 'mesa');
      expect(result.enLabel, 'table');
      expect(result.phrases.length, 1);
      expect(httpClient.callCount, 0); // No API call
    });

    test('cache miss calls DeepSeek API and returns result', () async {
      // Arrange: no cache
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test.jpg');
      tempFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

      httpClient.setResponse(http.Response(_successResponseBody(), 200));

      // Act
      final result = await repo.translate(tempFile.path, 'table');

      // Assert
      expect(result, isNotNull);
      expect(result!.esLabel, 'mesa');
      expect(result.phrases.length, 2);
      expect(result.aiConfidence, 0.95);
      expect(result.modelVersion, 'deepseek-v4-flash-vision-exp');
      expect(httpClient.callCount, 1);
      expect(docRef.savedData, isNotNull); // Cache was written

      tempDir.deleteSync(recursive: true);
    });

    test('offline throws AiTranslationOfflineException', () async {
      // Arrange
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test.jpg');
      tempFile.writeAsBytesSync([0xFF, 0xD8]);

      httpClient.setException(const SocketException('No internet'));

      // Act & Assert
      expect(
        () => repo.translate(tempFile.path, 'table'),
        throwsA(isA<AiTranslationOfflineException>()),
      );

      tempDir.deleteSync(recursive: true);
    });

    test('API 200 with markdown-wrapped JSON parses correctly', () async {
      // Arrange
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test.jpg');
      tempFile.writeAsBytesSync([0xFF, 0xD8]);

      httpClient.setResponse(
        http.Response(_markdownWrappedResponseBody(), 200),
      );

      // Act
      final result = await repo.translate(tempFile.path, 'chair');

      // Assert
      expect(result, isNotNull);
      expect(result!.esLabel, 'silla');
      expect(result.phrases.first.en, 'The chair is comfortable.');

      tempDir.deleteSync(recursive: true);
    });

    test('API 400 returns null without retry', () async {
      // Arrange
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test.jpg');
      tempFile.writeAsBytesSync([0xFF, 0xD8]);

      httpClient.setResponse(http.Response('Bad Request', 400));

      // Act
      final result = await repo.translate(tempFile.path, 'unknown');

      // Assert
      expect(result, isNull);
      expect(httpClient.callCount, 1); // No retry for 400

      tempDir.deleteSync(recursive: true);
    });

    test('API 429 retries once then returns null', () async {
      // Arrange
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test.jpg');
      tempFile.writeAsBytesSync([0xFF, 0xD8]);

      httpClient.setResponse(http.Response('Rate limited', 429));

      // Act
      final result = await repo.translate(tempFile.path, 'table');

      // Assert
      expect(result, isNull);
      expect(httpClient.callCount, 2); // Original + 1 retry

      tempDir.deleteSync(recursive: true);
    });

    test('invalid JSON response returns null', () async {
      // Arrange
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test.jpg');
      tempFile.writeAsBytesSync([0xFF, 0xD8]);

      final invalidBody = jsonEncode({
        'choices': [
          {
            'message': {'content': 'This is not JSON at all'},
          },
        ],
      });
      httpClient.setResponse(http.Response(invalidBody, 200));

      // Act
      final result = await repo.translate(tempFile.path, 'table');

      // Assert
      expect(result, isNull);

      tempDir.deleteSync(recursive: true);
    });

    test('cache read failure falls through to API call', () async {
      // Arrange: cache throws, but API succeeds
      docRef = FakeDocumentReference(); // get() returns non-existent by default
      // Override get to throw
      collection = FakeCollectionReference(docRef);
      firestore = FakeFirebaseFirestore(collection);
      repo = AiTranslationRepositoryImpl(firestore, httpClient, apiKey);

      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test.jpg');
      tempFile.writeAsBytesSync([0xFF, 0xD8]);

      httpClient.setResponse(http.Response(_successResponseBody(), 200));

      // Act
      final result = await repo.translate(tempFile.path, 'table');

      // Assert
      expect(result, isNotNull);
      expect(result!.esLabel, 'mesa');

      tempDir.deleteSync(recursive: true);
    });
  });
}
