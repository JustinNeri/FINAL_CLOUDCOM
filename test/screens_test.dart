import 'package:cloudcom_final/auth_models.dart';
import 'package:cloudcom_final/instance_screen.dart';
import 'package:cloudcom_final/instance_status.dart';
import 'package:cloudcom_final/player_accounts_screen.dart';
import 'package:cloudcom_final/top_hunters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('Top Hunters', () {
    testWidgets('ranks players by catches and marks the current player', (tester) async {
      useFakeServer({
        'view_top_hunters_api.php': (_) => jsonResponse([
              {'player_id': 1, 'player_name': 'Brock', 'total_catches': 3},
              {'player_id': 7, 'player_name': 'Ash', 'total_catches': 9},
            ]),
      });
      await pumpScreen(tester, const TopHuntersScreen(currentPlayerId: '7'));

      final ashTop = tester.getTopLeft(find.text('Ash')).dy;
      final brockTop = tester.getTopLeft(find.text('Brock')).dy;
      expect(ashTop, lessThan(brockTop));
      expect(find.text('You'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('shows an error with retry when the server fails', (tester) async {
      useFakeServer({'view_top_hunters_api.php': (_) => jsonResponse({}, 500)});
      await pumpScreen(tester, const TopHuntersScreen());

      expect(find.text('Could not load the leaderboard (500).'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Instance', () {
    testWidgets('starting shows progress and polls until running', (tester) async {
      var state = 'stopped';
      final requests = useFakeServer({
        'STOP_AND_START': (r) {
          if (r.url.queryParameters['action'] == 'start') state = 'pending';
          return jsonResponse({'state': state});
        },
      });
      await pumpScreen(
        tester,
        const InstanceScreen(initialState: InstanceState.unknown, pollInterval: Duration(seconds: 1)),
      );
      expect(find.text('Offline'), findsOneWidget);

      await tester.tap(find.text('Start server'));
      await settle(tester);
      expect(find.text('Starting…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      state = 'running';
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);

      expect(find.text('Online'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(requests.where((r) => r.url.queryParameters['action'] == 'start'), isNotEmpty);
    });

    testWidgets('asks before stopping the server', (tester) async {
      final requests = useFakeServer({'STOP_AND_START': (_) => jsonResponse({'state': 'running'})});
      await pumpScreen(tester, const InstanceScreen(initialState: InstanceState.unknown));

      await tester.tap(find.text('Stop server'));
      await settle(tester);
      expect(find.text('Stop the server?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(requests.where((r) => r.url.queryParameters['action'] == 'stop'), isEmpty);
    });
  });

  group('My Account', () {
    const player = PlayerProfile(id: '7', username: 'ash', name: 'Ash');

    testWidgets('updates the profile and reports it upward', (tester) async {
      PlayerProfile? reported;
      final requests = useFakeServer({
        'list_players_api.php': (_) => jsonResponse([
              {'player_id': 7, 'username': 'ash', 'player_name': 'Ash'},
            ]),
        'update_player_api.php': (_) => jsonResponse({'ok': true, 'affected_rows': 1}),
      });
      await pumpScreen(tester, PlayerAccountsScreen(currentPlayer: player, onProfileUpdated: (p) => reported = p));

      await tester.tap(find.text('Edit profile or password'));
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Player Name'), 'Ash Ketchum');
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(requests.last.bodyFields, {'player_id': '7', 'username': 'ash', 'player_name': 'Ash Ketchum'});
      expect(reported?.name, 'Ash Ketchum');
      expect(find.text('Profile updated.'), findsOneWidget);
    });

    testWidgets('validates the new password before saving', (tester) async {
      final requests = useFakeServer({'list_players_api.php': (_) => jsonResponse([])});
      await pumpScreen(tester, PlayerAccountsScreen(currentPlayer: player, onProfileUpdated: (_) {}));

      await tester.tap(find.text('Edit profile or password'));
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'abc');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'abd');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Use at least 6 characters.'), findsOneWidget);
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(requests.where((r) => r.url.path.endsWith('update_player_api.php')), isEmpty);
    });
  });
}
