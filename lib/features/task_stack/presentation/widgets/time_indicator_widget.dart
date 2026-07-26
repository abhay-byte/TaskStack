import 'dart:async';
import 'package:flutter/material.dart';

const double _kPixelsPerHour = 120.0;
const double _kMinuteHeight = _kPixelsPerHour / 60;

/// Live time-of-day indicator. Uses a 1-second timer instead of a Ticker
/// so the callback fires at 1 Hz instead of 120 Hz, eliminating
/// per-frame overhead on high-refresh-rate displays.
class TimeIndicatorWidget extends StatefulWidget {
  const TimeIndicatorWidget({super.key});

  @override
  State<TimeIndicatorWidget> createState() => _TimeIndicatorWidgetState();
}

class _TimeIndicatorWidgetState extends State<TimeIndicatorWidget> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  int _lastMinute = -1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    final now = DateTime.now();
    final minute = now.hour * 60 + now.minute;
    if (minute == _lastMinute) return;
    _lastMinute = minute;
    if (mounted) setState(() => _now = now);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = (_now.hour * 60 + _now.minute) * _kMinuteHeight;
    final color = Theme.of(context).colorScheme.primary;
    return Positioned(
      top: top - 6,
      left: 52,
      right: 0,
      child: RepaintBoundary(
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(child: Container(height: 2, color: color)),
          ],
        ),
      ),
    );
  }
}
