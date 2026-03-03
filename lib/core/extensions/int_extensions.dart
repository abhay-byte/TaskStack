extension IntDurationExtension on int {
  String toFormattedDuration() {
    if (this < 60) {
      return '${this}m';
    }
    final int hours = this ~/ 60;
    final int remainingMins = this % 60;
    if (remainingMins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMins}m';
  }
}
