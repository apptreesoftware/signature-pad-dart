library signature_pad_flutter;

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:signature_pad/mark.dart';
import 'package:signature_pad/signature_pad.dart';
import 'package:signature_pad_flutter/src/painter.dart';
import 'package:signature_pad_flutter/src/point.dart';

class SignaturePadController {
  _SignaturePadDelegate _delegate;
  void clear() => _delegate?.clear();
  Future<List<int>> toPng() => _delegate?.getPng();
  bool get hasSignature => _delegate.hasSignature;
  Function onDrawStart;

  SignaturePadController({this.onDrawStart});
}

abstract class _SignaturePadDelegate {
  void clear();
  Future<List<int>> getPng();
  bool get hasSignature;
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
  bool isOnDrawStartCalled;

  SignaturePadState(this._controller, SignaturePadOptions opts) {
    this.opts = opts;
    this.isOnDrawStartCalled = false;
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

    _updates.listen(handleDragUpdate);
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
    handleDrawStartedCallback();

    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;
    var offs = new Offset(x, y);
    RenderBox refBox = context.findRenderObject();
    offs = refBox.globalToLocal(offs);
    strokeBegin(new Point(offs.dx, offs.dy));
    strokeEnd();
  }

  void handleDragUpdate(DragUpdateDetails details) {
    handleDrawStartedCallback();

    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;
    var offs = new Offset(x, y);
    RenderBox refBox = context.findRenderObject();
    offs = refBox.globalToLocal(offs);
    strokeUpdate(new Point(offs.dx, offs.dy));
  }

  void handleDrawStartedCallback() {
    if (!isOnDrawStartCalled) {
      isOnDrawStartCalled = true;
      if (_controller.onDrawStart != null) {
        _controller.onDrawStart();
      }
    }
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
      allPoints.add(new SPPoint(point, size));
    });
  }

  String toDataUrl([String type = 'image/png']) {
    return null;
  }

  void clear() {
    super.clear();
    if (mounted) {
      setState(() {
        isOnDrawStartCalled = false;
        allPoints = [];
      });
    }
  }

  Future<List<int>> getPng() {
    return _currentPainter.getPng();
  }

  bool get hasSignature => _currentPainter.allPoints.isNotEmpty;

  bool _inBounds(double x, double y) {
    var size = this._currentPainter.lastSize;
    return x >= 0 && x < size.width && y >= 0 && y < size.height;
  }
}
