import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qafox/core/enums/bug_status.dart';
import 'package:qafox/shared/widgets/app_badge.dart';
import 'package:qafox/core/widgets/app_button.dart';

void main() {
  testWidgets('AppButton and AppBadge widget test', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              children: [
                AppBadge.status(BugStatus.inProgress),
                AppButton(
                  text: 'Submit Bug',
                  onPressed: () {
                    tapped = true;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Submit Bug'), findsOneWidget);

    await tester.tap(find.text('Submit Bug'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
