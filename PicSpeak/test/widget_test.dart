import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:picspeak/main.dart';

void main() {
  testWidgets('App renders with ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PicSpeakApp()),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
