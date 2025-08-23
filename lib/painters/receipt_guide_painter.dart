import 'package:flutter/material.dart';

/// 카메라 오버레이: 바깥은 어둡게, 중앙 밴드(옵션), 네 모서리만 둥글게 연결된 프레임
class ReceiptGuidePainter extends CustomPainter {
  final double cornerRadius;
  final double cornerArm;
  final double strokeWidth;
  final double edgeInset;
  final double verticalInsetExtra;
  final Color color;
  final bool showMiddleBand;
  final double bandOpacity;

  ReceiptGuidePainter({
    this.cornerRadius = 28,
    this.cornerArm = 24,
    this.strokeWidth = 4,
    this.edgeInset = 24,
    this.verticalInsetExtra = 32,
    this.color = Colors.white,
    this.showMiddleBand = true,
    this.bandOpacity = 0.18,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final margin = edgeInset;
    final boxW = size.width - margin * 2;
    final boxH = size.height * 0.68;
    final left = margin;
    final top = (size.height - boxH) / 2;
    final r = cornerRadius;

    final rect = Rect.fromLTWH(left, top, boxW, boxH);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // 바깥 스크림(구멍이 중앙 rrect)
    final scrim = Paint()..color = Colors.black.withOpacity(0.45);
    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()..addRRect(rrect);
    canvas.drawPath(Path.combine(PathOperation.difference, outer, inner), scrim);

    // 중앙 밴드(선택)
    if (showMiddleBand) {
      final bandH = boxH * 0.22;
      final bandRect = Rect.fromLTWH(left, top + (boxH - bandH) / 2, boxW, bandH);
      final bandPaint = Paint()..color = Colors.white.withOpacity(bandOpacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bandRect, const Radius.circular(14)),
        bandPaint,
      );
    }

    // 모서리(직선+원호)
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const double L = 24;

    final tlArc = Rect.fromLTWH(left, top, 2 * r, 2 * r);
    final trArc = Rect.fromLTWH(left + boxW - 2 * r, top, 2 * r, 2 * r);
    final blArc = Rect.fromLTWH(left, top + boxH - 2 * r, 2 * r, 2 * r);
    final brArc = Rect.fromLTWH(left + boxW - 2 * r, top + boxH - 2 * r, 2 * r, 2 * r);

    // Top-Left
    canvas.drawLine(Offset(left + r, top), Offset(left + r + L, top), stroke);
    canvas.drawLine(Offset(left, top + r), Offset(left, top + r + L), stroke);
    canvas.drawArc(tlArc, 3.1415926535, 1.5707963268, false, stroke);

    // Top-Right
    canvas.drawLine(Offset(left + boxW - r - L, top), Offset(left + boxW - r, top), stroke);
    canvas.drawLine(Offset(left + boxW, top + r), Offset(left + boxW, top + r + L), stroke);
    canvas.drawArc(trArc, 1.5707963268 * 3, 1.5707963268, false, stroke);

    // Bottom-Left
    canvas.drawLine(Offset(left + r, top + boxH), Offset(left + r + L, top + boxH), stroke);
    canvas.drawLine(Offset(left, top + boxH - r - L), Offset(left, top + boxH - r), stroke);
    canvas.drawArc(blArc, 1.5707963268, 1.5707963268, false, stroke);

    // Bottom-Right
    canvas.drawLine(
        Offset(left + boxW - r - L, top + boxH), Offset(left + boxW - r, top + boxH), stroke);
    canvas.drawLine(Offset(left + boxW, top + boxH - r - L),
        Offset(left + boxW, top + boxH - r), stroke);
    canvas.drawArc(brArc, 0, 1.5707963268, false, stroke);
  }

  @override
  bool shouldRepaint(covariant ReceiptGuidePainter old) =>
      cornerRadius != old.cornerRadius ||
          cornerArm != old.cornerArm ||
          strokeWidth != old.strokeWidth ||
          edgeInset != old.edgeInset ||
          verticalInsetExtra != old.verticalInsetExtra ||
          color != old.color ||
          showMiddleBand != old.showMiddleBand ||
          bandOpacity != old.bandOpacity;
}
