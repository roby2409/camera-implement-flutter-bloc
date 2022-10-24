import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:my_photos/blocs/camera/camera_bloc.dart';
import 'package:my_photos/screens/camera_screen.dart';
import 'package:my_photos/utils/camera_utils.dart';

class HomeScreen extends StatefulWidget {
  static String route = "/";

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Uint8List>? resultPathTakeMoreThanOne;
  String? resultPathTakeOnce;
  bool resultShowingForMoreThanOnce = false;

  void openCameraScreen({manyPhotosToTake = 1}) {
    FocusScope.of(context).requestFocus(FocusNode()); //remove focus
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => CameraBloc(cameraUtils: CameraUtils()),
            child: CameraScreen(amoutTakeWillBe: manyPhotosToTake),
          ),
        )).then((value) {
      setState(() {
        if (resultShowingForMoreThanOnce ){
          resultPathTakeMoreThanOne = value;
        }else{
          resultPathTakeOnce = value;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Camera with flutter bloc"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Take a photo once",
                    style: TextStyle(fontSize: 20),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        resultShowingForMoreThanOnce = false;
                      });
                      openCameraScreen();
                    },
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Take more than once",
                    style: TextStyle(fontSize: 20),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        resultShowingForMoreThanOnce = true;
                      });
                      openCameraScreen(manyPhotosToTake: 8);
                    },
                  )
                ],
              ),
              resultShowingForMoreThanOnce
                  ? Expanded(
                      child: resultPathTakeMoreThanOne != null
                          ? new ListView.builder(
                              itemCount: resultPathTakeMoreThanOne!.length,
                              itemBuilder: (BuildContext context, int index) {
                                return resultListMoreThanOne(context,
                                    resultPathTakeMoreThanOne![index], index);
                              })
                          : SizedBox())
                  : Expanded(
                      child: resultPathTakeOnce != null
                          ? Container(
                              width: double.infinity,
                              child: Image.file(File(resultPathTakeOnce!),
                                  fit: BoxFit.cover))
                          : SizedBox()),
            ],
          ),
        ));
  }

  Widget resultListMoreThanOne(
      BuildContext context, Uint8List image, int indexFromList) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Card(
          child: new Column(
            children: <Widget>[
              new Row(
                children: <Widget>[
                  new Container(
                    child: new Image.memory(
                      image,
                      height: 60.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  new Container(
                    padding: EdgeInsets.only(left: 15.0),
                    child: new Text('Photo index for $indexFromList'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
