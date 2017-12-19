library signature_pad_flutter;

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rate_limit/rate_limit.dart';
import 'package:signature_pad/mark.dart';
import 'package:signature_pad/signature_pad.dart';

/// A Calculator.
class SignaturePadWidget extends StatefulWidget {
  final SignaturePadOptions opts;
  SignaturePadWidget(this.opts);

  State<StatefulWidget> createState() {
    return new SignaturePadState(opts);
  }
}

class SignaturePadState extends SignaturePadBase
    with State<SignaturePadWidget> {
  List<SPPoint> allPoints = [];

  SignaturePadState(SignaturePadOptions opts) : super(opts);
  SignaturePadPainter painter;

  StreamController<DragUpdateDetails> _updateSink =
      new StreamController.broadcast();
  Stream<DragUpdateDetails> get _updates => _updateSink.stream;

  void initState() {
    var throttler = new Throttler<dynamic>(this.throttle) as StreamTransformer;
    _updates.transform(throttler).listen(handleDragUpdate);
  }

  Widget build(BuildContext context) {
    return new GestureDetector(
      onTapDown: handleTap,
      onHorizontalDragUpdate: (d) => _updateSink.add(d),
      onVerticalDragUpdate: (d) => _updateSink.add(d),
      onHorizontalDragEnd: handleDragEnd,
      onVerticalDragEnd: handleDragEnd,
      onHorizontalDragStart: handleDragStart,
      onVerticalDragStart: handleDragStart,
      behavior: HitTestBehavior.opaque,
      child: new CustomPaint(
        painter: new SignaturePadPainter(allPoints, opts),
      ),
    );
  }

  void handleTap(TapDownDetails details) {
    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;
    var offs = new Offset(x,y);
    RenderBox refBox = context.findRenderObject();
    offs = refBox.globalToLocal(offs);
    strokeBegin(
        new Point(offs.dx, offs.dy));
    strokeEnd();
  }

  void handleDragUpdate(DragUpdateDetails details) {
    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;
    var offs = new Offset(x,y);
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
    var offs = new Offset(x,y);
    RenderBox refBox = context.findRenderObject();
    offs = refBox.globalToLocal(offs);
    strokeBegin(new Point(offs.dx, offs.dy));
  }

  @override
  Mark createMark(double x, double y, [DateTime time]) {
    return new Mark(x, y, time ?? new DateTime.now());
  }

  @override
  void drawPoint(double x, double y, num size) {
    var point = new Point(x, y);
    setState(() {
      allPoints = new List.from(allPoints)..add(new SPPoint(point, size));
    });
  }

  @override
  String toDataUrl([String type = 'image/png']) {
    return null;
  }

  toDiagnosticsNode({String name, style}) {
    return super.toDiagnosticsNode(name: name, style: style);
  }

  @override
  String toStringShort() {
    return super.toStringShort();
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
  SignaturePadPainter(this.allPoints, this.opts);

  paint(Canvas canvas, Size size) {
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

Color colorFromColorString(String s) => new _ColorFormatter()._convertColorFromHex(s);

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
