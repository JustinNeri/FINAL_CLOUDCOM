import 'dart:convert';

import 'package:cloudcom_final/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

const _savedPlayer = {'player_id': '7', 'username': 'ash', 'player_name': 'Ash'};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Login', () {
    testWidgets('starts on the login screen when nobody is signed in', (tester) async {
      await tester.pumpWidget(const MyApp());
      await settle(tester);

      expect(find.text('Player Login'), findsOneWidget);
      expect(find.text('Create Player Account'), findsOneWidget);
    });

    testWidgets('requires username and password', (tester) async {
      await tester.pumpWidget(const MyApp());
      await settle(tester);

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Please enter username and password.'), findsOneWidget);
    });

    testWidgets('signs in, shows the dashboard and remembers the player', (tester) async {
      final requests = useFakeServer({
        'login_player_api.php': (_) => jsonResponse({'ok': true, 'player': _savedPlayer}),
      });
      await tester.pumpWidget(const MyApp());
      await settle(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'ash');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'pikachu1');
      await tester.tap(find.text('Login'));
      await settle(tester);

      expect(requests.single.bodyFields, {'username': 'ash', 'password': 'pikachu1'});
      expect(find.text('Welcome back, Ash!'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('signed_in_player')!), _savedPlayer);
    });

    testWidgets('shows the server error for a wrong password', (tester) async {
      useFakeServer({
        'login_player_api.php': (_) => jsonResponse({'ok': false, 'error': 'Wrong password'}),
      });
      await tester.pumpWidget(const MyApp());
      await settle(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'ash');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'nope');
      await tester.tap(find.text('Login'));
      await settle(tester);

      expect(find.text('Wrong password'), findsOneWidget);
      expect(find.text('Player Login'), findsOneWidget);
    });
  });

  group('Session', () {
    testWidgets('a saved player skips the login screen', (tester) async {
      SharedPreferences.setMockInitialValues({'signed_in_player': jsonEncode(_savedPlayer)});
      await tester.pumpWidget(const MyApp());
      await settle(tester);

      expect(find.text('Welcome back, Ash!'), findsOneWidget);
      expect(find.text('Player Login'), findsNothing);
    });

    testWidgets('logging out forgets the player', (tester) async {
      SharedPreferences.setMockInitialValues({'signed_in_player': jsonEncode(_savedPlayer)});
      await tester.pumpWidget(const MyApp());
      await settle(tester);

      await tester.tap(find.byTooltip('Open navigation menu'));
      await settle(tester);
      await tester.ensureVisible(find.text('Log Out'));
      await settle(tester);
      await tester.tap(find.text('Log Out'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await settle(tester);

      expect(find.text('Player Login'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('signed_in_player'), isNull);
    });
  });

  testWidgets('Catch is blocked while the server instance is offline', (tester) async {
    SharedPreferences.setMockInitialValues({'signed_in_player': jsonEncode(_savedPlayer)});
    useFakeServer({'STOP_AND_START': (_) => jsonResponse({'state': 'stopped'})});
    await tester.pumpWidget(const MyApp());
    await settle(tester);

    // Visit the instance screen so the dashboard learns the real status.
    await tester.tap(find.text('Server instance'));
    await settle(tester);
    expect(find.text('Offline'), findsOneWidget);
    await tester.tap(find.text('Back to dashboard'));
    await settle(tester);

    await tester.tap(find.text('Catch Monsters'));
    await settle(tester);

    expect(find.text('The server is offline. Start it to catch monsters.'), findsOneWidget);
    expect(find.text('Detect Monsters'), findsNothing);
  });
}
