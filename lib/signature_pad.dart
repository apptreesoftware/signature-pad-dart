import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:rate_limit/rate_limit.dart';

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

class SignaturePad {
  final SignaturePadOptions opts;
  final CanvasElement canvas;
  final CanvasRenderingContext2D context;
  final List _data = [];

  List<Mark<num>> points = [];
  double _lastVelocity;
  double _lastWidth;
  bool _isEmpty;
  bool _mouseButtonDown = false;

  List<StreamSubscription> _subscriptions = [];

  SignaturePad(this.canvas, [this.opts = const SignaturePadOptions()])
      : context = canvas.getContext('2d') {
    this.clear();
    this.on();
  }

  String get penColor => opts.penColor;
  double get velocityFilterWeight => opts.velocityFilterWeight;
  double get minWidth => opts.minWidth;
  double get maxWidth => opts.maxWidth;
  Duration get throttle => new Duration(milliseconds: opts.throttle);
  double get dotSize => opts.dotSize ?? minWidth + maxWidth / 2;
  bool get isEmpty => _isEmpty;

  void clear() {
    context.fillStyle = opts.backgroundColor;
    context.clearRect(0, 0, canvas.width, canvas.height);
    context.fillRect(0, 0, canvas.width, canvas.height);
    _data.clear();
    _reset();
    _isEmpty = true;
  }

  void on() {
    this._handleMouseEvents();
    this._handleTouchEvents();
  }

  void off() {
    _subscriptions.forEach((s) => s.cancel());
  }

  void _strokeBegin(Point p) {
    _reset();
    _strokeUpdate(p);
  }

  void _strokeUpdate(Point p) {
    var point = _createMark(p.x, p.y);
    var cw = _addMark(point);
    if (cw != null) {
      _drawCurve(cw.curve, cw.widths.t1, cw.widths.t2);
    }
  }

  void _strokeEnd() {
    var canDrawCurve = this.points.length > 2;
    var point = this.points[0];
    if (!canDrawCurve && point != null) {
      _drawDot(point);
    }
  }

  void _handleMouseEvents() {
    _mouseButtonDown = false;

    _subscriptions.addAll([
      canvas.onMouseDown.listen(_handleMouseDown),
      canvas.onMouseMove
          .transform(new Throttler(this.throttle))
          .listen(_handleMouseMove),
      canvas.onMouseUp.listen(_handleMouseUp),
    ]);
  }

  void _handleTouchEvents() {
    canvas.style.touchAction = 'none';
    canvas.style.setProperty('msTouchAction', 'none');

    _subscriptions.addAll([
      canvas.onTouchStart.listen(_handleTouchStart),
      canvas.onTouchMove
          .transform(new Throttler(this.throttle))
          .listen(_handleTouchMove),
      canvas.onTouchEnd.listen(_handleTouchEnd),
    ]);
  }

  void _handleMouseDown(MouseEvent e) {
    _mouseButtonDown = true;
    print("MOUSE DOWN");
    _strokeBegin(e.client);
  }

  void _handleMouseMove(MouseEvent e) {
    print("MOUSE MOVE down: $_mouseButtonDown");
    if (_mouseButtonDown) {
      _strokeUpdate(e.client);
    }
  }

  void _handleMouseUp(MouseEvent e) {
    _mouseButtonDown = false;
    print("MOUSE UP");
    _strokeEnd();
  }

  void _handleTouchStart(TouchEvent e) {
    var touch = e.changedTouches[0];
    e.preventDefault();
    _strokeBegin(touch.client);
  }

  void _handleTouchMove(TouchEvent e) {
    var touch = e.changedTouches[0];
    e.preventDefault();
    _strokeUpdate(touch.client);
  }

  void _handleTouchEnd(TouchEvent e) {
    var wasCanvasTouched = e.target == canvas;
    if (wasCanvasTouched) {
      e.preventDefault();
      _strokeEnd();
    }
  }

  void _reset() {
    points.clear();
    _lastVelocity = 0.0;
    _lastWidth = (minWidth + maxWidth) / 2;
    context.fillStyle = penColor;
  }

  Mark _createMark(num x, num y, [DateTime time]) {
    var rect = canvas.getBoundingClientRect();
    return new Mark(x - rect.left, y - rect.top, time ?? new DateTime.now());
  }

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

  _Tuple<Point> _calculateCurveControlPoints(Mark s1, Mark s2, Mark s3) {
    var dx1 = s1.x - s2.x;
    var dy1 = s1.y - s2.y;
    var dx2 = s2.x - s3.x;
    var dy2 = s2.y - s3.y;

    var m1 = new Point((s1.x + s2.x) / 2.0, (s1.y + s2.y) / 2.0);
    var m2 = new Point((s2.x + s3.x) / 2.0, (s2.y + s3.y) / 2.0);

    var l1 = sqrt((dx1 * dx1) + (dy1 * dy1));
    var l2 = sqrt((dx2 * dx2) + (dy2 * dy2));

    var dxm = (m1.x - m2.x);
    var dym = (m1.y - m2.y);

    var k = l2 / (l1 + l2);
    var cm = new Point(m2.x + (dxm * k), m2.y + (dym * k));

    var tx = s2.x - cm.x;
    var ty = s2.y - cm.y;

    return new _Tuple<Point>(
        new Point(m1.x + tx, m1.y + ty), new Point(m2.x + tx, m2.y + ty));
  }

  _Tuple<double> _calculateCurveWidths(Bezier curve) {
    var startPoint = curve.startPoint;
    var endPoint = curve.endPoint;

    var velocity =
        (this.velocityFilterWeight * endPoint.velocityFrom(startPoint)) +
            ((1 - this.velocityFilterWeight) * this._lastVelocity);

    var newWidth = this._strokeWidth(velocity);

    var widths = new _Tuple(_lastWidth, newWidth);

    this._lastVelocity = velocity;
    this._lastWidth = newWidth;

    return widths;
  }

  double _strokeWidth(double velocity) {
    return max(maxWidth / (velocity + 1), minWidth);
  }

  void _drawPoint(num x, num y, num size) {
    context.moveTo(x, y);
    context.arc(x, y, size, 0, 2 * PI);
    _isEmpty = false;
  }

  void _drawCurve(Bezier curve, num startWidth, num endWidth) {
    var ctx = context;
    var widthDelta = endWidth - startWidth;
    var drawSteps = curve.length()/*.floor()*/;

    ctx.beginPath();

    for (var i = 0; i < drawSteps; i += 1) {
      // Calculate the Bezier (x, y) coordinate for this step.
      var t = i / drawSteps;
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
      this._drawPoint(x, y, width);
    }

    ctx.closePath();
    ctx.fill();
  }

  void _drawDot(Mark point) {
    var ctx = this.context;
    var width = this.dotSize;

    ctx.beginPath();
    this._drawPoint(point.x, point.y, width);
    ctx.closePath();
    ctx.fill();
  }

  String toDataUrl([String type = 'image/png']) {
    return canvas.toDataUrl(type);
  }
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
