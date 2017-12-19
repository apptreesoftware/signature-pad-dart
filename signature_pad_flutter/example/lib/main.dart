import 'package:flutter/material.dart';
import 'package:signature_pad/signature_pad.dart';
import 'package:signature_pad_flutter/signature_pad_flutter.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        body: new SignaturePadExample(),
      ),
    );
  }
}

class SignaturePadExample extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Center(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new AspectRatio(
            aspectRatio: 2.0 / 1.0,
            child: new Container(
              decoration: new BoxDecoration(
                  border: new Border.all(color: Colors.black, width: 2.0)),
              child: new SignaturePadWidget(
                new SignaturePadOptions(
                  dotSize: 3.0,
                  minWidth: 1.5,
                  penColor: "#000000",
                ),
              ),
            ),
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              new MaterialButton(
                  onPressed: _handleClear, child: new Text("Clear")),
              new MaterialButton(
                  onPressed: _handleSaveSvg, child: new Text("Save as PNG")),
              new MaterialButton(
                  onPressed: _handleSavePng, child: new Text("Save as SVG")),
            ],
          ),
        ],
      ),
    );
  }

  void _handleClear() {
    print('clear');
  }

  void _handleSaveSvg() {
    print('save svg');
  }

  void _handleSavePng() {
    print('save png');
  }
}
