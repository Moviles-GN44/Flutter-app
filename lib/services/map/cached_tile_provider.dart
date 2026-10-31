import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Keeps the map tiles the student has already seen on the phone's disk.
///
/// The campus is a small, fixed area, so after one visit its whole map fits in
/// a few megabytes. A tile is read from disk and only downloaded when it is
/// missing or older than [maxAge]. Offline, even an old tile is better than a
/// grey square. Caching also follows the OpenStreetMap tile usage policy,
/// which asks apps not to download the same tiles again and again.
class TileDiskCache {
  TileDiskCache({
    Future<Directory>? directory,
    http.Client? client,
    this.maxAge = const Duration(days: 30),
    DateTime Function()? now,
  }) : _injectedDirectory = directory,
       _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  /// The cache the map uses.
  static final shared = TileDiskCache();

  /// Campus streets and buildings rarely change, so a tile stays fresh for a
  /// month before it is downloaded again.
  final Duration maxAge;

  final Future<Directory>? _injectedDirectory;
  final http.Client _client;
  final DateTime Function() _now;

  late final Future<Directory> _directory =
      _injectedDirectory ??
      getApplicationCacheDirectory().then(
        (cache) => Directory('${cache.path}/map_tiles'),
      );

  /// The image bytes of the tile saved under [key] (e.g. `17/12345/6789.png`),
  /// downloaded from [url] when there is no fresh copy on disk.
  Future<Uint8List> load(
    String url, {
    required String key,
    Map<String, String> headers = const {},
  }) async {
    final file = File('${(await _directory).path}/$key');
    final saved = await file.exists() ? file : null;
    if (saved != null &&
        _now().difference(await saved.lastModified()) < maxAge) {
      return saved.readAsBytes();
    }

    try {
      final response = await _client.get(Uri.parse(url), headers: headers);
      if (response.statusCode != 200) {
        throw HttpException(
          'Tile request failed (${response.statusCode})',
          uri: Uri.parse(url),
        );
      }
      await _save(file, response.bodyBytes);
      return response.bodyBytes;
    } on Exception {
      // Offline (or the server failed): an outdated tile still shows the
      // campus. Without one, the error reaches the map, which tells the
      // student the background is unavailable.
      if (saved != null) return saved.readAsBytes();
      rethrow;
    }
  }

  // Writes to a temporary file first, so a tile cut off halfway (e.g. the app
  // is closed while saving) never replaces a good one.
  Future<void> _save(File file, Uint8List bytes) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(file.path);
  }
}

/// Map tile provider that loads tiles through [TileDiskCache].
class CachedTileProvider extends TileProvider {
  CachedTileProvider({TileDiskCache? cache})
    : _cache = cache ?? TileDiskCache.shared;

  final TileDiskCache _cache;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _CachedTileImage(
      url: getTileUrl(coordinates, options),
      key: '${coordinates.z}/${coordinates.x}/${coordinates.y}.png',
      headers: headers,
      cache: _cache,
    );
  }
}

class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  const _CachedTileImage({
    required this.url,
    required this.key,
    required this.headers,
    required this.cache,
  });

  final String url;
  final String key;
  final Map<String, String> headers;
  final TileDiskCache cache;

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _decode(decode),
      scale: 1,
      debugLabel: url,
    );
  }

  Future<ui.Codec> _decode(ImageDecoderCallback decode) async {
    final bytes = await cache.load(url, key: key, headers: headers);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
