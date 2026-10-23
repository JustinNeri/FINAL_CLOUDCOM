import 'package:flutter_test/flutter_test.dart';

import 'package:cloudcom_final/main.dart';

void main() {
  testWidgets('App starts on the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Player Login'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Player Account'), findsOneWidget);
  });

  testWidgets('Login requires username and password', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Please enter username and password.'), findsOneWidget);
  });
}
