import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustcircleai/theme/trustcircle_theme.dart';

void main() {
  final theme = TrustCircleTheme.light;

  test('uses the TrustCircle palette on the active Material theme', () {
    expect(theme.scaffoldBackgroundColor, TrustCircleColors.background);
    expect(theme.colorScheme.primary, TrustCircleColors.trustBlue);
    expect(theme.colorScheme.secondary, TrustCircleColors.intelligenceTeal);
    expect(theme.appBarTheme.backgroundColor, TrustCircleColors.trustNavy);
    expect(theme.cardTheme.color, TrustCircleColors.surface);
    expect(theme.textTheme.headlineLarge?.letterSpacing, 0);
  });

  test('applies prompt-defined card, input, and button radii', () {
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(
      cardShape.borderRadius.resolve(TextDirection.ltr),
      BorderRadius.circular(12),
    );

    final input = theme.inputDecorationTheme;
    for (final border in [
      input.border,
      input.enabledBorder,
      input.focusedBorder,
    ]) {
      expect(border, isA<OutlineInputBorder>());
      expect(
        (border! as OutlineInputBorder).borderRadius,
        BorderRadius.circular(8),
      );
    }

    final buttonStyles = [
      theme.elevatedButtonTheme.style,
      theme.filledButtonTheme.style,
      theme.outlinedButtonTheme.style,
    ];
    for (final style in buttonStyles) {
      final shape = style!.shape!.resolve({})! as RoundedRectangleBorder;
      expect(
        shape.borderRadius.resolve(TextDirection.ltr),
        BorderRadius.circular(8),
      );
      expect(style.minimumSize!.resolve({})!.width, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('Material widgets resolve the configured TrustCircle theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TrustCircleTheme.light,
        home: Scaffold(
          appBar: AppBar(title: const Text('TrustCircle')),
          body: const Card(
            child: TextField(decoration: InputDecoration(labelText: 'Name')),
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(TextField));
    final resolvedTheme = Theme.of(context);
    final renderedCard = tester.widget<Card>(find.byType(Card));
    final renderedAppBar = tester.widget<AppBar>(find.byType(AppBar));

    expect(resolvedTheme.scaffoldBackgroundColor, TrustCircleColors.background);
    expect(
      renderedCard.color ?? resolvedTheme.cardTheme.color,
      TrustCircleColors.surface,
    );
    expect(
      renderedAppBar.backgroundColor ??
          resolvedTheme.appBarTheme.backgroundColor,
      TrustCircleColors.trustNavy,
    );
    expect(
      resolvedTheme.inputDecorationTheme.enabledBorder,
      isA<OutlineInputBorder>(),
    );
    expect(tester.takeException(), isNull);
  });
}
