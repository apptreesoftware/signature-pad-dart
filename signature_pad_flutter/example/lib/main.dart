import 'package:flutter/material.dart';
import 'package:signature_pad/signature_pad.dart';
import 'package:signature_pad_flutter/signature_pad_flutter.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(title: new Text("SignaturePad")),
        body: new SignaturePadExample(),
      ),
    );
  }
}

class SignaturePadExample extends StatefulWidget {
  State<StatefulWidget> createState() {
    return new SignaturePadExampleState();
  }
}

class SignaturePadExampleState extends State<SignaturePadExample> {
  SignaturePadController _padController;
  void initState() {
    _padController = new SignaturePadController();
  }

  Widget build(BuildContext context) {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        new Expanded(
          child: new AspectRatio(
            aspectRatio: 2.0 / 1.0,
            child: new Container(
              decoration: new BoxDecoration(
                  border: new Border.all(color: Colors.black, width: 2.0)),
              child: new SignaturePadWidget(
                _padController,
                new SignaturePadOptions(
                  dotSize: 3.0,
                  minWidth: 1.5,
                  penColor: "#000000",
                ),
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
                onPressed: _handleSavePng, child: new Text("Save as PNG")),
            new MaterialButton(
                onPressed: _handleSaveSvg, child: new Text("Save as SVG")),
          ],
        ),
      ],
    );
  }

  void _handleClear() {
    _padController.clear();
  }

  void _handleSaveSvg() {
    var result = _padController.toSvg();
    print("svg = $result");
  }

  void _handleSavePng() {
    var result = _padController.toPng() as Image;
    print("png = $result");
    Navigator.of(context).push(new MaterialPageRoute(
          builder: (BuildContext context) {
            return new Scaffold(
              appBar: new AppBar(title: new Text("PNG")),
              body: new Image(image: null),
            );
          },
          fullscreenDialog: true,
        ));
  }
}
