import 'package:flutter/rendering.dart';

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