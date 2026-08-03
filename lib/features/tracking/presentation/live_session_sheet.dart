import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../features/settings/controller/settings_controller.dart';
import '../../../models/activity_type.dart';
import '../../../models/finished_session.dart';
import '../controller/tracking_controller.dart';

/// Live-session presentation shown while an activity is being tracked.
///
/// GPS points are recorded in memory. On Finish, an in-memory [FinishedSession]
/// is passed to [onFinished] without saving to the database. The user can then
/// review the summary and decide whether to Save or Discard.
class LiveSessionSheet extends StatefulWidget {
  const LiveSessionSheet({
    super.key,
    required this.activityType,
    required this.onFinished,
  });

  final ActivityType activityType;

  /// Called with the in-memory [FinishedSession] when tracking is finished.
  /// Not called if the user cancels or if no GPS fix was ever received.
  final ValueChanged<FinishedSession> onFinished;

  @override
  State<LiveSessionSheet> createState() => _LiveSessionSheetState();
}

class _LiveSessionSheetState extends State<LiveSessionSheet> {
  TrackingController get _controller => trackingController;

  @override
  void initState() {
    super.initState();
    if (!_controller.isTracking) {
      _controller.start(
        activityType: widget.activityType,
        distanceFilter: settingsController.gpsAccuracy.distanceFilter,
      );
    }
  }

  void _minimize() {
    Navigator.of(context).pop();
  }

  Future<void> _confirmDiscard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard Activity?'),
        content: const Text(
          'Are you sure you want to discard this activity? All tracked data for this session will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('DISCARD'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _controller.cancel();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity discarded.')),
      );
    }
  }

  void _finish() {
    final session = _controller.finish();
    if (session == null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No GPS data was recorded.')),
      );
      return;
    }

    widget.onFinished(session);
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
                        onPressed: _minimize,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        tooltip: 'Minimize live session',
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
                      TextButton(
                        onPressed: _confirmDiscard,
                        child: Text(
                          'Discard',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: colorScheme.surfaceContainerLow),
                      Positioned(
                        left: 16,
                        top: 16,
                        child: _GpsStatusChip(controller: _controller),
                      ),
                      Center(
                        child: _PulseIndicator(
                          icon: widget.activityType.icon,
                          color: colorScheme.primary,
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.activityType.label.toUpperCase(),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatDuration(_controller.elapsed),
                        style: textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Map tracking is off to save battery',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
                              value:
                                  position?.latitude.toStringAsFixed(5) ?? '--',
                              unit: '',
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              label: 'LONGITUDE',
                              value:
                                  position?.longitude.toStringAsFixed(5) ??
                                  '--',
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
                                  ? settingsController.measurementUnit
                                        .speedFromMetersPerSecond(
                                          position.speed,
                                        )
                                        .toStringAsFixed(1)
                                  : '--',
                              unit:
                                  settingsController.measurementUnit.speedLabel,
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              label: 'ACCURACY',
                              value:
                                  position?.accuracy.toStringAsFixed(1) ?? '--',
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
                                _controller.isPaused
                                    ? Icons.play_arrow
                                    : Icons.pause,
                              ),
                              label: Text(
                                _controller.isPaused ? 'Resume' : 'Pause',
                              ),
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

/// Lightweight "live" indicator used in place of a map. Two rings expand
/// and fade out of phase around a static icon, driven by a single
/// [AnimationController] — cheap opacity/scale transforms instead of a
/// map SDK or per-frame [CustomPainter] work.
class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 150,
        height: 150,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                _ring(_controller.value),
                _ring((_controller.value + 0.5) % 1.0),
                child!,
              ],
            );
          },
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(widget.icon, size: 34, color: widget.color),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(double t) {
    return Opacity(
      opacity: (1 - t).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.64 + (0.51 * t),
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color.withValues(alpha: 0.25)),
          ),
        ),
      ),
    );
  }
}