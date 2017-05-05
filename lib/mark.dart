import 'dart:math';

class Mark<T extends num> extends Point<T> {
  final DateTime time;

  Mark(T x, T y, this.time) : super(x, y);

  int get timeMs => time.millisecondsSinceEpoch;

  double velocityFrom(Mark<T> start) {
    if (this.time == start.time) {
      return 1.0;
    }
    return this.distanceTo(start) / (this.timeMs - start.timeMs);
  }
}
