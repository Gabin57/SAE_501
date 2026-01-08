import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web; // for platform view registry
import 'package:flutter/material.dart';

class WebCameraView extends StatefulWidget {
  final Function(html.VideoElement) onCameraReady;
  final Function(String) onError;

  const WebCameraView({
    Key? key,
    required this.onCameraReady,
    required this.onError,
  }) : super(key: key);

  @override
  State<WebCameraView> createState() => _WebCameraViewState();
}

class _WebCameraViewState extends State<WebCameraView> {
  late html.VideoElement _videoElement;
  final String _viewType =
      'web-camera-view-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _initializeWebCamera();
  }

  void _initializeWebCamera() async {
    // 1. Create a video element
    _videoElement = html.VideoElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit =
          'cover' // Make sure it fills the container
      ..autoplay = true
      ..muted = true
      ..setAttribute(
        'playsinline',
        'true',
      ); // Important for mobile browsers (iOS Safari)

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoElement,
    );

    // 3. Request camera access
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': 'environment', // Prefer back camera
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      });

      _videoElement.srcObject = stream;

      // Notify parent when video is ready to play
      _videoElement.onCanPlay.listen((_) {
        if (mounted) {
          widget.onCameraReady(_videoElement);
        }
      });
    } catch (e) {
      widget.onError(e.toString());
    }
  }

  @override
  void dispose() {
    // Stop tracks to release camera
    if (_videoElement.srcObject != null) {
      final stream = _videoElement.srcObject as html.MediaStream;
      stream.getTracks().forEach((track) => track.stop());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

Future<List<int>> captureFrame(html.VideoElement video) async {
  final canvas = html.CanvasElement(
    width: video.videoWidth,
    height: video.videoHeight,
  );

  canvas.context2D.drawImage(video, 0, 0);

  // Get data URL
  final dataUrl = canvas.toDataUrl('image/jpeg', 0.8);

  // Convert base64 data URL to bytes
  final base64String = dataUrl.split(',')[1];
  return base64.decode(base64String);
}
