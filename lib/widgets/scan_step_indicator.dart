import 'package:flutter/material.dart';
import '../screens/receipt_scan_screen.dart' show CaptureStep;

class ScanStepIndicator extends StatelessWidget {
  final CaptureStep current;
  const ScanStepIndicator({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5E2AD7);

    Widget dot(int idx, String label) {
      final isActive = current.index == idx;
      final isDone = current.index > idx;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isDone
                ? Colors.green
                : isActive
                ? purple
                : Colors.white.withOpacity(0.55),
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
              '${idx + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      );
    }

    Widget bar(bool passed) => Container(
      width: 48,
      height: 2,
      color: passed ? purple : Colors.white38,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          dot(0, '사업자번호'),
          bar(current.index >= 1),
          dot(1, '거래일시'),
          bar(current.index >= 2),
          dot(2, '총 금액'),
        ],
      ),
    );
  }
}
