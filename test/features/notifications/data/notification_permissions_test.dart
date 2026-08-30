import 'package:flutter_test/flutter_test.dart';

import 'package:picspeak/features/notifications/domain/notification_permission_status.dart';
import 'package:picspeak/features/notifications/data/notification_permissions.dart';

void main() {
  group('NotificationPermissionStatus', () {
    test('has granted value', () {
      expect(NotificationPermissionStatus.granted, isNotNull);
    });

    test('has denied value', () {
      expect(NotificationPermissionStatus.denied, isNotNull);
    });

    test('has permanentlyDenied value', () {
      expect(NotificationPermissionStatus.permanentlyDenied, isNotNull);
    });

    test('enum has exactly 3 values', () {
      expect(NotificationPermissionStatus.values.length, equals(3));
    });

    test('values are distinct', () {
      final values = NotificationPermissionStatus.values;
      expect(values.toSet().length, equals(values.length));
    });
  });

  group('NotificationPermissions', () {
    // NOTE: requestPermission() and getPermissionStatus() require platform
    // channel mocking via permission_handler. These tests verify the class
    // can be instantiated and the enum contract is correct.
    //
    // Full integration tests for permission flow should be done via
    // integration_test/ with real platform channels.

    test('can be instantiated', () {
      final permissions = NotificationPermissions();
      expect(permissions, isA<NotificationPermissions>());
    });
  });
}
