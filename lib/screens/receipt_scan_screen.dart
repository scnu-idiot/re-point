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

  /// 화면 비율 기준 스캔영역 (중앙)
  /// width = 화면 가로의 80%, height = width / 0.75 (세로로 길쭉)
  static const double scanBoxWidthRatio = 0.80;
  static const double scanBoxAspect = 0.75; // width / height

  @override
  void initState() {
    super.initState();
    _initializeCameraAndRecognizer();
  }

  Future<void> _initializeCameraAndRecognizer() async {
    await Permission.camera.request();
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _cameraController = CameraController(backCamera, ResolutionPreset.high);
    await _cameraController!.initialize();

    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    if (mounted) setState(() {});
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraController == null || _isBusy) return;
    setState(() => _isBusy = true);

    final picture = await _cameraController!.takePicture();

    // 현재는 전체 이미지로 OCR
    final inputImage = InputImage.fromFilePath(picture.path);

    // --- ✅ 스캔박스만 인식하려면 ---
    // 1) 아래 _cropToScanBox() 구현 (image 패키지 사용)
    // 2) cropped 파일을 InputImage로 전달
    // final croppedPath = await _cropToScanBox(picture.path);
    // final inputImage = InputImage.fromFilePath(croppedPath);

    final recognizedText = await _textRecognizer.processImage(inputImage);

    setState(() {
      _recognizedText = recognizedText.text;
      _isBusy = false;
    });
  }

  /// TODO: crop to scan box (원하면 활성화)
  /// - pubspec에 image: ^4.x 추가
  /// - 프리뷰/실제 사진 종횡비·회전 매핑 필요(운영 시 매트릭스 계산 권장)
  /*
  Future<String> _cropToScanBox(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final img = decodeImage(bytes)!; // package:image/image.dart

    final screen = MediaQuery.of(context).size;
    final boxW = (screen.width * scanBoxWidthRatio);
    final boxH = boxW / scanBoxAspect;
    final left = (screen.width - boxW) / 2;
    final top  = (screen.height - boxH) / 2;

    // 단순 비율 매핑(프리뷰/실사진 종횡비 차이 있을 수 있음)
    final scaleX = img.width / screen.width;
    final scaleY = img.height / screen.height;

    final cropLeft = (left * scaleX).round().clamp(0, img.width - 1);
    final cropTop  = (top  * scaleY).round().clamp(0, img.height - 1);
    final cropW    = (boxW * scaleX).round().clamp(1, img.width - cropLeft);
    final cropH    = (boxH * scaleY).round().clamp(1, img.height - cropTop);

    final cropped = copyCrop(img, x: cropLeft, y: cropTop, width: cropW, height: cropH);
    final outPath = filePath.replaceFirst('.jpg', '_crop.jpg');
    await File(outPath).writeAsBytes(encodeJpg(cropped, quality: 95));
    return outPath;
  }
  */

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenW = constraints.maxWidth;
          final screenH = constraints.maxHeight;

          final boxW = screenW * scanBoxWidthRatio;
          final boxH = boxW / scanBoxAspect;
          final boxLeft = (screenW - boxW) / 2;
          final boxTop  = (screenH - boxH) / 2;
          final scanRect = Rect.fromLTWH(boxLeft, boxTop, boxW, boxH);

          return Stack(
            children: [
              // 1) 카메라 프리뷰: 전체 화면
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              ),

              // 2) 반투명 오버레이(바깥만) + 가운데 투명 스캔창
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScanOverlayPainter(
                    holeRect: RRect.fromRectXY(scanRect, 16, 16),
                    dimColor: Colors.black.withOpacity(0.55),
                    borderColor: Colors.white,
                    borderWidth: 3,
                    showCorners: true,
                    cornerLength: 22,
                    cornerWidth: 4,
                  ),
                ),
              ),

              // 3) 하단 패널 + 촬영 버튼
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '15',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: ' 포인트 적립 가능',
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
                              padding: const EdgeInsets.all(10),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_recognizedText.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 360),
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _recognizedText,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 반투명 스크림(바깥) + 가운데 구멍(완전 투명) + 테두리/코너
class _ScanOverlayPainter extends CustomPainter {
  final RRect holeRect;
  final Color dimColor;
  final Color borderColor;
  final double borderWidth;
  final bool showCorners;
  final double cornerLength;
  final double cornerWidth;

  _ScanOverlayPainter({
    required this.holeRect,
    required this.dimColor,
    required this.borderColor,
    required this.borderWidth,
    this.showCorners = true,
    this.cornerLength = 20,
    this.cornerWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 바깥 영역만 칠하기: 전체 - 스캔박스
    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()..addRRect(holeRect);
    final overlay = Path.combine(PathOperation.difference, outer, inner);

    final scrimPaint = Paint()..color = dimColor;
    canvas.drawPath(overlay, scrimPaint); // 가운데는 완전 투명하게 남음

    // 스캔 박스 테두리
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(holeRect, borderPaint);

    // 코너 강조선
    if (showCorners) {
      final cPaint = Paint()
        ..color = borderColor
        ..strokeWidth = cornerWidth
        ..strokeCap = StrokeCap.round;

      final r = holeRect.outerRect;
      final rad = holeRect.blRadiusX;

      // Top-Left
      canvas.drawLine(Offset(r.left, r.top + rad), Offset(r.left, r.top + rad + cornerLength), cPaint);
      canvas.drawLine(Offset(r.left + rad, r.top), Offset(r.left + rad + cornerLength, r.top), cPaint);
      // Top-Right
      canvas.drawLine(Offset(r.right, r.top + rad), Offset(r.right, r.top + rad + cornerLength), cPaint);
      canvas.drawLine(Offset(r.right - rad, r.top), Offset(r.right - rad - cornerLength, r.top), cPaint);
      // Bottom-Left
      canvas.drawLine(Offset(r.left, r.bottom - rad), Offset(r.left, r.bottom - rad - cornerLength), cPaint);
      canvas.drawLine(Offset(r.left + rad, r.bottom), Offset(r.left + rad + cornerLength, r.bottom), cPaint);
      // Bottom-Right
      canvas.drawLine(Offset(r.right, r.bottom - rad), Offset(r.right, r.bottom - rad - cornerLength), cPaint);
      canvas.drawLine(Offset(r.right - rad, r.bottom), Offset(r.right - rad - cornerLength, r.bottom), cPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter old) =>
      old.holeRect != holeRect ||
          old.dimColor != dimColor ||
          old.borderColor != borderColor ||
          old.borderWidth != borderWidth ||
          old.showCorners != showCorners ||
          old.cornerLength != cornerLength ||
          old.cornerWidth != cornerWidth;
}
