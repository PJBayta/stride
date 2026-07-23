import 'package:flutter/material.dart';

import '../controller/tracking_controller.dart';

/// Live-session presentation shown while an activity is being tracked.
///
/// Map/route rendering and activity persistence are not implemented yet
/// (Phase 4 scope is GPS tracking only); the map area remains a visual
/// placeholder.
class LiveSessionSheet extends StatefulWidget {
  const LiveSessionSheet({
    super.key,
    required this.activityLabel,
    required this.activityIcon,
    required this.onFinish,
  });

  final String activityLabel;
  final IconData activityIcon;
  final VoidCallback onFinish;

  @override
  State<LiveSessionSheet> createState() => _LiveSessionSheetState();
}

class _LiveSessionSheetState extends State<LiveSessionSheet> {
  late final TrackingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TrackingController()..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    _controller.stop();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final position = _controller.currentPosition;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        tooltip: 'Close live session',
                      ),
                      Expanded(
                        child: Text(
                          'Live Session',
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: colorScheme.tertiaryContainer),
                      CustomPaint(
                        painter: _MapPlaceholderPainter(
                          routeColor: colorScheme.primary,
                          lineColor: colorScheme.onTertiaryContainer.withValues(alpha: 0.2),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        child: _GpsStatusChip(controller: _controller),
                      ),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          widget.activityIcon,
                          size: 36,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.activityLabel.toUpperCase(),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatElapsed(_controller.elapsed),
                        style: textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              label: 'LATITUDE',
                              value: position?.latitude.toStringAsFixed(5) ?? '--',
                              unit: '',
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              label: 'LONGITUDE',
                              value: position?.longitude.toStringAsFixed(5) ?? '--',
                              unit: '',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              label: 'SPEED',
                              value: position != null
                                  ? (position.speed * 3.6).toStringAsFixed(1)
                                  : '--',
                              unit: 'km/h',
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              label: 'ACCURACY',
                              value: position?.accuracy.toStringAsFixed(1) ?? '--',
                              unit: 'm',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _controller.isPaused
                                  ? _controller.resume
                                  : _controller.pause,
                              icon: Icon(
                                _controller.isPaused ? Icons.play_arrow : Icons.pause,
                              ),
                              label: Text(_controller.isPaused ? 'Resume' : 'Pause'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _finish,
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Finish'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _formatElapsed(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

class _GpsStatusChip extends StatelessWidget {
  const _GpsStatusChip({required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final String label;
    if (controller.status == TrackingStatus.error) {
      label = controller.errorMessage ?? 'GPS unavailable';
    } else if (controller.isPaused) {
      label = 'GPS paused';
    } else if (controller.currentPosition == null) {
      label = 'Acquiring GPS…';
    } else {
      label = 'GPS live';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gps_fixed, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(text: value),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  const _MapPlaceholderPainter({required this.routeColor, required this.lineColor});

  final Color routeColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (var offset = -size.height; offset < size.width; offset += 32) {
      canvas.drawLine(Offset(offset, 0), Offset(offset + size.height, size.height), linePaint);
    }

    final routePaint = Paint()
      ..color = routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(size.width * .18, size.height * .83)
      ..cubicTo(size.width * .12, size.height * .56, size.width * .72, size.height * .64,
          size.width * .60, size.height * .34)
      ..cubicTo(size.width * .54, size.height * .17, size.width * .81, size.height * .20,
          size.width * .86, size.height * .10);
    canvas.drawPath(route, routePaint);
  }

  @override
  bool shouldRepaint(_MapPlaceholderPainter oldDelegate) =>
      routeColor != oldDelegate.routeColor || lineColor != oldDelegate.lineColor;
}
