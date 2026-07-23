import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../../data/database/app_database.dart';

/// Displays a finished activity's recorded route as a static, view-only map
/// using OpenStreetMap tiles.
///
/// Falls back to a simple placeholder when there aren't enough points to
/// draw a route (e.g. a very short or GPS-less session). This widget never
/// live-updates — it's for reviewing a finished route, not tracking.
class RouteMapView extends StatelessWidget {
  const RouteMapView({super.key, required this.points});

  final List<GpsPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return _RouteMapPlaceholder(hasSinglePoint: points.isNotEmpty);
    }

    final coordinates = [
      for (final point in points) latlong.LatLng(point.latitude, point.longitude),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.coordinates(
              coordinates: coordinates,
              padding: const EdgeInsets.all(32),
            ),
            // View-only: this is a static recap of a finished route, not an
            // interactive or live map.
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.stride',
            ),
            PolylineLayer(
              polylines: [
                Polyline(points: coordinates, strokeWidth: 4, color: colorScheme.primary),
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
      ),
    );
  }
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
      decoration: BoxDecoration(color: colors.tertiaryContainer, borderRadius: BorderRadius.circular(18)),
      child: Stack(
        children: [
          Center(child: Icon(Icons.map_outlined, size: 64, color: colors.onTertiaryContainer.withValues(alpha: 0.55))),
          Positioned(
            top: 12,
            left: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.surface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_off, size: 14, color: colors.primary),
                    const SizedBox(width: 5),
                    Text(
                      hasSinglePoint ? 'NOT ENOUGH GPS DATA' : 'NO ROUTE RECORDED',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
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
