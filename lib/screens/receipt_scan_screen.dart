// lib/screens/receipt_scan_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

enum CaptureStep { bizno, time, amount, review }

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  CameraController? _controller;
  final _textRecognizer = TextRecognizer();
  bool _busy = false;
  bool _torchOn = true;

  CaptureStep _step = CaptureStep.bizno;

  String? _bizno;        // 하이픈 표준화 결과(###-##-#####)
  String? _timeIso;      // 내부 저장(+09:00)
  String? _timeDisplay;  // 화면표시(+09:00 제거)
  int? _amount;
  String _lastRaw = "-";
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadUid();
    _initCamera();
  }

  Future<void> _loadUid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _uid = prefs.getString('userId');
    });
  }

  Future<void> _initCamera() async {
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
      final back = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller!.initialize();

      // 플래시 자동 (가능하면)
      try {
        await _controller!.setFlashMode(FlashMode.auto);
        _torchOn = true;
      } catch (_) {
        _torchOn = false;
      }

      if (!mounted) return;
      setState(() {});
      _announceStep(); // 시작 안내
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카메라 초기화 실패: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  // ===== 단계 안내 =====
  String _stepMessage([CaptureStep? s]) {
    switch (s ?? _step) {
      case CaptureStep.bizno:
        return "사업자번호를 찍어주세요";
      case CaptureStep.time:
        return "거래일시를 찍어주세요";
      case CaptureStep.amount:
        return "총 금액(합계/총액)을 찍어주세요";
      case CaptureStep.review:
        return "인식 결과를 확인하세요";
    }
  }

  Future<void> _showCenterDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 28),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
  }

  void _announceStep([CaptureStep? step]) {
    final msg = _stepMessage(step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCenterDialog(msg);
    });
  }

  // ===== 촬영/인식 =====
  Future<void> _shootAndRecognize() async {
    final cam = _controller;
    if (cam == null || !cam.value.isInitialized || _busy) return;
    setState(() => _busy = true);

    try {
      final file = await cam.takePicture();
      final input = InputImage.fromFile(File(file.path));
      final result = await _textRecognizer.processImage(input);
      final text = result.text;
      _lastRaw = text;

      bool ok = false;

      switch (_step) {
        case CaptureStep.bizno:
          final b = _extractBizNo(text);
          if (b != null) {
            _bizno = b;
            ok = true;
          }
          break;
        case CaptureStep.time:
          final iso = _extractDateTimeIso(text);
          if (iso != null) {
            _timeIso = iso;
            _timeDisplay = _toDisplayNoTZ(iso); // +09:00 제거해서 표시
            ok = true;
          }
          break;
        case CaptureStep.amount:
          final a = _extractAmountSmart(text);
          if (a != null) {
            _amount = a;
            ok = true;
          }
          break;
        case CaptureStep.review:
          ok = true;
          break;
      }

      if (!ok) {
        final failMsg = _step == CaptureStep.bizno
            ? "사업자번호를 인식하지 못했습니다. 다시 시도해주세요."
            : _step == CaptureStep.time
            ? "거래일시를 인식하지 못했습니다. 다시 시도해주세요."
            : "총 금액을 인식하지 못했습니다. 다시 시도해주세요.";
        _showCenterDialog(failMsg);
      }
    } catch (e) {
      _lastRaw = "OCR 실패: $e";
      _showCenterDialog("처리 중 오류가 발생했습니다. 다시 촬영해 주세요.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _nextStep() {
    setState(() {
      if (_step == CaptureStep.bizno) _step = CaptureStep.time;
      else if (_step == CaptureStep.time) _step = CaptureStep.amount;
      else if (_step == CaptureStep.amount) _step = CaptureStep.review;
    });
    _announceStep();
  }

  void _resetStep(CaptureStep s) {
    setState(() {
      _step = s;
      if (s == CaptureStep.bizno) _bizno = null;
      if (s == CaptureStep.time) {
        _timeIso = null;
        _timeDisplay = null;
      }
      if (s == CaptureStep.amount) _amount = null;
    });
    _announceStep(s);
  }

  // ===== 파싱 유틸 =====
  String? _extractBizNo(String text) => extractValidBizNo(text);

  String _toDisplayNoTZ(String iso) {
    final core = iso.split('+').first;
    return core.replaceFirst('T', ' ');
  }

  String? _extractDateTimeIso(String text) {
    // yyyy.mm.dd HH:MM(:SS)
    final r1 = RegExp(r'(\d{4})[./-](\d{1,2})[./-](\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?');
    final m1 = r1.firstMatch(text);
    if (m1 != null) {
      final y = m1.group(1)!.padLeft(4, '0');
      final mo = m1.group(2)!.padLeft(2, '0');
      final d = m1.group(3)!.padLeft(2, '0');
      final hh = m1.group(4)!.padLeft(2, '0');
      final mm = m1.group(5)!.padLeft(2, '0');
      final ss = (m1.group(6) ?? "00").padLeft(2, '0');
      return "$y-$mo-${d}T$hh:$mm:$ss+09:00";
    }
    // yyyymmdd HHMM(SS)
    final r2 = RegExp(r'(\d{4})(\d{2})(\d{2})\s*(\d{2})(\d{2})(\d{2})?');
    final m2 = r2.firstMatch(text);
    if (m2 != null) {
      final y = m2.group(1)!;
      final mo = m2.group(2)!;
      final d = m2.group(3)!;
      final hh = m2.group(4)!;
      final mm = m2.group(5)!;
      final ss = (m2.group(6) ?? "00");
      return "$y-$mo-${d}T$hh:$mm:$ss+09:00";
    }
    // yyyy/mm/dd HH:MM(:SS)
    final r3 = RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?');
    final m3 = r3.firstMatch(text);
    if (m3 != null) {
      final y = m3.group(1)!.padLeft(4, '0');
      final mo = m3.group(2)!.padLeft(2, '0');
      final d = m3.group(3)!.padLeft(2, '0');
      final hh = m3.group(4)!.padLeft(2, '0');
      final mm = m3.group(5)!.padLeft(2, '0');
      final ss = (m3.group(6) ?? "00").padLeft(2, '0');
      return "$y-$mo-${d}T$hh:$mm:$ss+09:00";
    }
    return null;
  }

  int? _extractAmountSmart(String text) {
    // 키워드 기반(가장 마지막 매칭 채택)
    final kw = RegExp(
      r'(총\s*금액|합계|총액|결제\s*금액|결제금액|받을\s*금액|청구금액)\s*[:\-]?\s*([0-9,]+)\s*원?',
      caseSensitive: false,
    );
    final m1 = kw.allMatches(text).toList();
    if (m1.isNotEmpty) {
      final last = m1.last;
      final digits = (last.group(2) ?? "").replaceAll(",", "");
      final val = int.tryParse(digits);
      if (val != null) return val;
    }
    // 숫자 후보 중 최댓값(백 단위 이상)
    final nums = RegExp(r'\b[0-9]{1,3}(?:,[0-9]{3})+\b|\b[0-9]{4,}\b');
    final values = <int>[];
    for (final m in nums.allMatches(text)) {
      final v = int.tryParse(m.group(0)!.replaceAll(',', ''));
      if (v != null) values.add(v);
    }
    if (values.isNotEmpty) {
      values.sort();
      return values.last;
    }
    return null;
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final cam = _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text("영수증 OCR"),
        actions: [
          if (cam != null && cam.value.isInitialized && cam.value.flashMode != FlashMode.off)
            IconButton(
              tooltip: _torchOn ? "손전등 끄기" : "손전등 켜기",
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
              onPressed: () async {
                if (_controller == null) return;
                try {
                  if (_torchOn) {
                    await _controller!.setFlashMode(FlashMode.off);
                    setState(() => _torchOn = false);
                  } else {
                    await _controller!.setFlashMode(FlashMode.torch);
                    setState(() => _torchOn = true);
                  }
                } catch (_) {}
              },
            ),
        ],
      ),
      body: cam == null || !cam.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 상단 굵은 제목
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _currentTitle(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),

          // 카메라 + 정사각형 가이드
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: CameraPreview(cam)),
                // 중앙 정사각형 가이드
                Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: _SquareGuidePainter(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 아래 결과/버튼 패널
          Container(
            width: double.infinity,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCurrentValueRow(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // 다시찍기
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _resetStep(_step),
                        icon: const Icon(Icons.refresh),
                        label: const Text("다시찍기"),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 촬영(인식)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _shootAndRecognize,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("촬영"),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 다음 단계
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _busy
                            ? null
                            : () async {
                          if (_step == CaptureStep.review) {
                            if (_uid == null || _bizno == null || _timeIso == null || _amount == null) {
                              _showCenterDialog("모든 정보를 인식해야 합니다.");
                              return;
                            }
                            try {
                              final earnedPoints = await ApiClient.earnByReceipt(
                                _uid!,
                                receiptId: _bizno!,
                                title: "영수증 인식 적립",
                                detail: "${_timeDisplay!} - ${_amount!}원",
                              );
                              if (!mounted) return;
                              _showCenterDialog("영수증 인식 완료! ${earnedPoints} 포인트 적립!");
                            } catch (e) {
                              debugPrint('Error earning points: $e');
                              if (!mounted) return;
                              _showCenterDialog("포인트 적립에 실패했습니다. 다시 시도해주세요.");
                            }
                          } else {
                            _nextStep();
                          }
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(_step == CaptureStep.review ? "마침" : "다음"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _currentTitle() {
    switch (_step) {
      case CaptureStep.bizno:
        return "사업자번호";
      case CaptureStep.time:
        return "거래일시";
      case CaptureStep.amount:
        return "총 금액";
      case CaptureStep.review:
        return "인식 결과";
    }
  }

  Widget _buildCurrentValueRow() {
    switch (_step) {
      case CaptureStep.bizno:
        return _kvRow("사업자번호", _bizno ?? "-");
      case CaptureStep.time:
        return _kvRow("거래일시", _timeDisplay ?? "-");
      case CaptureStep.amount:
        final disp = _amount != null
            ? "${_amount!.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}원"
            : "-";
        return _kvRow("총 금액", disp);
      case CaptureStep.review:
        final dispAmt = _amount != null
            ? "${_amount!.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}원"
            : "-";
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kvRow("사업자번호", _bizno ?? "-"),
            const SizedBox(height: 6),
            _kvRow("거래일시", _timeDisplay ?? "-", sub: _timeIso != null ? "(ISO: $_timeIso)" : null),
            const SizedBox(height: 6),
            _kvRow("총 금액", dispAmt),
          ],
        );
    }
  }

  Widget _kvRow(String k, String v, {String? sub}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 88, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v, style: const TextStyle(fontSize: 16)),
              if (sub != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 중앙 정사각형 가이드: 바깥은 어둡게, 테두리 흰색
class _SquareGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = Colors.black.withOpacity(0.45);
    final paintBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 전체 영역 어둡게
    final full = Path()..addRect(Offset.zero & size);

    // 중앙 정사각형
    final edge = size.shortestSide;
    final left = (size.width - edge) / 2;
    final top = (size.height - edge) / 2;
    final square = Rect.fromLTWH(left, top, edge, edge);

    // 바깥 어둡게(정사각형만 구멍)
    final hole = Path.combine(PathOperation.difference, full, Path()..addRect(square));
    canvas.drawPath(hole, paintDark);

    // 테두리
    canvas.drawRect(square, paintBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===============================================
/// 사업자등록번호 정규식 + 체크섬 검증 + 문맥 점수화
/// ===============================================

/// 메인 추출 함수: 표준 포맷 "###-##-#####" 반환, 없으면 null
String? extractValidBizNo(String fullText) {
  final text = fullText.replaceAll('\u00A0', ' '); // NBSP 정리
  final lines = text.split(RegExp(r'\r?\n')).map((e) => e.trim()).toList();

  // 라벨(사업자/등록/번호) 붙은 줄 최우선
  final labelRegex = RegExp(
    r'(사업자\s*등록\s*번호|사업자\s*번호|사업자등록번호)\s*[:\-]?\s*([0-9\-\s]{10,14})',
    caseSensitive: false,
  );
  // 하이픈 3-2-5
  final hyphenRegex = RegExp(r'\b(\d{3})\s*-\s*(\d{2})\s*-\s*(\d{5})\b');
  // 붙임 10자리(양옆 숫자 금지)
  final plain10Regex = RegExp(r'(?<!\d)(\d{10})(?!\d)');
  // 전화번호 라인 배제
  final phoneLike = RegExp(r'\b\d{2,3}-\d{3,4}-\d{4}\b');

  final candidates = <_BizCand>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (phoneLike.hasMatch(line)) continue;

    // (A) 라벨형
    for (final m in labelRegex.allMatches(line)) {
      final raw = m.group(2)!;
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 10 && _isValidBizChecksum(digits)) {
        candidates.add(_BizCand(value: _formatBiz(digits), line: i, score: 100));
      }
    }

    // (B) 하이픈형
    for (final m in hyphenRegex.allMatches(line)) {
      final digits = '${m.group(1)}${m.group(2)}${m.group(3)}';
      if (_isValidBizChecksum(digits)) {
        final hasLabelWord = RegExp(r'사업자|등록|번호').hasMatch(line);
        candidates.add(_BizCand(
          value: _formatBiz(digits),
          line: i,
          score: 70 + (hasLabelWord ? 10 : 0),
        ));
      }
    }

    // (C) 10자리 붙임형
    for (final m in plain10Regex.allMatches(line)) {
      final digits = m.group(1)!;
      // 날짜/일자 근처면 감점 (오탐 줄이기)
      final nearDate = RegExp(r'\b\d{4}[./-]?\d{1,2}[./-]?\d{1,2}\b').hasMatch(line);
      if (_isValidBizChecksum(digits)) {
        final base = 50;
        final penalty = nearDate ? 15 : 0;
        candidates.add(_BizCand(
          value: _formatBiz(digits),
          line: i,
          score: base - penalty,
        ));
      }
    }
  }

  if (candidates.isEmpty) return null;

  // 점수 높은 순 → 중복 값 제거 → 첫 값 반환
  candidates.sort((a, b) => b.score.compareTo(a.score));
  final seen = <String>{};
  for (final c in candidates) {
    if (seen.add(c.value)) return c.value;
  }
  return candidates.first.value;
}

class _BizCand {
  final String value;
  final int line;
  final int score;
  _BizCand({required this.value, required this.line, required this.score});
}

/// 체크섬 검증 (국내 사업자등록번호 10자리)
bool _isValidBizChecksum(String digits10) {
  final d = digits10.replaceAll(RegExp(r'\D'), '');
  if (d.length != 10) return false;

  final nums = d.split('').map(int.parse).toList();
  // 가중치: 1,3,7,1,3,7,1,3,5 (앞 9자리)
  const w = [1, 3, 7, 1, 3, 7, 1, 3, 5];
  int sum = 0;
  for (int i = 0; i < 9; i++) {
    sum += nums[i] * w[i];
  }
  sum += (nums[8] * 5) ~/ 10; // 9번째*5의 몫
  final check = (10 - (sum % 10)) % 10;
  return check == nums[9];
}

/// 표준 포맷으로 변환 ###-##-#####
String _formatBiz(String digits10) {
  final d = digits10.replaceAll(RegExp(r'\D'), '');
  if (d.length != 10) return digits10;
  return '${d.substring(0, 3)}-${d.substring(3, 5)}-${d.substring(5)}';
}