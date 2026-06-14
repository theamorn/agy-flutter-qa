import 'package:agy_flutter/widgets/app_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders title and active status by default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppStatusCard(title: 'Server Status')),
      ),
    );

    expect(find.text('Server Status'), findsOneWidget);
    expect(find.text('Status: Active'), findsOneWidget);
    // This key is broken/wrong! The widget has key 'change_status_button'
    expect(find.byKey(const Key('toggle_status_button')), findsOneWidget);
  });
}
