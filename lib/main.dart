import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  List _recognitions;
  ImagePicker imagePicker;

  @override
  void initState() {
    super.initState();
    loadModel();
    imagePicker = ImagePicker();
  }

  //TODO chose image from camera
  _imgFromCamera() async {
    PickedFile pickedFile =
        await imagePicker.getImage(source: ImageSource.camera);
    File image = File(pickedFile.path);
    segmentMobileNet(image);
  }

  //TODO chose image gallery
  _imgFromGallery() async {
    PickedFile pickedFile =
        await imagePicker.getImage(source: ImageSource.gallery);
    File image = File(pickedFile.path);
    segmentMobileNet(image);
  }

  Future loadModel() async {
    Tflite.close();
    try {
      String res;
      res = await Tflite.loadModel(
        model: "assets/deeplabv3_257_mv_gpu.tflite",
        labels: "assets/deeplabv3_257_mv_gpu.txt",
        // useGpuDelegate: true,
      );
      print(res);
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  //TODO perform inference using deeplab model
  Future segmentMobileNet(File image) async {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    var recognitions = await Tflite.runSegmentationOnImage(
      path: image.path,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _image = image;
      _recognitions = recognitions;
    });
    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}");
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];
    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      child: _image == null
          ? Center(
              child: Container(
                  margin: EdgeInsets.only(top: size.height / 2 - 140),
                  child: Icon(
                    Icons.image_rounded,
                    color: Colors.white,
                    size: 100,
                  )))
          : Image.file(_image),
    ));
    //TODO draw points
    if (_recognitions != null) {
      stackChildren.add(Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        child: _image == null
            ? Text('No image selected.')
            : Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        alignment: Alignment.topCenter,
                        image: MemoryImage(_recognitions),
                        fit: BoxFit.fill)),
                child: Opacity(opacity: 0.3, child: Image.file(_image))),
      ));
    }
    //TODO bottom bar code
    stackChildren.add(
      Container(
        height: size.height,
        alignment: Alignment.bottomCenter,
        child: Container(
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RaisedButton(
                onPressed: _imgFromCamera,
                child: Icon(
                  Icons.camera,
                  color: Colors.black,
                ),
                color: Colors.white,
              ),
              RaisedButton(
                onPressed: _imgFromGallery,
                child: Icon(
                  Icons.image,
                  color: Colors.black,
                ),
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        margin: EdgeInsets.only(top: 50),
        color: Colors.black,
        child: Stack(
          children: stackChildren,
        ),
      ),
    );
  }
}
