import 'dart:html';
import 'dart:math';
import 'dart:typed_data';

import 'package:signature_pad/signature_pad.dart';
import 'package:signature_pad/signature_pad_html.dart';

main() {
  var clearButton = querySelector("[data-action=clear]");
  var savePngButton = querySelector("#save-png-button");
  var saveSvgButton = querySelector("#save-svg-button");
  var canvas = querySelector("canvas");
  var opts = new SignaturePadOptions(minWidth: 1.5, maxWidth: 4.0);
  var signaturePad = new SignaturePadHtml(canvas, opts);
  clearButton.onClick.listen((e) => signaturePad.clear());

  savePngButton.onClick.listen((e) {
    download(signaturePad.toDataUrl(), "signature.png");
  });
  saveSvgButton.onClick.listen((e) {
    download(signaturePad.toDataUrl('image/svg+xml'), "signature.svg");
  });

  window.onResize.listen((e) => resizeCanvas(canvas));
  resizeCanvas(canvas);
}

void download(String dataUrl, String filename) {
  var blob = dataUrlToBlob(dataUrl);
  var url = Url.createObjectUrl(blob);

  var a = document.createElement("a");
  a.setAttribute("style", "display: none");
  a.setAttribute("href", url);
  a.setAttribute("download", filename);

  document.body.append(a);
  a.click();

  Url.revokeObjectUrl(url);
}

Blob dataUrlToBlob(String dataUri) {
  const String base64Marker = ';base64,';
  var parts = dataUri.split(base64Marker);
  var contentType = parts[0].split(":")[1];
  var raw = window.atob(parts[1]);
  var rawLength = raw.length;
  var list = Uint8List(rawLength);
  for (var i = 0; i < rawLength; i++) {
    list[i] = raw.codeUnitAt(i);
  }
  return new Blob([list], contentType);
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
