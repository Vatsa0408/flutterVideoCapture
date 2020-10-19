import 'dart:async';

import 'package:flutter/material.dart';
import './videoCapture.dart';

class VideoRecorderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VideoRecorderExample(),
    );
  }
}

Future<void> main() async {
  runApp(VideoRecorderApp());
}
