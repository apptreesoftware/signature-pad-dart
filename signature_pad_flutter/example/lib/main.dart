import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signature_pad/signature_pad.dart';
import 'package:signature_pad_flutter/signature_pad_flutter.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        body: new SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: new SignaturePadExample(),
          ),
        ),
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
    var signaturePad = new SignaturePadWidget(
      _padController,
      new SignaturePadOptions(
        dotSize: 5.0,
        minWidth: 1.5,
        maxWidth: 5.0,
        penColor: "#000000",
      ),
    );
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            new Expanded(
              child: new Container(
                height: 200.0,
                child: new Center(
                  child: new AspectRatio(
                    aspectRatio: 3.0 / 1.0,
                    child: new Container(
                      decoration: new BoxDecoration(border: new Border.all()),
                      child: signaturePad,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              new MaterialButton(
                onPressed: _handleClear,
                child: new Text("Clear"),
                color: Colors.blue,
                textColor: Colors.white,
              ),
              new MaterialButton(
                onPressed: _handleSavePng,
                child: new Text("Save as PNG"),
                color: Colors.red,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleClear() {
    _padController.clear();
  }

  Future _handleSavePng() async {
    var result = await _padController.toPng();
    Navigator.of(context).push(
          new MaterialPageRoute(
            builder: (BuildContext context) {
              return new Scaffold(
                appBar: new AppBar(),
                body: new Container(
                  decoration: new BoxDecoration(border: new Border.all()),
                  padding: new EdgeInsets.all(4.0),
                  margin: new EdgeInsets.all(4.0),
                  child: new Image.memory(result),
                ),
              );
            },
            fullscreenDialog: true,
          ),
        );
  }
}
