import 'package:cloudcom_final/api.dart';
import 'package:cloudcom_final/auth_models.dart';
import 'package:cloudcom_final/caught_monsters.dart';
import 'package:cloudcom_final/instance_status.dart';
import 'package:cloudcom_final/top_hunters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseInstanceState', () {
    test('reads JSON state fields', () {
      expect(parseInstanceState('{"state": "running"}'), InstanceState.running);
      expect(parseInstanceState('{"status": "pending"}'), InstanceState.starting);
      expect(parseInstanceState('{"instance_state": "stopped"}'), InstanceState.stopped);
    });

    test('treats stopping as stopping, not online', () {
      expect(parseInstanceState('Instance is stopping'), InstanceState.stopping);
      expect(parseInstanceState('was running, now stopping'), InstanceState.stopping);
    });

    test('falls back to unknown', () {
      expect(parseInstanceState('{"ok": true}'), InstanceState.unknown);
      expect(parseInstanceState(''), InstanceState.unknown);
    });
  });

  group('decodeList', () {
    test('accepts a list or a data wrapper', () {
      expect(decodeList('[{"a": 1}]'), [
        {'a': 1}
      ]);
      expect(decodeList('{"data": [{"a": 1}, 5]}'), [
        {'a': 1}
      ]);
    });

    test('returns null for other shapes', () {
      expect(decodeList('{"error": "x"}'), isNull);
      expect(decodeList('not json'), isNull);
    });
  });

  test('requestErrorMessage explains unreachable servers', () {
    expect(requestErrorMessage(Exception('ClientException: XMLHttpRequest error.')), contains('Could not reach the server'));
    expect(requestErrorMessage(Exception('TimeoutException after 0:00:10')), contains('took too long'));
  });

  test('CaughtMonster pins the spawn point before the catch point', () {
    final both = CaughtMonster.fromMap({
      'catch_id': 1,
      'monster_id': 2,
      'spawn_latitude': '15.1',
      'spawn_longitude': '120.1',
      'latitude': '15.2',
      'longitude': '120.2',
    });
    expect([both.mapLat, both.mapLon, both.coordinateSource], [15.1, 120.1, 'Spawn']);

    final catchOnly = CaughtMonster.fromMap({'catch_id': 1, 'monster_id': 2, 'lat': '15.2', 'lon': '120.2'});
    expect([catchOnly.mapLat, catchOnly.coordinateSource], [15.2, 'Caught location']);
  });

  test('parseHunterStats aggregates raw catch rows', () {
    final stats = parseHunterStats('[{"player_id": 1}, {"player_id": 2}, {"player_id": 2, "player_name": "Ash"}]');
    expect(stats.map((s) => [s.playerId, s.totalCatches]), [
      ['2', 2],
      ['1', 1],
    ]);
    expect(stats.first.playerName, 'Ash');
  });

  test('PlayerProfile survives a save and load round trip', () {
    const profile = PlayerProfile(id: '7', username: 'ash', name: 'Ash');
    final restored = PlayerProfile.fromMap(profile.toMap());
    expect([restored.id, restored.username, restored.name], ['7', 'ash', 'Ash']);
    expect(const PlayerProfile(id: '1', username: 'brock').displayName, 'brock');
  });
}
