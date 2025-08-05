import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  CameraController? _cameraController;
  late final TextRecognizer _textRecognizer;
  String _recognizedText = '';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _initializeCameraAndRecognizer();
  }

  Future<void> _initializeCameraAndRecognizer() async {
    await Permission.camera.request();
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back);

    _cameraController = CameraController(backCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();

    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    if (mounted) setState(() {});
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraController == null || _isBusy) return;
    setState(() => _isBusy = true);

    final picture = await _cameraController!.takePicture();
    final inputImage = InputImage.fromFilePath(picture.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    setState(() {
      _recognizedText = recognizedText.text;
      _isBusy = false;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  ScanCorner(position: 'topLeft'),
                  ScanCorner(position: 'topRight'),
                ],
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  ScanCorner(position: 'bottomLeft'),
                  ScanCorner(position: 'bottomRight'),
                ],
              ),
            ],
          ),

          // 포인트 적립 + OCR 버튼
          Positioned(
            bottom: 50,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "15",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: " 포인트 적립 가능",
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _captureAndRecognize,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF7A5EF2),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_recognizedText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_recognizedText, style: const TextStyle(color: Colors.black)),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ScanCorner extends StatelessWidget {
  final String position;
  const ScanCorner({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    const double size = 40;
    BorderRadius radius;

    switch (position) {
      case 'topLeft':
        radius = const BorderRadius.only(topLeft: Radius.circular(16));
        break;
      case 'topRight':
        radius = const BorderRadius.only(topRight: Radius.circular(16));
        break;
      case 'bottomLeft':
        radius = const BorderRadius.only(bottomLeft: Radius.circular(16));
        break;
      case 'bottomRight':
        radius = const BorderRadius.only(bottomRight: Radius.circular(16));
        break;
      default:
        radius = BorderRadius.zero;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: radius,
      ),
    );
  }
}
