import 'dart:math';

class Mark extends Point<double> {
  final DateTime time;

  Mark(double x, double y, this.time) : super(x, y);

  int get timeMs => time.millisecondsSinceEpoch;

  double velocityFrom(Mark start) {
    if (this.timeMs == start.timeMs) {
      return 1.0;
    }
    var result = this.distanceTo(start) / (this.timeMs - start.timeMs);
    return result;
  }
}
