import 'package:agy_flutter/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows label and fires onPressed when idle', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(PrimaryButton(label: 'Submit', onPressed: () => taps++)),
    );

    expect(find.text('Submit'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    expect(taps, 1);
  });

  testWidgets('shows spinner and ignores taps while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        PrimaryButton(
          label: 'Submit',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    expect(find.text('Submit'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    expect(taps, 0);
  });
}
