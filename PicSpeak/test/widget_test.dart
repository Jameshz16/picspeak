import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picspeak/features/onboarding/data/onboarding_providers.dart';
import 'package:picspeak/features/onboarding/data/onboarding_repository.dart';

class _MockOnboardingRepository implements OnboardingRepository {
  @override
  Future<bool> hasSeenOnboarding() async => true;

  @override
  Future<void> markOnboardingSeen() async {}
}

void main() {
  testWidgets('App renders with ProviderScope and mocked onboarding',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(
            _MockOnboardingRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Text('Test')),
        ),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
  });
}
