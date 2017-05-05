import 'dart:math';

import 'package:signature_pad/mark.dart';

class Bezier {
  final Mark startPoint;
  final Point control1;
  final Point control2;
  final Mark endPoint;
  Bezier(this.startPoint, this.control1, this.control2, this.endPoint);

  num length() {
    var steps = 10;
    var length = 0;
    var px;
    var py;

    for (var i = 0; i <= steps; i += 1) {
      var t = i / steps;
      var cx = this._point(
        t,
        this.startPoint.x,
        this.control1.x,
        this.control2.x,
        this.endPoint.x,
      );
      var cy = _point(
        t,
        this.startPoint.y,
        this.control1.y,
        this.control2.y,
        this.endPoint.y,
      );
      if (i > 0) {
        var xdiff = cx - px;
        var ydiff = cy - py;
        length += sqrt((xdiff * xdiff) + (ydiff * ydiff));
      }
      px = cx;
      py = cy;
    }

    return length;
  }

  num _point(num t, num start, num c1, num c2, num end) {
    return (start * (1.0 - t) * (1.0 - t) * (1.0 - t)) +
        (3.0 * c1 * (1.0 - t) * (1.0 - t) * t) +
        (3.0 * c2 * (1.0 - t) * t * t) +
        (end * t * t * t);
  }
}
