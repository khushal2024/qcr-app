import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_vision/image_vision.dart';
import 'dart:developer' as dev;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<List<Map<String, dynamic>>> getLabels(File file) async {
    var bytes = await file.readAsBytes();
    String jsonLabels = await ImageVision.getTagsOfImage(Uint8List.fromList(bytes.toList()), 0.3);
    var labels = List<Map<String, dynamic>>.from(json.decode(jsonLabels));
    if (kDebugMode){
      dev.log(labels.toString());
    }
    return labels ;
  }

  Future<List<Map<String, dynamic>>> getFaces(File file) async {
    var bytes = await file.readAsBytes();
    String jsonLabels = await ImageVision.detectFacesFromImage(Uint8List.fromList(bytes.toList()));
    var faces = List<Map<String, dynamic>>.from(json.decode(jsonLabels));
    if (kDebugMode){
      dev.log(faces.toString());
    }
    return faces ;
  }
Future<dynamic> recognizeFace(Map<String, dynamic> inputFace, File image) async {
  var faceBytes = await image.readAsBytes();
  if (faceBytes.isNotEmpty) {
    var rec = await ImageVision.recognizeFace(Uint8List.fromList(faceBytes));
    var split = rec["confidence"].toString().split(".");
    var number = split[0];
    if (int.parse(number) < 1) {
      rec["title"] = "face_not_found";
      rec["confidence"] = "0.0";
      return rec;
    } else {
      return rec;
    }
  }

  return {};
}

Future<String> register(String name, Map<String, dynamic> inputFace, File image) async {
  var faceBytes = await image.readAsBytes();
  if (faceBytes.isNotEmpty) {
    var rec = await ImageVision.registerFace(name, Uint8List.fromList(faceBytes));
    dev.log(rec.toString());
    return rec;
  }
  return "error";
}


  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
         (await ImageVision.initial()).toString();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

            if (image != null) {
              var file = File(image.path);
              // get image labels
              await getLabels(file);
              // get image faces
              var faces = await getFaces(file);
              // recognize Face
              var face = await recognizeFace(faces[0], file);
              if (face["title"] == "face_not_found"){
                // if face not found you can register it
                await register(/** You can use any name for face **/ "Amir", faces[0], file);
              } else {
                // if face is detected
                dev.log(face.toString());
              }
            }
          },
          child: const Icon(Icons.photo),
        ),
      ),
    );
  }
}