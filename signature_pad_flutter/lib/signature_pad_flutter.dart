library signature_pad_flutter;

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' hide TextStyle;
import 'package:signature_pad/mark.dart';
import 'package:signature_pad/signature_pad.dart';
import 'package:stream_transform/stream_transform.dart';

class SignaturePadController {
  _SignaturePadDelegate _delegate;
  void clear() => _delegate?.clear();
  toPng() => _delegate?.getPng();
}

abstract class _SignaturePadDelegate {
  void clear();
  getPng();
}

class SignaturePadWidget extends StatefulWidget {
  final SignaturePadOptions opts;
  final SignaturePadController controller;
  SignaturePadWidget(this.controller, this.opts);

  State<StatefulWidget> createState() {
    return new SignaturePadState(controller, opts);
  }
}

class SignaturePadState extends State<SignaturePadWidget>
    with SignaturePadBase
    implements _SignaturePadDelegate {
  SignaturePadController _controller;
  List<SPPoint> allPoints = [];

  SignaturePadState(this._controller, SignaturePadOptions opts) {
    this.opts = opts;
    clear();
    on();
  }

  SignaturePadPainter _currentPainter;

  StreamController<DragUpdateDetails> _updateSink =
      new StreamController.broadcast();
  Stream<DragUpdateDetails> get _updates => _updateSink.stream;

  void initState() {
    super.initState();
    _controller._delegate = this;

    _updates
        .transform(throttle(this.throttleDuration))
        .listen(handleDragUpdate);
  }

  Widget build(BuildContext context) {
    _currentPainter = new SignaturePadPainter(allPoints, opts);
    return new ClipRect(
      child: new CustomPaint(
        painter: _currentPainter,
        child: new GestureDetector(
          onTapDown: handleTap,
          onHorizontalDragUpdate: (d) => _updateSink.add(d),
          onVerticalDragUpdate: (d) => _updateSink.add(d),
          onHorizontalDragEnd: handleDragEnd,
          onVerticalDragEnd: handleDragEnd,
          onHorizontalDragStart: handleDragStart,
          onVerticalDragStart: handleDragStart,
          behavior: HitTestBehavior.opaque,
        ),
      ),
    );
  }

  void handleTap(TapDownDetails details) {
    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;
    var offs = new Offset(x, y);
    RenderBox refBox = context.findRenderObject();
    offs = refBox.globalToLocal(offs);
    strokeBegin(new Point(offs.dx, offs.dy));
    strokeEnd();
  }

  void handleDragUpdate(DragUpdateDetails details) {
    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;
    var offs = new Offset(x, y);
    RenderBox refBox = context.findRenderObject();
    offs = refBox.globalToLocal(offs);
    strokeUpdate(new Point(offs.dx, offs.dy));
  }

  void handleDragEnd(DragEndDetails details) {
    strokeEnd();
  }

  void handleDragStart(DragStartDetails details) {
    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;
    var offs = new Offset(x, y);
    RenderBox refBox = context.findRenderObject();
    offs = refBox.globalToLocal(offs);
    strokeBegin(new Point(offs.dx, offs.dy));
  }

  Mark createMark(double x, double y, [DateTime time]) {
    return new Mark(x, y, time ?? new DateTime.now());
  }

  void drawPoint(double x, double y, num size) {
    if (!_inBounds(x, y)) {
      return;
    }
    var point = new Point(x, y);
    setState(() {
      allPoints = new List.from(allPoints)..add(new SPPoint(point, size));
    });
  }

  String toDataUrl([String type = 'image/png']) {
    return null;
  }

  void clear() {
    super.clear();
    if (mounted) {
      setState(() {
        allPoints = [];
      });
    }
  }

  getPng() {
    return _currentPainter.getPng();
  }

  bool _inBounds(double x, double y) {
    var size = this._currentPainter._lastSize;
    return x >= 0 && x < size.width && y >= 0 && y < size.height;
  }
}

class SPPoint {
  final Point point;
  final double size;
  SPPoint(this.point, this.size);
  String toString() => "SPPoint $point $size";
}

class SignaturePadPainter extends CustomPainter {
  final List<SPPoint> allPoints;
  final SignaturePadOptions opts;
  Canvas _lastCanvas;
  Size _lastSize;

  SignaturePadPainter(this.allPoints, this.opts);

  Future<Uint8List> getPng() async {
    if (_lastCanvas == null) {
      return null;
    }
    if (_lastSize == null) {
      return null;
    }
    var recorder = new ui.PictureRecorder();
    var origin = new Offset(0.0, 0.0);
    var paintBounds = new Rect.fromPoints(
        _lastSize.topLeft(origin), _lastSize.bottomRight(origin));
    var canvas = new Canvas(recorder, paintBounds);
    paint(canvas, _lastSize);

    // Add grey text in the bottom-right corner
    if (opts.signatureText != null) {
      var paragraphBuilder = new ui.ParagraphBuilder(
        new ui.ParagraphStyle(
          textDirection: ui.TextDirection.ltr,
        ),
      );
      var style = new TextStyle(color: new Color.fromRGBO(100, 100, 100, 1.0));
      paragraphBuilder.pushStyle(style);
      paragraphBuilder.addText(opts.signatureText);
      paragraphBuilder.pop();
      var paragraph = paragraphBuilder.build();
      paragraph.layout(new ui.ParagraphConstraints(width: _lastSize.width));
      canvas.drawParagraph(
        paragraph,
        new Offset(
          _lastSize.width - paragraph.maxIntrinsicWidth,
          _lastSize.height - paragraph.height,
        ),
      );
    }

    var picture = recorder.endRecording();
    var image =
        picture.toImage(_lastSize.width.round(), _lastSize.height.round());
    ByteData data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data.buffer.asUint8List();
  }

  void paint(Canvas canvas, Size size) {
    _lastCanvas = canvas;
    _lastSize = size;
    for (var point in this.allPoints) {
      var paint = new Paint()..color = colorFromColorString(opts.penColor);
      paint.strokeWidth = 5.0;
      var path = new Path();
      var offset = new Offset(point.point.x, point.point.y);
      path.moveTo(point.point.x, point.point.y);
      var pointSize = point.size;
      if (pointSize == null || pointSize.isNaN) {
        pointSize = opts.dotSize;
      }

      canvas.drawCircle(offset, pointSize, paint);

      paint.style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
  }

  bool shouldRepaint(SignaturePadPainter oldDelegate) {
    return true;
  }
}

Color colorFromColorString(String s) =>
    new _ColorFormatter()._convertColorFromHex(s);

class _ColorFormatter {
  Color _convertColorFromHex(String hexVal) {
    String r = (int.parse(hexVal.substring(1, 3), radix: 16)).toRadixString(10);
    String g = (int.parse(hexVal.substring(3, 5), radix: 16)).toRadixString(10);
    String b = (int.parse(hexVal.substring(5), radix: 16)).toRadixString(10);

    return new Color.fromRGBO(int.parse(r), int.parse(g), int.parse(b), 1.0);
  }

  Color flutterColor(String hexColor) {
    return _convertColorFromHex(hexColor);
  }
}
