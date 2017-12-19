import 'dart:math';

import 'package:signature_pad/bezier.dart';
import 'package:signature_pad/mark.dart';

class SignaturePadOptions {
  final String penColor;
  final String backgroundColor;
  final double minWidth;
  final double maxWidth;
  final int throttle; // ms
  final double velocityFilterWeight;
  final double dotSize;
  const SignaturePadOptions(
      {this.penColor = 'black',
      this.backgroundColor = 'rgba(0,0,0,0)',
      this.minWidth = 0.5,
      this.maxWidth = 2.5,
      this.throttle = 16,
      this.velocityFilterWeight = 0.7,
      this.dotSize});
}

abstract class SignaturePadBase {
  final SignaturePadOptions opts;
  final List _data = [];

  List<Mark> points = [];
  double _lastVelocity;
  double _lastWidth;
  bool isEmpty;

  SignaturePadBase(this.opts) {
    this.clear();
    this.on();
  }

  String get penColor => opts.penColor;
  double get velocityFilterWeight => opts.velocityFilterWeight;
  double get minWidth => opts.minWidth;
  double get maxWidth => opts.maxWidth;
  Duration get throttle => new Duration(milliseconds: opts.throttle);
  double get dotSize => opts.dotSize ?? minWidth + maxWidth / 2;

  void clear() {
    _data.clear();
    reset();
    isEmpty = true;
  }

  void on() {}

  void off() {}

  void strokeBegin(Point p) {
    reset();
    strokeUpdate(p);
  }

  void strokeUpdate(Point p) {
    var point = createMark(p.x, p.y);
    var cw = _addMark(point);
    if (cw != null) {
      drawCurve(cw.curve, cw.widths.t1, cw.widths.t2);
    }
  }

  void strokeEnd() {
    var canDrawCurve = this.points.length > 2;
    var point = this.points[0];
    if (!canDrawCurve && point != null) {
      drawDot(point);
    }
  }

  void reset() {
    points.clear();
    _lastVelocity = 0.0;
    _lastWidth = (minWidth + maxWidth) / 2;
  }

  Mark createMark(double x, double y, [DateTime time]);

  _CurveWidth _addMark(Mark p) {
    points.add(p);
    if (points.length > 2) {
      // To reduce the initial lag make it work with 3 points
      // by copying the first point to the beginning.
      if (points.length == 3) {
        points.insert(0, points[0]);
      }
      var tmp = _calculateCurveControlPoints(points[0], points[1], points[2]);
      var c2 = tmp.t2;
      tmp = _calculateCurveControlPoints(points[1], points[2], points[3]);
      var c3 = tmp.t1;
      var curve = new Bezier(points[1], c2, c3, points[2]);
      var widths = _calculateCurveWidths(curve);

      // Remove the first element from the list,
      // so that we always have no more than 4 points in points array.
      points.removeAt(0);
      return new _CurveWidth(curve, widths);
    }
    return null;
  }

  _Tuple<Point<double>> _calculateCurveControlPoints(
      Mark s1, Mark s2, Mark s3) {
    var dx1 = s1.x - s2.x;
    var dy1 = s1.y - s2.y;
    var dx2 = s2.x - s3.x;
    var dy2 = s2.y - s3.y;

    assert(s1.x is double);
    assert(s1.y is double);
    assert(s2.x is double);
    assert(s2.y is double);
    if (s1.x is! double) {
      print('s1.x is not double');
    }
    if (s1.y is! double) {
      print('s1.y is not double');
    }
    if (s2.x is! double) {
      print('s2.x is not double');
    }
    if (s2.y is! double) {
      print('s2.y is not double');
    }
    var m1 = new Point((s1.x + s2.x) / 2.0, (s1.y + s2.y) / 2.0);
    var m2 = new Point((s2.x + s3.x) / 2.0, (s2.y + s3.y) / 2.0);

    var l1 = sqrt((dx1 * dx1) + (dy1 * dy1));
    var l2 = sqrt((dx2 * dx2) + (dy2 * dy2));

    var dxm = (m1.x - m2.x);
    var dym = (m1.y - m2.y);

    assert(l2 is double);
    var k = l2 / (l1 + l2);
    var cm = new Point(m2.x + (dxm * k), m2.y + (dym * k));

    var tx = s2.x - cm.x;
    var ty = s2.y - cm.y;

    return new _Tuple<Point<double>>(
        new Point(m1.x + tx, m1.y + ty), new Point(m2.x + tx, m2.y + ty));
  }

  _Tuple<double> _calculateCurveWidths(Bezier curve) {
    var startPoint = curve.startPoint;
    var endPoint = curve.endPoint;

    var velocity =
        (this.velocityFilterWeight * endPoint.velocityFrom(startPoint)) +
            ((1 - this.velocityFilterWeight) * this._lastVelocity);
//    print('velocity = $velocity');

    var newWidth = this._strokeWidth(velocity);
//    print('newWidth = $newWidth');

    var widths = new _Tuple(_lastWidth, newWidth);

    this._lastVelocity = velocity;
    this._lastWidth = newWidth;

    return widths;
  }

  double _strokeWidth(double velocity) {
    return max(maxWidth / (velocity + 1.0), minWidth);
  }

  void drawPoint(double x, double y, double size);

  void drawCurve(Bezier curve, double startWidth, double endWidth) {
    if (startWidth.isNaN) {
      print('startWidth is NaN');
    }
    var widthDelta = endWidth - startWidth;
    if (widthDelta.isNaN) {
      print('widthDelta is NaN');
    }
    var drawSteps = curve.length();
    for (var i = 0.0; i < drawSteps; i += 1) {
      // Calculate the Bezier (x, y) coordinate for this step.
      var t = i / drawSteps as double;
      var tt = t * t;
      var ttt = tt * t;
      var u = 1 - t;
      var uu = u * u;
      var uuu = uu * u;

      var x = uuu * curve.startPoint.x;
      x += 3 * uu * t * curve.control1.x;
      x += 3 * u * tt * curve.control2.x;
      x += ttt * curve.endPoint.x;

      var y = uuu * curve.startPoint.y;
      y += 3 * uu * t * curve.control1.y;
      y += 3 * u * tt * curve.control2.y;
      y += ttt * curve.endPoint.y;

      var width = startWidth + (ttt * widthDelta);
      if (ttt.isNaN) {
        print('ttt is NaN');
      }
      if (width.isNaN) {
        print('width is NaN');
      }
      this.drawPoint(x, y, width);
    }
  }

  void drawDot(Mark point) {
    var width = this.dotSize;
    this.drawPoint(point.x, point.y, width);
  }

  String toDataUrl([String type = 'image/png']);
}

class _Tuple<T> {
  final T t1;
  final T t2;
  _Tuple(this.t1, this.t2);
}

class _CurveWidth {
  final Bezier curve;
  final _Tuple<double> widths;
  _CurveWidth(this.curve, this.widths);
}
