import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:video_recorder/models/information_class.dart';

class VideoRecorderExample extends StatefulWidget {
  @override
  _VideoRecorderExampleState createState() {
    return _VideoRecorderExampleState();
  }
}

String videoPath;
String id;

class _VideoRecorderExampleState extends State<VideoRecorderExample> {
  CameraController controller;
  final List<InfoVideo> _infoList = [];

  List<CameraDescription> cameras;
  int selectedCameraIdx;
  //final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // Get the listonNewCameraSelected of available cameras.
    // Then set the first camera as selected.
    availableCameras().then((availableCameras) {
      cameras = availableCameras;

      if (cameras.length > 0) {
        setState(() {
          selectedCameraIdx = 0;
        });

        _onCameraSwitched(cameras[selectedCameraIdx]).then((void v) {});
      }
    }).catchError((err) {
      print('Error: $err.code\nError Message: $err.message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Video Recorder'),
      ),
      body: Container(
        padding: EdgeInsets.all(5),
        height: double.infinity,
        width: double.infinity,
        color: Colors.tealAccent,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 500,
              width: double.infinity,
              child: Card(
                elevation: 10,
                color: Colors.amber,
                child: Row(
                  verticalDirection: VerticalDirection.up,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //verticalDirection: VerticalDirection.up,
                  //crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 300,
                      width: 300,
                      child: _cameraPreviewWidget(),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(
                          color: controller != null &&
                                  controller.value.isRecordingVideo
                              ? Colors.redAccent
                              : Colors.yellow[300],
                          width: 5.0,
                        ),
                      ),
                    ),
                    _cameraTogglesRowWidget(),
                    _captureControlRowWidget(),
                  ],
                ),
              ),
            ),
            Container(
              // height: 400,
              //color: Colors.deepOrange,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.deepOrange,
                  width: 5,
                ),
              ),
              child: _dataList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCameraLensIcon(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return Icons.camera_rear;
      case CameraLensDirection.front:
        return Icons.camera_front;
      case CameraLensDirection.external:
        return Icons.camera;
      default:
        return Icons.device_unknown;
    }
  }

  // Display 'Loading' text when the camera is still loading.
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    if (cameras == null) {
      return Row();
    }

    CameraDescription selectedCamera = cameras[selectedCameraIdx];
    CameraLensDirection _lensDirection = selectedCamera.lensDirection;

    return Container(
        // width: 20.0,
        // height: 20.0,
        // child: Row(
        //     crossAxisAlignment: CrossAxisAlignment.end,
        //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //     mainAxisSize: MainAxisSize.max,
        child: IconButton(
      iconSize: 60.0,
      icon: Icon(_getCameraLensIcon(_lensDirection)),
      color: Colors.black,
      onPressed: _onSwitchCamera,
    )
        // child: RaisedButton.icon(
        //   onPressed: _onSwitchCamera,
        //   icon: Icon(_getCameraLensIcon(lensDirection)),
        //   label: Text(
        //     "${lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1)}",
        //   ),
        //   color: Colors.indigoAccent,
        // ),
        );
  }

  /// Display the control bar with buttons to record videos.
  Widget _captureControlRowWidget() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          IconButton(
            iconSize: 60.0,
            icon: const Icon(Icons.videocam),
            color: Colors.blue,
            onPressed: controller != null &&
                    controller.value.isInitialized &&
                    !controller.value.isRecordingVideo
                ? _onRecordButtonPressed
                : null,
          ),
          IconButton(
            iconSize: 60.0,
            icon: const Icon(Icons.stop),
            color: Colors.red,
            onPressed: controller != null &&
                    controller.value.isInitialized &&
                    controller.value.isRecordingVideo
                ? _onStopButtonPressed
                : null,
          ),
        ],
      ),
    );
  }

  Widget _dataList() {
    return Container(
      height: 630,
      child: ListView.builder(
        itemBuilder: (ctx, index) {
          return Column(
            children: [
              Card(
                child: Column(
                  children: [
                    Text(
                      _infoList[index].videoFilePath,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _infoList[index].id,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete),
                          color: Colors.red,
                          iconSize: 30,
                          onPressed: () => _deleteVideo,
                        ),
                        IconButton(
                          icon: Icon(Icons.open_with),
                          iconSize: 30,
                          color: Colors.purple,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        itemCount: _infoList.length,
      ),
    );
  }

  void _addInfoList(String videoPath, String id) {
    final newInfo = InfoVideo(
      videoFilePath: '$videoPath',
      id: DateTime.now().toString(),
    );

    setState(() {
      _infoList.add(newInfo);
    });
  }

  void _deleteVideo() {
    setState(() {
      final dir = Directory(videoPath);
      dir.deleteSync(recursive: true);
      Fluttertoast.showToast(
          msg: 'Deleted',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.red,
          textColor: Colors.white);
    });
  }

  Future<void> _onCameraSwitched(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }

    controller = CameraController(cameraDescription, ResolutionPreset.max);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (controller.value.hasError) {
        Fluttertoast.showToast(
            msg: 'Camera error ${controller.value.errorDescription}',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.red,
            textColor: Colors.white);
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _onSwitchCamera() {
    selectedCameraIdx =
        selectedCameraIdx < cameras.length - 1 ? selectedCameraIdx + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIdx];

    CameraLensDirection view = selectedCamera.lensDirection;

    _onCameraSwitched(selectedCamera);
    Fluttertoast.showToast(
        msg: '$view triggered',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.black,
        textColor: Colors.white);

    setState(() {
      selectedCameraIdx = selectedCameraIdx;
    });
  }

  void _onRecordButtonPressed() {
    _startVideoRecording().then((String filePath) async {
      if (filePath != null) {
        final startgpsdata = await Location().getLocation();
        // print(startgpsdata.latitude);
        // print(startgpsdata.longitude);
        final starttimestamp = DateTime.now();
        //print(starttimestamp);
        print('$videoPath');

        final startcontents = [
          startgpsdata.latitude,
          startgpsdata.longitude,
          starttimestamp,
          startgpsdata.time,
        ].toString();

        final startdirectory = await getExternalStorageDirectory();
        // For your reference print the AppDoc directory
        //print(startdirectory.path);
        String startTextDirectory = '${startdirectory.path}/Video And Data';
        await Directory(startTextDirectory).create(recursive: true);
        File startTextfilePath =
            new File('$startTextDirectory/$starttimestamp.txt');
        await startTextfilePath.writeAsString('$startcontents');
        Fluttertoast.showToast(
            msg: 'GPS and Timestamp are recorded. Video Recording started',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.black,
            textColor: Colors.white);
      }
    });
  }

  void _onStopButtonPressed() {
    _stopVideoRecording().then((_) async {
      if (mounted) setState(() {});
      Fluttertoast.showToast(
          msg: 'Video, GPS and Timestamp are recorded.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.black,
          textColor: Colors.white);
      final stopgpsdata = await Location().getLocation();
      final stoptimestamp = DateTime.now();

      final stopcontents = [
        stopgpsdata.latitude,
        stopgpsdata.longitude,
        stoptimestamp,
        stopgpsdata.time,
      ];

      final stopdirectory = await getExternalStorageDirectory();
      final String stopTextDirectory = '${stopdirectory.path}/Video And Data';
      //stopTextDirectory = dataDir;
      await Directory(stopTextDirectory).create(recursive: true);
      final File stopTextfilePath =
          new File('$stopTextDirectory/$stoptimestamp.txt');
      await stopTextfilePath.writeAsString('$stopcontents');
      _addInfoList(videoPath, id);
      return File(stopTextDirectory);
    });
  }

  Future<String> _startVideoRecording() async {
    if (!controller.value.isInitialized) {
      Fluttertoast.showToast(
          msg: 'Please wait',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.black,
          textColor: Colors.white);

      return null;
    }

    // Do nothing if a recording is on progress
    if (controller.value.isRecordingVideo) {
      return null;
    }

    final Directory appDirectory = await getExternalStorageDirectory();
    final String videoDirectory = '${appDirectory.path}/Video And Data';
    await Directory(videoDirectory).create(recursive: true);
    final String currentTime = DateTime.now().toString();
    final String filePath = '$videoDirectory/$currentTime.mp4';

    try {
      await controller.startVideoRecording(filePath);
      videoPath = filePath;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  Future<void> _stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error: ${e.code}\nError Message: ${e.description}';
    print(errorText);

    Fluttertoast.showToast(
        msg: 'Error: ${e.code}\n${e.description}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white);
  }
}
