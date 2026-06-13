import 'package:agy_flutter/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Form(child: child)),
  );

  testWidgets('renders label and updates text correctly', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      wrap(AppTextField(label: 'Email Address', controller: controller)),
    );

    // Verify label is rendered
    expect(find.text('Email Address'), findsOneWidget);

    // Enter text and verify controller is updated
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    expect(controller.text, 'test@example.com');
  });

  testWidgets('triggers validator when form is validated', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var validated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Password',
                  controller: controller,
                  validator: (value) {
                    validated = true;
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    formKey.currentState?.validate();
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Tap submit when field is empty
    await tester.tap(find.text('Submit'));
    await tester.pump();

    // Verify validator was triggered and error message displays
    expect(validated, true);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
