import 'package:flutter/material.dart';

class WebCameraView extends StatelessWidget {
  final Function(dynamic) onCameraReady;
  final Function(String) onError;

  const WebCameraView({
    Key? key,
    required this.onCameraReady,
    required this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Web Camera not supported on this platform'),
    );
  }
}

Future<List<int>> captureFrame(dynamic video) async => [];
