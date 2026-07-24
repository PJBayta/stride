import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:path_provider/path_provider.dart';

/// Manages the tile cache for flutter_map's [TileLayer].
///
/// ## How the cache works
/// Every OSM tile fetched by flutter_map goes through [CachedTileProvider].
/// The provider checks the local file-system store first:
///   - **HIT** → returns the cached file immediately, no network request.
///   - **STALE** (older than [maxStale]) → serves the cached tile while
///     revalidating it in the background (stale-while-revalidate).
///   - **MISS** → downloads from the tile server, stores the response, then
///     returns it.
///
/// This means previously-viewed routes display their map tiles even when the
/// device has no internet connection, as long as those tiles were downloaded
/// during an earlier online session.
///
/// ## Extending later
/// To add a "Clear Map Cache" button in Settings, call [clearCache()].
/// The method is static so Settings can invoke it without holding a reference
/// to this service instance.
class TileCacheService {
  TileCacheService._();

  static const _cacheSubDir = 'stride_map_tiles';

  // Reuse a single provider instance across the app lifecycle so that the
  // underlying Dio/store objects are not recreated on every widget rebuild.
  static CachedTileProvider? _provider;

  // Kept separately so clearCache() can call store.clean() without needing
  // a getter on CachedTileProvider.
  static FileCacheStore? _store;

  /// Initialises the file-system cache store and returns a [CachedTileProvider]
  /// ready to be passed to flutter_map's [TileLayer.tileProvider].
  ///
  /// Safe to call multiple times; subsequent calls return the existing instance.
  static Future<CachedTileProvider> getProvider() async {
    if (_provider != null) return _provider!;

    // Use the OS-managed cache directory (automatically cleaned by the system
    // when storage is low; the app does not need to manage eviction manually).
    final cacheDir = await getTemporaryDirectory();
    final tileCachePath = '${cacheDir.path}/$_cacheSubDir';

    _store = FileCacheStore(tileCachePath);
    _provider = CachedTileProvider(
      // Tiles are considered fresh for 30 days. After that, the provider tries
      // to revalidate them on the next request but still serves the stale tile
      // if the network is unavailable (offline-first behaviour).
      maxStale: const Duration(days: 30),
      store: _store!,
    );

    return _provider!;
  }

  /// Deletes all cached map tiles from disk.
  ///
  /// Call this from a "Clear Map Cache" Settings option.
  /// After clearing, a new provider is created on the next [getProvider] call.
  static Future<void> clearCache() async {
    await _store?.clean();
    _provider = null; // Force re-initialisation on next use
    _store = null;
  }
}
