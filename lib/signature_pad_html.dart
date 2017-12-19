import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'package:rate_limit/rate_limit.dart';
import 'package:signature_pad/bezier.dart';
import 'package:signature_pad/mark.dart';
import 'package:signature_pad/signature_pad.dart';

class SignaturePadHtml extends SignaturePadBase {
  final CanvasElement canvas;
  final CanvasRenderingContext2D context;

  bool _mouseButtonDown;
  List<StreamSubscription> _subscriptions = [];

  SignaturePadHtml(this.canvas,
      [SignaturePadOptions opts = const SignaturePadOptions()])
      : super(opts),
        context = canvas.getContext('2d'),
        _mouseButtonDown = false;

  void clear() {
    context.fillStyle = opts.backgroundColor;
    context.clearRect(0, 0, canvas.width, canvas.height);
    context.fillRect(0, 0, canvas.width, canvas.height);
    super.clear();
  }

  void on() {
    this._handleMouseEvents();
    this._handleTouchEvents();
  }

  void off() {
    _subscriptions.forEach((s) => s.cancel());
  }

  void _handleMouseEvents() {
    _mouseButtonDown = false;

    _subscriptions.addAll([
      canvas.onMouseDown.listen(handleMouseDown),
      canvas.onMouseMove
          .transform(new Throttler(this.throttle))
          .listen(handleMouseMove),
      canvas.onMouseUp.listen(handleMouseUp),
    ]);
  }

  void _handleTouchEvents() {
    canvas.style.touchAction = 'none';
    canvas.style.setProperty('msTouchAction', 'none');

    _subscriptions.addAll([
      canvas.onTouchStart.listen(handleTouchStart),
      canvas.onTouchMove
          .transform(new Throttler(this.throttle))
          .listen(handleTouchMove),
      canvas.onTouchEnd.listen(handleTouchEnd),
    ]);
  }

  void handleMouseDown(MouseEvent e) {
    _mouseButtonDown = true;
    strokeBegin(doublePoint(e.client));
  }

  void handleMouseMove(MouseEvent e) {
    if (_mouseButtonDown) {
      strokeUpdate(doublePoint(e.client));
    }
  }

  void handleMouseUp(MouseEvent e) {
    _mouseButtonDown = false;
    strokeEnd();
  }

  void handleTouchStart(TouchEvent e) {
    var touch = e.changedTouches[0];
    e.preventDefault();
    strokeBegin(doublePoint(touch.client));
  }

  void handleTouchMove(TouchEvent e) {
    var touch = e.changedTouches[0];
    e.preventDefault();
    strokeUpdate(doublePoint(touch.client));
  }

  void handleTouchEnd(TouchEvent e) {
    var wasCanvasTouched = e.target == canvas;
    if (wasCanvasTouched) {
      e.preventDefault();
      strokeEnd();
    }
  }

  void reset() {
    super.reset();
    context.fillStyle = penColor;
  }

  Mark createMark(double x, double y, [DateTime time]) {
    var rect = canvas.getBoundingClientRect();
    return new Mark(x - rect.left, y - rect.top, time ?? new DateTime.now());
  }

  String toDataUrl([String type = 'image/png']) {
    return canvas.toDataUrl(type);
  }

  void drawPoint(double x, double y, double size) {
    context.moveTo(x, y);
    context.arc(x, y, size, 0, 2 * PI);
    isEmpty = false;
  }

  void drawCurve(Bezier curve, double startWidth, double endWidth) {
    var ctx = context;
    ctx.beginPath();

    super.drawCurve(curve, startWidth, endWidth);

    ctx.closePath();
    ctx.fill();
  }

  void drawDot(Mark point) {
    var ctx = this.context;

    ctx.beginPath();

    super.drawDot(point);

    ctx.closePath();
    ctx.fill();
  }
}

Point<double> doublePoint(Point<num> p) {
  return new Point(p.x + 0.0, p.y + 0.0);
}