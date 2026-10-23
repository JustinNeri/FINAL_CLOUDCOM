import 'package:cloudcom_final/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';

Future<void> fillForm(WidgetTester tester, {String username = 'misty', String password = 'starmie1', String? confirm}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Username'), username);
  await tester.enterText(find.widgetWithText(TextFormField, 'Password'), password);
  await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), confirm ?? password);
}

void main() {
  testWidgets('rejects mismatched and short passwords without calling the server', (tester) async {
    final requests = useFakeServer({});
    await pumpScreen(tester, const CreatePlayerAccountScreen());

    await fillForm(tester, password: 'abc', confirm: 'abd');
    await tapVisible(tester, findButton('Create Account'));
    await tester.pump();

    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('rejects usernames with spaces', (tester) async {
    await pumpScreen(tester, const CreatePlayerAccountScreen());

    await fillForm(tester, username: 'ash ketchum');
    await tapVisible(tester, findButton('Create Account'));
    await tester.pump();

    expect(find.text('Usernames cannot contain spaces.'), findsOneWidget);
  });

  testWidgets('shows a server error returned with HTTP 200', (tester) async {
    useFakeServer({
      'create_player_api.php': (_) => jsonResponse({'ok': false, 'error': 'Username already taken'}),
    });
    await pumpScreen(tester, const CreatePlayerAccountScreen());

    await fillForm(tester);
    await tapVisible(tester, findButton('Create Account'));
    await settle(tester);

    expect(find.text('Username already taken'), findsOneWidget);
    expect(find.byType(CreatePlayerAccountScreen), findsOneWidget);
  });

  testWidgets('on success returns to login with the username filled in', (tester) async {
    late http.Request sent;
    useFakeServer({
      'create_player_api.php': (r) {
        sent = r;
        return jsonResponse({'ok': true});
      },
    });
    await pumpScreen(tester, LoginScreen(onLoginSuccess: (_) {}));

    await tapVisible(tester, find.text('Create Player Account'));
    // Finish the page transition so the login form is offstage.
    await tester.pumpAndSettle();
    await fillForm(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Player Name (optional)'), 'Misty');
    await tapVisible(tester, findButton('Create Account'));
    await settle(tester);
    await tester.pumpAndSettle();

    expect(sent.bodyFields, {'username': 'misty', 'player_name': 'Misty', 'password': 'starmie1'});
    expect(find.text('Player Login'), findsOneWidget);
    expect(find.text('Account created. Sign in with your new password.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'misty'), findsOneWidget);
  });
}
