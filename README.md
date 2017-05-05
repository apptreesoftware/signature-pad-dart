# signature_pad for Dart

A Pure Dart implementation of [Signature Pad][signature-pad] by Szymon Nowak

![logo][image]

## Example

```
import 'dart:html';
import 'package:signature_pad/signature_pad.dart`

main() {
  var canvas = querySelector("canvas");
  var opts = new SignaturePadOptions(minWidth: 1.5, maxWidth: 4.0, velocityFilterWeight: 0.7);
  var signaturePad = new SignaturePad(canvas, opts);
}
```

see the `example/` directory for a complete example. (e.g. `pub serve example`)

## Demo

The `example/` directory contains a Dart version of the [JS demo][demo]

[signature-pad]: https://github.com/szimek/signature_pad
[demo]: http://szimek.github.io/signature_pad/
[image]: https://raw.githubusercontent.com/johnpryan/signature-pad-dart/master/doc/signature_pad.png
