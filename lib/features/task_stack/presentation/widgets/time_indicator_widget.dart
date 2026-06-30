import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const double _kPixelsPerHour = 120.0;
const double _kMinuteHeight = _kPixelsPerHour / 60;

/// Live time-of-day indicator. Owns its own ticker so the rest of the
/// stack page does not rebuild every minute — only this small widget.
class TimeIndicatorWidget extends StatefulWidget {
  const TimeIndicatorWidget({super.key});

  @override
  State<TimeIndicatorWidget> createState() => _TimeIndicatorWidgetState();
}

class _TimeIndicatorWidgetState extends State<TimeIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  DateTime _now = DateTime.now();
  int _lastMinute = -1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration _) {
    final now = DateTime.now();
    final minute = now.hour * 60 + now.minute;
    if (minute == _lastMinute) return;
    _lastMinute = minute;
    setState(() => _now = now);
  }

  @override
  void dispose() {
    _ticker.dispose();
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
