import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../../data/database/app_database.dart';
import '../../../services/tile_cache_service.dart';

/// Displays a finished activity's recorded route as a static, view-only map
/// using OpenStreetMap tiles.
///
/// **Tile caching**: tiles are served by [TileCacheService] which wraps the
/// [TileLayer] with a file-system [CachedTileProvider]. Any tile that was
/// previously downloaded is served from disk without a network request, so the
/// route map renders correctly even when the device is offline.
///
/// Falls back to a simple placeholder when there aren't enough points to
/// draw a route (e.g. a very short or GPS-less session). This widget never
/// live-updates — it's for reviewing a finished route, not tracking.
class RouteMapView extends StatefulWidget {
  const RouteMapView({super.key, required this.points})
      : coordinates = null;

  const RouteMapView.fromCoordinates({super.key, required this.coordinates})
      : points = null;

  final List<GpsPoint>? points;
  final List<latlong.LatLng>? coordinates;

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  /// Resolved asynchronously once; null while the provider is initialising.
  CachedTileProvider? _tileProvider;
  final MapController _mapController = MapController();
  var _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initCache();
  }

  Future<void> _initCache() async {
    final provider = await TileCacheService.getProvider();
    if (mounted) setState(() => _tileProvider = provider);
  }

  void _fitRoute(List<latlong.LatLng> coordinates) {
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: coordinates,
        padding: const EdgeInsets.all(32),
      ),
    );
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom + delta);
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = widget.coordinates ?? [
      for (final point in (widget.points ?? const <GpsPoint>[]))
        latlong.LatLng(point.latitude, point.longitude),
    ];

    if (coordinates.length < 2) {
      return _RouteMapPlaceholder(hasSinglePoint: coordinates.isNotEmpty);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 180,
        child: _tileProvider == null
            // Show a neutral surface while the cache provider is loading.
            // This is typically < 50 ms and invisible in practice.
            ? ColoredBox(color: colorScheme.tertiaryContainer)
            : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCameraFit: CameraFit.coordinates(
                        coordinates: coordinates,
                        padding: const EdgeInsets.all(32),
                      ),
                      onMapReady: () {
                        if (!_isMapReady) {
                          setState(() => _isMapReady = true);
                        }
                      },
                      // Users can inspect a completed route, but this remains
                      // a read-only recap with no navigation or live tracking.
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        // Choosing the tile URL from the inherited theme means
                        // FlutterMap rebuilds with the new tiles immediately when
                        // the app theme changes. The cache keys each source by URL,
                        // so light and dark tiles remain independent.
                        urlTemplate: isDarkMode
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: isDarkMode
                            ? const ['a', 'b', 'c', 'd']
                            : const [],
                        userAgentPackageName: 'com.example.stride',
                        // Lift CARTO's near-black dark tiles toward the
                        // blue-grey tone used by Stride, without changing the
                        // route, endpoint markers, or map controls.
                        tileBuilder: (context, tileWidget, tile) => isDarkMode
                            ? ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  0.62, 0, 0, 0, 38,
                                  0, 0.62, 0, 0, 63,
                                  0, 0, 0.62, 0, 71,
                                  0, 0, 0, 1, 0,
                                ]),
                                child: tileWidget,
                              )
                            : tileWidget,
                        // Cached tile provider: checks disk first, falls back to
                        // network. When offline, only already-cached tiles render;
                        // missing tiles fail gracefully (grey placeholder square)
                        // without crashing the app.
                        tileProvider: _tileProvider!,
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: coordinates,
                            strokeWidth: 4,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: coordinates.first,
                            width: 26,
                            height: 26,
                            child: const _RouteEndpointMarker(
                              color: Colors.green,
                              icon: Icons.trip_origin,
                            ),
                          ),
                          Marker(
                            point: coordinates.last,
                            width: 26,
                            height: 26,
                            child: const _RouteEndpointMarker(
                              color: Colors.red,
                              icon: Icons.sports_score,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_isMapReady)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: _MapControls(
                        onZoomIn: () => _zoomBy(1),
                        onZoomOut: () => _zoomBy(-1),
                        onFitRoute: () => _fitRoute(coordinates),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitRoute,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitRoute;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapControlButton(
            tooltip: 'Zoom in',
            icon: Icons.add,
            onPressed: onZoomIn,
          ),
          Divider(height: 1, color: colors.outlineVariant),
          _MapControlButton(
            tooltip: 'Zoom out',
            icon: Icons.remove,
            onPressed: onZoomOut,
          ),
          Divider(height: 1, color: colors.outlineVariant),
          _MapControlButton(
            tooltip: 'Fit route',
            icon: Icons.fit_screen_outlined,
            onPressed: onFitRoute,
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      visualDensity: VisualDensity.compact,
    ),
  );
}

class _RouteEndpointMarker extends StatelessWidget {
  const _RouteEndpointMarker({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}

class _RouteMapPlaceholder extends StatelessWidget {
  const _RouteMapPlaceholder({required this.hasSinglePoint});

  final bool hasSinglePoint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.map_outlined,
              size: 64,
              color: colors.onTertiaryContainer.withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_off, size: 14, color: colors.primary),
                    const SizedBox(width: 5),
                    Text(
                      hasSinglePoint
                          ? 'NOT ENOUGH GPS DATA'
                          : 'NO ROUTE RECORDED',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
