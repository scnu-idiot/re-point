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

  // ⛑️ null-safe: 초기화 실패/권한 거부 시에도 dispose에서 안전
  TextRecognizer? _koRecognizer;    // korean
  TextRecognizer? _latinRecognizer; // latin(영어/숫자)

  bool _isBusy = false;

  // 원문 및 추출 결과
  String _rawText = '';
  String? _storeName;
  String? _address;
  int? _totalAmount;

  /// 화면 비율 기준 스캔영역 (중앙) - UI용
  static const double scanBoxWidthRatio = 0.80;
  static const double scanBoxAspect = 0.75; // width / height

  @override
  void initState() {
    super.initState();
    _initializeCameraAndRecognizer();
  }

  Future<void> _initializeCameraAndRecognizer() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카메라 권한이 필요합니다. 설정에서 허용해주세요.')),
        );
        return;
      }

      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // ⛑️ 안정성 우선: medium (필요시 high로 올려도 OK)
      _cameraController = CameraController(backCamera, ResolutionPreset.medium);
      await _cameraController!.initialize();

      // ⛑️ 인식기 생성 (한/영 각각)
      _koRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
      _latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('초기화 실패: $e')),
      );
    }
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraController == null || _isBusy) return;
    setState(() => _isBusy = true);

    try {
      final picture = await _cameraController!.takePicture();

      // 현재는 전체 이미지로 OCR (원하면 스캔영역 크롭 추가 가능)
      final inputImage = InputImage.fromFilePath(picture.path);

      // ⛑️ 인식기 null 가능 → 각각 시도
      final ko = await _koRecognizer?.processImage(inputImage);
      final la = await _latinRecognizer?.processImage(inputImage);

      if (ko == null && la == null) {
        throw '텍스트 인식기가 초기화되지 않았습니다. (네트워크/Google Play Services 확인)';
      }

      final merged = _mergeRecognized(ko, la);
      final fields = _extractFields(
        ko ?? RecognizedText(text: '', blocks: const []),
        la ?? RecognizedText(text: '', blocks: const []),
        merged,
      );

      setState(() {
        _rawText = merged;
        _storeName = fields.storeName;
        _address = fields.address;
        _totalAmount = fields.totalAmount;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인식 중 오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // === OCR 결과 병합: 라인 기준 합치고 중복 제거 ===
  String _mergeRecognized(RecognizedText? ko, RecognizedText? la) {
    final set = <String>{};
    void collect(RecognizedText? rt) {
      if (rt == null) return;
      for (final b in rt.blocks) {
        for (final l in b.lines) {
          final s = l.text.trim();
          if (s.isNotEmpty) set.add(s);
        }
      }
    }
    collect(ko);
    collect(la);
    return set.join('\n');
  }

  // === 필드 추출 ===
  _Extracted _extractFields(RecognizedText ko, RecognizedText la, String merged) {
    final total = _parseTotal(merged);
    final address = _parseAddress(merged);
    final store = _pickStoreNameFromBlocks(ko)
        ?? _pickStoreNameFromBlocks(la)
        ?? _pickStoreNameFromMerged(merged);
    return _Extracted(storeName: store, address: address, totalAmount: total);
  }

  int? _parseTotal(String text) {
    final totalRegex = RegExp(
      r'(총\s*액|합\s*계|받을\s*금액|결제\s*금액|카드\s*매출|신용\s*매출|최종\s*결제)[^\d]*(\d{1,3}(?:,\d{3})+|\d+)',
      caseSensitive: false,
    );
    final m = totalRegex.firstMatch(text);
    if (m != null) {
      final numStr = m.group(2)!.replaceAll(',', '');
      return int.tryParse(numStr);
    }

    // 키워드가 없으면 하단의 숫자 큰 라인 추정
    final numberLine = RegExp(r'^\s*(\d{1,3}(?:,\d{3})+|\d+)\s*원?\s*$', multiLine: true);
    final matches = numberLine.allMatches(text).toList();
    if (matches.isNotEmpty) {
      final last = matches.last.group(1)!.replaceAll(',', '');
      return int.tryParse(last);
    }
    return null;
  }

  String? _parseAddress(String text) {
    // 도로명 주소 후보
    final addrLine = RegExp(
      r'((?:[가-힣A-Za-z]+\s*(?:도|시))?\s*[가-힣A-Za-z]+\s*(?:시|군|구)\s*[가-힣A-Za-z0-9\-]+(?:로|길|동)\s*\d+[^\n]*)',
      multiLine: true,
    );
    final m = addrLine.firstMatch(text);
    if (m != null) return m.group(1)!.trim();

    // 지번 주소 후보
    final jibun = RegExp(
      r'([가-힣A-Za-z]+\s*(?:시|군|구)\s*[가-힣A-Za-z0-9\-]+\s*(?:동|읍|면)\s*\d+-?\d*\s*(?:번지)?[^\n]*)',
      multiLine: true,
    );
    final m2 = jibun.firstMatch(text);
    return m2?.group(1)?.trim();
  }

  String? _pickStoreNameFromBlocks(RecognizedText rt) {
    final badWords = RegExp(r'(영수증|거래|승인|신용|매출|사업자|면세|부가세|계산서|발행|고객|카드)', caseSensitive: false);
    final addressHints = RegExp(r'(시|군|구|로|길|동|읍|면|번지|호|지번|도로명)');
    final phone = RegExp(r'(TEL|전화|FAX|휴대|010|02\-|\d{2,3}-\d{3,4}-\d{4})', caseSensitive: false);

    for (final b in rt.blocks) {
      for (final l in b.lines) {
        final s = l.text.trim();
        if (s.length < 2 || s.length > 25) continue;
        if (badWords.hasMatch(s)) continue;
        if (addressHints.hasMatch(s)) continue;
        if (phone.hasMatch(s)) continue;

        final digits = RegExp(r'\d').allMatches(s).length;
        if (digits > (s.length * 0.3)) continue;

        return s;
      }
    }
    return null;
  }

  String? _pickStoreNameFromMerged(String text) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final badWords = RegExp(r'(영수증|거래|승인|신용|매출|사업자|면세|부가세|계산서|발행|고객|카드)', caseSensitive: false);
    final addressHints = RegExp(r'(시|군|구|로|길|동|읍|면|번지|호|지번|도로명)');
    final phone = RegExp(r'(TEL|전화|FAX|휴대|010|02\-|\d{2,3}-\d{3,4}-\d{4})', caseSensitive: false);

    for (final s in lines.take(10)) {
      if (s.length < 2 || s.length > 25) continue;
      if (badWords.hasMatch(s)) continue;
      if (addressHints.hasMatch(s)) continue;
      if (phone.hasMatch(s)) continue;

      final digits = RegExp(r'\d').allMatches(s).length;
      if (digits > (s.length * 0.3)) continue;
      return s;
    }
    return null;
  }

  // (선택) 스캔영역 크롭 — 운영 시 프리뷰/실제 사진 매핑 보정 필요
  /*
  Future<String> _cropToScanBox(String filePath) async {
    // pubspec에 image: ^4.x 추가 필요
    final bytes = await File(filePath).readAsBytes();
    final img = decodeImage(bytes)!;

    final screen = MediaQuery.of(context).size;
    final boxW = (screen.width * scanBoxWidthRatio);
    final boxH = boxW / scanBoxAspect;
    final left = (screen.width - boxW) / 2;
    final top  = (screen.height - boxH) / 2;

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
    _koRecognizer?.close();
    _latinRecognizer?.close();
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
              // 1) 카메라 프리뷰(전체)
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

              // 3) 하단 패널 + 촬영 버튼 + 결과
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
                            onTap: _isBusy ? null : _captureAndRecognize,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isBusy ? Colors.grey : const Color(0xFF7A5EF2),
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

                    if (_storeName != null || _address != null || _totalAmount != null || _rawText.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 380),
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.97),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_storeName != null) _kv('상호', _storeName!),
                            if (_address != null) _kv('주소', _address!),
                            if (_totalAmount != null) _kv('합계', '${_totalAmount!} 원'),
                            if (_rawText.isNotEmpty) const Divider(height: 18),
                            if (_rawText.isNotEmpty)
                              Text(
                                _rawText,
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                          ],
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

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 44, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
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
    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()..addRRect(holeRect);
    final overlay = Path.combine(PathOperation.difference, outer, inner);

    final scrimPaint = Paint()..color = dimColor;
    canvas.drawPath(overlay, scrimPaint); // 가운데는 완전 투명

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(holeRect, borderPaint);

    if (showCorners) {
      final p = Paint()
        ..color = borderColor
        ..strokeWidth = cornerWidth
        ..strokeCap = StrokeCap.round;
      final r = holeRect.outerRect;
      final rad = holeRect.blRadiusX;

      // Top-Left
      canvas.drawLine(Offset(r.left, r.top + rad), Offset(r.left, r.top + rad + cornerLength), p);
      canvas.drawLine(Offset(r.left + rad, r.top), Offset(r.left + rad + cornerLength, r.top), p);
      // Top-Right
      canvas.drawLine(Offset(r.right, r.top + rad), Offset(r.right, r.top + rad + cornerLength), p);
      canvas.drawLine(Offset(r.right - rad, r.top), Offset(r.right - rad - cornerLength, r.top), p);
      // Bottom-Left
      canvas.drawLine(Offset(r.left, r.bottom - rad), Offset(r.left, r.bottom - rad - cornerLength), p);
      canvas.drawLine(Offset(r.left + rad, r.bottom), Offset(r.left + rad + cornerLength, r.bottom), p);
      // Bottom-Right
      canvas.drawLine(Offset(r.right, r.bottom - rad), Offset(r.right, r.bottom - rad - cornerLength), p);
      canvas.drawLine(Offset(r.right - rad, r.bottom), Offset(r.right - rad - cornerLength, r.bottom), p);
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

class _Extracted {
  final String? storeName;
  final String? address;
  final int? totalAmount;
  _Extracted({this.storeName, this.address, this.totalAmount});
}
