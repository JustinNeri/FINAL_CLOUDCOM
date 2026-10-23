import 'package:cloudcom_final/catch_monster.dart';
import 'package:cloudcom_final/location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'helpers.dart';

const _nearby = [
  {'monster_id': 1, 'monster_name': 'Sparky', 'monster_type': 'Electric', 'distance': 12},
  {'monster_id': 2, 'monster_name': 'Blaze', 'monster_type': 'Fire', 'distance': 30},
  {'monster_id': 3, 'monster_name': 'Drip', 'monster_type': 'Water', 'distance': 45},
];

Future<void> openAndDetect(WidgetTester tester) async {
  await pumpScreen(tester, const CatchMonsterScreen(playerId: '7', enableAlerts: false));
  await tester.tap(find.text('Detect Monsters'));
  await settle(tester);
}

void main() {
  setUp(() => currentLocation = () async => const LatLng(15.1, 120.5));

  testWidgets('lists nearby monsters, hiding ones already caught', (tester) async {
    final requests = useFakeServer({
      'get_caught_monsters_api.php': (_) => jsonResponse([{'monster_id': 3}]),
      'detect_monsters_api.php': (_) => jsonResponse(_nearby),
    });
    await openAndDetect(tester);

    final detect = requests.lastWhere((r) => r.url.path.endsWith('detect_monsters_api.php'));
    expect(detect.url.queryParameters, {'lat': '15.1', 'lon': '120.5'});
    expect(find.text('Nearby Monsters (2)'), findsOneWidget);
    expect(find.text('Sparky'), findsOneWidget);
    expect(find.text('Blaze'), findsOneWidget);
    expect(find.text('Drip'), findsNothing);
    expect(find.text('Catch Sparky'), findsOneWidget);
  });

  testWidgets('selecting a monster changes the catch target', (tester) async {
    useFakeServer({
      'get_caught_monsters_api.php': (_) => jsonResponse([]),
      'detect_monsters_api.php': (_) => jsonResponse(_nearby),
    });
    await openAndDetect(tester);

    await tester.tap(find.text('Blaze'));
    await tester.pump();

    expect(find.text('Catch Blaze'), findsOneWidget);
  });

  testWidgets('a successful catch removes the monster and moves to the next', (tester) async {
    final requests = useFakeServer({
      'get_caught_monsters_api.php': (_) => jsonResponse([]),
      'detect_monsters_api.php': (_) => jsonResponse(_nearby),
      'catch_monster_api.php': (_) => jsonResponse({'ok': true}),
    });
    await openAndDetect(tester);

    await tester.tap(find.text('Catch Sparky'));
    await settle(tester);

    final sent = requests.lastWhere((r) => r.url.path.endsWith('catch_monster_api.php'));
    expect(sent.bodyFields, {'player_id': '7', 'monster_id': '1', 'lat': '15.1', 'lon': '120.5'});
    expect(find.text('Sparky'), findsNothing);
    expect(find.text('Catch Blaze'), findsOneWidget);
  });

  testWidgets('a rejected catch shows the reason and keeps the monster', (tester) async {
    useFakeServer({
      'get_caught_monsters_api.php': (_) => jsonResponse([]),
      'detect_monsters_api.php': (_) => jsonResponse(_nearby),
      'catch_monster_api.php': (_) => jsonResponse({'ok': false, 'error': 'Too far away'}),
    });
    await openAndDetect(tester);

    await tester.tap(find.text('Catch Sparky'));
    await settle(tester);

    expect(find.text('Catch failed: Too far away'), findsOneWidget);
    expect(find.text('Sparky'), findsOneWidget);
  });

  testWidgets('says so when nothing is nearby', (tester) async {
    useFakeServer({
      'get_caught_monsters_api.php': (_) => jsonResponse([]),
      'detect_monsters_api.php': (_) => jsonResponse([]),
    });
    await openAndDetect(tester);

    expect(find.text('No monster found nearby.'), findsOneWidget);
  });

  testWidgets('shows a location error with a way to retry', (tester) async {
    useFakeServer({});
    currentLocation = () async => throw const LocationException('Location permission was denied.');
    await pumpScreen(tester, const CatchMonsterScreen(playerId: '7', enableAlerts: false));

    expect(find.text('Location unavailable'), findsOneWidget);
    expect(find.text('Location permission was denied.'), findsOneWidget);
    expect(find.byTooltip('Update location'), findsOneWidget);
  });
}
