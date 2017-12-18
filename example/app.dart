import 'dart:html';
import 'dart:math';

import 'package:signature_pad/signature_pad.dart';
import 'package:signature_pad/signature_pad_html.dart';

main() {
  var clearButton = querySelector("[data-action=clear]");
  var savePngButton = querySelector("#save-png-button");
  var saveSvgButton = querySelector("#save-svg-button");
  var canvas = querySelector("canvas");
  var opts = new SignaturePadOptions(
      minWidth: 1.5, maxWidth: 4.0);
  var signaturePad = new SignaturePadHtml(canvas, opts);
  clearButton.onClick.listen((e) => signaturePad.clear());

  savePngButton.onClick.listen((e) {
    window.open(signaturePad.toDataUrl(), "signature");
  });
  saveSvgButton.onClick.listen((e) {
    window.open(signaturePad.toDataUrl('image/svg+xml'), "signature");
  });

  window.onResize.listen((e) => resizeCanvas(canvas));
  resizeCanvas(canvas);
}

// Adjust canvas coordinate space taking into account pixel ratio,
// to make it look crisp on mobile devices.
// This also causes canvas to be cleared.
void resizeCanvas(CanvasElement canvas) {
  // When zoomed out to less than 100%, for some very strange reason,
  // some browsers report devicePixelRatio as less than 1
  // and only part of the canvas is cleared then.
  var ratio = max(window.devicePixelRatio ?? 1.0, 1);
  canvas.width = canvas.offsetWidth * ratio;
  canvas.height = canvas.offsetHeight * ratio;
  (canvas.getContext("2d") as CanvasRenderingContext2D).scale(ratio, ratio);
}
