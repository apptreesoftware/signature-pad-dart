import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/widgets.dart' hide TextStyle;
import 'package:signature_pad/signature_pad.dart';
import 'package:signature_pad_flutter/src/colors.dart';
import 'package:signature_pad_flutter/src/point.dart';

class SignaturePadPainter extends CustomPainter {
  final List<SPPoint> allPoints;
  final SignaturePadOptions opts;
  Size lastSize;

  SignaturePadPainter(this.allPoints, this.opts);

  Future<Uint8List> getPng() async {
    if (lastSize == null) {
      return null;
    }
    var recorder = new ui.PictureRecorder();
    var origin = new Offset(0.0, 0.0);
    var paintBounds = new Rect.fromPoints(
        lastSize.topLeft(origin), lastSize.bottomRight(origin));
    var canvas = new Canvas(recorder, paintBounds);

    _paintPoints(canvas, lastSize, 0);

    // Add grey text in the bottom-right corner
    if (opts.signatureText != null) {
      var paragraphBuilder = new ui.ParagraphBuilder(
        new ui.ParagraphStyle(
          textDirection: ui.TextDirection.ltr,
        ),
      );
      var style =
          new ui.TextStyle(color: new Color.fromRGBO(100, 100, 100, 1.0));
      paragraphBuilder.pushStyle(style);
      paragraphBuilder.addText(opts.signatureText);
      paragraphBuilder.pop();
      var paragraph = paragraphBuilder.build();
      paragraph.layout(new ui.ParagraphConstraints(width: lastSize.width));
      canvas.drawParagraph(
        paragraph,
        new Offset(
          lastSize.width - paragraph.maxIntrinsicWidth,
          lastSize.height - paragraph.height,
        ),
      );
    }

    var picture = recorder.endRecording();
    var image =
        picture.toImage(lastSize.width.round(), lastSize.height.round());
    ByteData data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data.buffer.asUint8List();
  }

  void paint(Canvas canvas, Size size) {
    lastSize = size;
    _paintPoints(canvas, size, 0);
  }

  void _paintPoints(Canvas canvas, Size size, int startIdx) {
    for (var i = startIdx; i < allPoints.length; i++) {
      var point = this.allPoints[i];
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
