import 'package:flutter/material.dart';

const double _kPixelsPerHour = 120.0;
const double _kMinuteHeight = _kPixelsPerHour / 60;

class TimeIndicatorWidget extends StatelessWidget {
  const TimeIndicatorWidget({super.key, required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final top = (now.hour * 60 + now.minute) * _kMinuteHeight;
    final color = Theme.of(context).colorScheme.primary;

    return Positioned(
      top: top - 6,
      left: 52,
      right: 0,
      child: Row(
        children: [
          // Circle dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          // Line
          Expanded(
            child: Container(height: 2, color: color),
          ),
        ],
      ),
    );
  }
}
