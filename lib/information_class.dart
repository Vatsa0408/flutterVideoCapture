import 'package:flutter/foundation.dart';

class InfoVideo {
  final String videoFilePath;
  final double startGPSLat;
  final double startGPSLong;
  final double stopGPSLat;
  final double stopGPSLong;
  final DateTime startTimeStamp;
  final DateTime stopTimeStamp;

  InfoVideo({
    @required this.videoFilePath,
    @required this.startGPSLat,
    @required this.startGPSLong,
    @required this.startTimeStamp,
    @required this.stopGPSLat,
    @required this.stopGPSLong,
    @required this.stopTimeStamp,
  });
}
