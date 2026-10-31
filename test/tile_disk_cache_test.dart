import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:uniandes_food/services/map/cached_tile_provider.dart';

const _url = 'https://tile.openstreetmap.org/17/1/2.png';
const _key = '17/1/2.png';

void main() {
  late Directory directory;
  late int requests;
  var online = true;
  var now = DateTime(2026, 10, 30);

  TileDiskCache cache() => TileDiskCache(
    directory: Future.value(directory),
    now: () => now,
    client: MockClient((request) async {
      requests++;
      if (!online) throw const SocketException('No internet');
      return http.Response.bytes([1, 2, 3], 200);
    }),
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('tiles');
    requests = 0;
    online = true;
    now = DateTime.now();
  });

  tearDown(() => directory.delete(recursive: true));

  test('A downloaded tile is saved and then read from disk', () async {
    final tiles = cache();

    expect(await tiles.load(_url, key: _key), [1, 2, 3]);
    expect(await tiles.load(_url, key: _key), [1, 2, 3]);

    expect(requests, 1);
    expect(File('${directory.path}/$_key').existsSync(), isTrue);
  });

  test('Offline, a saved tile is shown even when it is old', () async {
    await cache().load(_url, key: _key);
    online = false;
    now = now.add(const Duration(days: 60));

    expect(await cache().load(_url, key: _key), [1, 2, 3]);
  });

  test('Offline, a tile never seen before fails so the map can say so', () {
    online = false;

    expect(cache().load(_url, key: _key), throwsA(isA<SocketException>()));
  });
}
