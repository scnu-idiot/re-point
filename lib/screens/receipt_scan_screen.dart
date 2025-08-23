import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../utils/ocr_parsers.dart';
import '../painters/receipt_guide_painter.dart';
import '../widgets/scan_step_indicator.dart';

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

  String? _bizno;        // ###-##-#####
  String? _timeIso;      // +09:00 포함 저장
  String? _timeDisplay;  // 화면 표시는 TZ 제거
  int? _amount;

  @override
  void initState() {
    super.initState();
    _initCamera();
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

      try {
        await _controller!.setFlashMode(FlashMode.auto);
        _torchOn = true;
      } catch (_) {
        _torchOn = false;
      }

      if (!mounted) return;
      setState(() {});
      _announceStep();
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
        return '사업자번호를 찍어주세요';
      case CaptureStep.time:
        return '거래일시를 찍어주세요';
      case CaptureStep.amount:
        return '총 금액(합계/총액)을 찍어주세요';
      case CaptureStep.review:
        return '인식 결과를 확인하세요';
    }
  }

  Future<void> _showCenterDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
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
              child: const Text('확인'),
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

      bool ok = false;

      switch (_step) {
        case CaptureStep.bizno: {
          final b = extractValidBizNo(text);
          if (b != null) {
            setState(() {
              _bizno = b;
            });
            ok = true;
          }
          break;
        }
        case CaptureStep.time: {
          final iso = extractDateTimeIso(text);
          if (iso != null) {
            setState(() {
              _timeIso = iso;
              _timeDisplay = stripTimezoneForDisplay(iso);
            });
            ok = true;
          }
          break;
        }
        case CaptureStep.amount: {
          final a = extractAmountSmart(text);
          if (a != null) {
            setState(() {
              _amount = a;
            });
            ok = true;
          }
          break;
        }
        case CaptureStep.review:
          ok = true;
          break;
      }

      if (!ok) {
        final failMsg = _step == CaptureStep.bizno
            ? '사업자번호를 인식하지 못했습니다. 다시 시도해주세요.'
            : _step == CaptureStep.time
            ? '거래일시를 인식하지 못했습니다. 다시 시도해주세요.'
            : '총 금액을 인식하지 못했습니다. 다시 시도해주세요.';
        _showCenterDialog(failMsg);
      } else {
        // 사용자가 다음 눌러야 이동
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인식 완료! 해당값을 확인 후 다음을 눌러주세요.')),
        );
        }
    } catch (e) {
      _showCenterDialog('처리 중 오류가 발생했습니다. 다시 촬영해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _autoAdvanceOnSuccess() {
    if (!mounted) return;
    if (_step == CaptureStep.bizno) {
      setState(() => _step = CaptureStep.time);
      _announceStep(CaptureStep.time);
    } else if (_step == CaptureStep.time) {
      setState(() => _step = CaptureStep.amount);
      _announceStep(CaptureStep.amount);
    } else if (_step == CaptureStep.amount) {
      setState(() => _step = CaptureStep.review);
      _showCenterDialog('인식이 완료되었습니다. 결과를 확인하세요.');
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

  int _calcEarned() {
    if (_amount == null || _amount! <= 0) return 0;
    return max(1, (_amount! * 0.01).floor()); // 총 금액의 1% (최소 1)
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final cam = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('영수증 OCR'),
        backgroundColor: const Color(0xFFF4EFFF),
        foregroundColor: Colors.black,
        actions: [
          if (cam != null && cam.value.isInitialized && cam.value.flashMode != FlashMode.off)
            IconButton(
              tooltip: _torchOn ? '손전등 끄기' : '손전등 켜기',
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

          // 카메라 + 오버레이
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: CameraPreview(cam)),

                // 반투명 스텝 인디케이터 (카메라 위)
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: ScanStepIndicator(current: _step),
                ),

                // 네 모서리만 둥근 가이드 + 중앙 밴드
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: ReceiptGuidePainter(
                        cornerRadius: 28,
                        cornerArm: 24,
                        strokeWidth: 4,
                        edgeInset: 24,
                        verticalInsetExtra: 32,
                        showMiddleBand: true,
                        bandOpacity: 0.18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 하단 결과/버튼
          Container(
            width: double.infinity,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCurrentValueRow(),
                if (_step == CaptureStep.review && _amount != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '예상 적립: ${_calcEarned()} point',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5E2AD7),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _resetStep(_step),
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시찍기'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _shootAndRecognize,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('촬영'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _busy
                            ? null
                            : () {
                          if (_step == CaptureStep.review) {
                            final earned = _calcEarned();
                            if (earned <= 0) {
                              _showCenterDialog('적립할 금액을 찾지 못했습니다. 총 금액을 먼저 인식해 주세요.');
                              return;
                            }
                            // ✅ 호출부(홈 등)에서 적립 포인트 수신
                            Navigator.pop<int>(context, earned);
                          } else {
                            _nextStep();
                          }
                        },
                        icon: Icon(_step == CaptureStep.review
                            ? Icons.check_circle
                            : Icons.arrow_forward),
                        label: Text(_step == CaptureStep.review ? '적립' : '다음'),
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
        return '사업자번호';
      case CaptureStep.time:
        return '거래일시';
      case CaptureStep.amount:
        return '총 금액';
      case CaptureStep.review:
        return '인식 결과';
    }
  }

  Widget _buildCurrentValueRow() {
    switch (_step) {
      case CaptureStep.bizno:
        return _kvRow('사업자번호', _bizno ?? '-');
      case CaptureStep.time:
        return _kvRow('거래일시', _timeDisplay ?? '-');
      case CaptureStep.amount:
        final disp = _amount != null
            ? '${_amount!.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}원'
            : '-';
        return _kvRow('총 금액', disp);
      case CaptureStep.review:
        final dispAmt = _amount != null
            ? '${_amount!.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}원'
            : '-';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kvRow('사업자번호', _bizno ?? '-'),
            const SizedBox(height: 6),
            _kvRow('거래일시', _timeDisplay ?? '-', sub: _timeIso != null ? '(ISO: $_timeIso)' : null),
            const SizedBox(height: 6),
            _kvRow('총 금액', dispAmt),
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
