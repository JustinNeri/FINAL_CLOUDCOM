import 'package:cloudcom_final/delete_monster.dart';
import 'package:cloudcom_final/edit_monster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _caught = [
  {'catch_id': 10, 'monster_id': 1, 'monster_name': 'Sparky', 'monster_type': 'Electric'},
  {'catch_id': 11, 'monster_id': 2, 'monster_name': 'Blaze', 'monster_type': 'Fire'},
];

void main() {
  group('Delete Monsters', () {
    testWidgets('lists caught monsters for the player', (tester) async {
      final requests = useFakeServer({'get_caught_monsters_api.php': (_) => jsonResponse({'data': _caught})});
      await pumpScreen(tester, const DeleteMonsterScreen(playerId: '7'));

      expect(requests.single.url.queryParameters, {'player_id': '7'});
      expect(find.text('Caught Monsters (2)'), findsOneWidget);
      expect(find.text('Sparky'), findsOneWidget);
    });

    testWidgets('deletes after confirmation', (tester) async {
      final requests = useFakeServer({
        'get_caught_monsters_api.php': (_) => jsonResponse(_caught),
        'delete_monster_api.php': (_) => jsonResponse({'ok': true}),
      });
      await pumpScreen(tester, const DeleteMonsterScreen(playerId: '7'));

      await tester.tap(find.byTooltip('Delete Sparky'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);

      expect(requests.last.bodyFields, {'catch_id': '10', 'monster_id': '1'});
      expect(find.text('Sparky'), findsNothing);
      expect(find.text('Sparky was released.'), findsOneWidget);
    });

    testWidgets('keeps the monster when the server refuses', (tester) async {
      useFakeServer({
        'get_caught_monsters_api.php': (_) => jsonResponse(_caught),
        'delete_monster_api.php': (_) => jsonResponse({'ok': false, 'error': 'Not your catch'}),
      });
      await pumpScreen(tester, const DeleteMonsterScreen(playerId: '7'));

      await tester.tap(find.byTooltip('Delete Sparky'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);

      expect(find.text('Delete failed: Not your catch'), findsOneWidget);
      expect(find.text('Sparky'), findsOneWidget);
    });

    testWidgets('shows an empty state when nothing is caught', (tester) async {
      useFakeServer({'get_caught_monsters_api.php': (_) => jsonResponse([])});
      await pumpScreen(tester, const DeleteMonsterScreen(playerId: '7'));

      expect(find.text('No caught monsters yet'), findsOneWidget);
    });

    testWidgets('shows load errors with a retry button', (tester) async {
      useFakeServer({'get_caught_monsters_api.php': (_) => jsonResponse({'error': 'Database offline'})});
      await pumpScreen(tester, const DeleteMonsterScreen(playerId: '7'));

      expect(find.text('Database offline'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Edit Monsters', () {
    testWidgets('requires a name or type', (tester) async {
      final requests = useFakeServer({'get_caught_monsters_api.php': (_) => jsonResponse(_caught)});
      await pumpScreen(tester, const EditMonsterScreen(playerId: '7'));

      await tester.tap(find.byTooltip('Edit Sparky'));
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Monster Name'), '');
      await tester.enterText(find.widgetWithText(TextFormField, 'Monster Type'), '');
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      expect(find.text('Enter a new name or type.'), findsOneWidget);
      expect(requests, hasLength(1));
    });

    testWidgets('saves a new name and updates the list', (tester) async {
      final requests = useFakeServer({
        'get_caught_monsters_api.php': (_) => jsonResponse(_caught),
        'edit_monster_api.php': (_) => jsonResponse({'ok': true}),
      });
      await pumpScreen(tester, const EditMonsterScreen(playerId: '7'));

      await tester.tap(find.byTooltip('Edit Sparky'));
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Monster Name'), 'Zappy');
      await tester.tap(find.text('Save Changes'));
      await settle(tester);

      expect(requests.last.bodyFields, {'catch_id': '10', 'monster_id': '1', 'name': 'Zappy', 'type': 'Electric'});
      expect(find.text('Zappy'), findsOneWidget);
      expect(find.text('Monster updated.'), findsOneWidget);
    });

    testWidgets('keeps the sheet open and shows the error when saving fails', (tester) async {
      useFakeServer({
        'get_caught_monsters_api.php': (_) => jsonResponse(_caught),
        'edit_monster_api.php': (_) => jsonResponse({'ok': false, 'error': 'Name too long'}),
      });
      await pumpScreen(tester, const EditMonsterScreen(playerId: '7'));

      await tester.tap(find.byTooltip('Edit Sparky'));
      await settle(tester);
      await tester.tap(find.text('Save Changes'));
      await settle(tester);

      expect(find.text('Name too long'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });
}
