import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustcircleai/models/trust_case.dart';
import 'package:trustcircleai/screens/assessment_screen.dart';
import 'package:trustcircleai/services/trust_intelligence_engine.dart';
import 'package:trustcircleai/theme/trustcircle_theme.dart';
import 'package:trustcircleai/main.dart';

void main() {
  testWidgets('shows demo login details and logs in with test credentials', (
    tester,
  ) async {
    await tester.pumpWidget(const TrustCircleApp());
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('Use demo login:'), findsOneWidget);
    expect(find.text('admin@trustcircle.ai'), findsOneWidget);
    expect(find.text('TrustCircle@123'), findsOneWidget);

    final textFields = find.byType(TextField);

    await tester.enterText(textFields.at(0), 'admin@trustcircle.ai');
    await tester.enterText(textFields.at(1), 'TrustCircle@123');
    await tester.tap(find.text('Enter secure workspace'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your plan'), findsOneWidget);
    await tester.tap(find.text('Start with Freemium'));
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('PRIVATE & CONFIDENTIAL'), findsOneWidget);
  });

  testWidgets('shows freemium and paid plan options before access', (
    tester,
  ) async {
    await tester.pumpWidget(const TrustCircleApp());
    await tester.pump(const Duration(milliseconds: 1500));

    await tester.enterText(
      find.byKey(const ValueKey('login_email_field')),
      'admin@trustcircle.ai',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login_password_field')),
      'TrustCircle@123',
    );
    await tester.tap(find.text('Enter secure workspace'));
    await tester.pumpAndSettle();

    expect(find.text('Freemium'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Unlimited PDF exports'), findsOneWidget);
  });

  testWidgets('shows verification navigation after plan selection', (
    tester,
  ) async {
    await tester.pumpWidget(const TrustCircleApp());
    await tester.pump(const Duration(milliseconds: 1500));

    await tester.enterText(
      find.byKey(const ValueKey('login_email_field')),
      'admin@trustcircle.ai',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login_password_field')),
      'TrustCircle@123',
    );
    await tester.tap(find.text('Enter secure workspace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start with Freemium'));
    await tester.pumpAndSettle();

    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
  });

  testWidgets('labels a fallback verdict provisional and omits confidence', (
    tester,
  ) async {
    final trustCase =
        TrustCase.create(
          title: 'Payment review',
          personName: 'Asha Rao',
          statement: 'The payment was made.',
          caseLanguage: 'en',
          displayLanguage: 'en',
          confidentialityLevel: 'private',
          authorizationConfirmed: true,
          confidentialityConfirmed: true,
          sequence: 40,
        ).copyWith(
          evidence: [
            EvidenceItem(
              id: 'evidence-40',
              text: 'A bank entry records the payment.',
              source: 'Bank statement',
              sourceType: 'document',
              relation: EvidenceRelation.supports,
              createdAt: DateTime(2026, 10, 1),
            ),
          ],
        );
    final result = await const TrustIntelligenceEngine().analyze(trustCase);

    await tester.pumpWidget(
      MaterialApp(
        theme: TrustCircleTheme.light,
        home: Scaffold(
          body: AssessmentScreen(
            trustCase: trustCase,
            result: result,
            displayLanguage: 'en',
            onRun: () {},
          ),
        ),
      ),
    );

    expect(
      find.textContaining('This is not a model assessment'),
      findsOneWidget,
    );
    expect(find.text('Assessment confidence'), findsOneWidget);
    expect(find.text('Unavailable'), findsWidgets);
    expect(find.textContaining('%'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'creates a case and explains that fallback analysis needs evidence',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const TrustCircleApp());
      await tester.enterText(
        find.byKey(const ValueKey('login_email_field')),
        'admin@trustcircle.ai',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login_password_field')),
        'TrustCircle@123',
      );
      await tester.tap(find.text('Enter secure workspace'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start with Freemium'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('case_field_Person name')),
        'Asha Rao',
      );
      await tester.enterText(
        find.byKey(const ValueKey('case_field_Case title')),
        'Payment review',
      );
      await tester.enterText(
        find.byKey(const ValueKey('case_field_Original statement')),
        'The payment was made.',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('authorization_confirmation')),
      );
      await tester.tap(
        find.byKey(const ValueKey('authorization_confirmation')),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('confidentiality_confirmation')),
      );
      await tester.tap(
        find.byKey(const ValueKey('confidentiality_confirmation')),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('create_case_button')),
      );
      await tester.tap(find.byKey(const ValueKey('create_case_button')));
      await tester.pumpAndSettle();

      expect(find.text('Case created for this session.'), findsOneWidget);
      expect(find.textContaining('TC-2026-'), findsOneWidget);
      expect(find.text('No evidence added'), findsOneWidget);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trust analysis'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Run assessment'));
      await tester.pumpAndSettle();
      expect(find.text('INCONCLUSIVE'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No evidence has been attached to this case.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
