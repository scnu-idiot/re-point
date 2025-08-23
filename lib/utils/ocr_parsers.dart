// OCR 파싱 유틸 모듈 (사업자번호, 날짜/시간, 금액)

String? extractValidBizNo(String fullText) {
  final text = fullText.replaceAll('\u00A0', ' ');
  final lines = text.split(RegExp(r'\r?\n')).map((e) => e.trim()).toList();

  final labelRegex = RegExp(
    r'(사업자\s*등록\s*번호|사업자\s*번호|사업자등록번호)\s*[:\-]?\s*([0-9\-\s]{10,14})',
    caseSensitive: false,
  );
  final hyphenRegex = RegExp(r'\b(\d{3})\s*-\s*(\d{2})\s*-\s*(\d{5})\b');
  final plain10Regex = RegExp(r'(?<!\d)(\d{10})(?!\d)');
  final phoneLike = RegExp(r'\b\d{2,3}-\d{3,4}-\d{4}\b');

  final candidates = <_BizCand>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (phoneLike.hasMatch(line)) continue;

    for (final m in labelRegex.allMatches(line)) {
      final raw = m.group(2)!;
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 10 && _isValidBizChecksum(digits)) {
        candidates.add(_BizCand(value: _formatBiz(digits), line: i, score: 100));
      }
    }
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
    for (final m in plain10Regex.allMatches(line)) {
      final digits = m.group(1)!;
      final nearDate = RegExp(r'\b\d{4}[./-]?\d{1,2}[./-]?\d{1,2}\b').hasMatch(line);
      if (_isValidBizChecksum(digits)) {
        final base = 50;
        final penalty = nearDate ? 15 : 0;
        candidates.add(_BizCand(value: _formatBiz(digits), line: i, score: base - penalty));
      }
    }
  }

  if (candidates.isEmpty) return null;

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

bool _isValidBizChecksum(String digits10) {
  final d = digits10.replaceAll(RegExp(r'\D'), '');
  if (d.length != 10) return false;

  final nums = d.split('').map(int.parse).toList();
  const w = [1, 3, 7, 1, 3, 7, 1, 3, 5];
  int sum = 0;
  for (int i = 0; i < 9; i++) {
    sum += nums[i] * w[i];
  }
  sum += (nums[8] * 5) ~/ 10;
  final check = (10 - (sum % 10)) % 10;
  return check == nums[9];
}

String _formatBiz(String digits10) {
  final d = digits10.replaceAll(RegExp(r'\D'), '');
  if (d.length != 10) return digits10;
  return '${d.substring(0, 3)}-${d.substring(3, 5)}-${d.substring(5)}';
}

/// yyyy.MM.dd HH:mm(:ss), yyyymmdd HHmm(ss), yyyy/MM/dd HH:mm(:ss) 등을 +09:00 ISO로 변환
String? extractDateTimeIso(String text) {
  final r1 = RegExp(r'(\d{4})[./-](\d{1,2})[./-](\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?');
  final m1 = r1.firstMatch(text);
  if (m1 != null) {
    final y = m1.group(1)!.padLeft(4, '0');
    final mo = m1.group(2)!.padLeft(2, '0');
    final d = m1.group(3)!.padLeft(2, '0');
    final hh = m1.group(4)!.padLeft(2, '0');
    final mm = m1.group(5)!.padLeft(2, '0');
    final ss = (m1.group(6) ?? '00').padLeft(2, '0');
    return '$y-$mo-$d$hh:$mm:$ss+09:00';
  }
  final r2 = RegExp(r'(\d{4})(\d{2})(\d{2})\s*(\d{2})(\d{2})(\d{2})?');
  final m2 = r2.firstMatch(text);
  if (m2 != null) {
    final y = m2.group(1)!;
    final mo = m2.group(2)!;
    final d = m2.group(3)!;
    final hh = m2.group(4)!;
    final mm = m2.group(5)!;
    final ss = (m2.group(6) ?? '00');
    return '$y-$mo-$d$hh:$mm:$ss+09:00';
  }
  final r3 = RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?');
  final m3 = r3.firstMatch(text);
  if (m3 != null) {
    final y = m3.group(1)!.padLeft(4, '0');
    final mo = m3.group(2)!.padLeft(2, '0');
    final d = m3.group(3)!.padLeft(2, '0');
    final hh = m3.group(4)!.padLeft(2, '0');
    final mm = m3.group(5)!.padLeft(2, '0');
    final ss = (m3.group(6) ?? '00').padLeft(2, '0');
    return '$y-$mo-$d$hh:$mm:$ss+09:00';
  }
  return null;
}

String stripTimezoneForDisplay(String iso) {
  final core = iso.split('+').first;
  return core.replaceFirst('T', ' ');
}

/// 키워드 우선, 없으면 숫자 후보 중 최댓값 반환
int? extractAmountSmart(String text) {
  final kw = RegExp(
    r'(총\s*금액|합계|총액|결제\s*금액|결제금액|받을\s*금액|청구금액)\s*[:\-]?\s*([0-9,]+)\s*원?',
    caseSensitive: false,
  );
  final m1 = kw.allMatches(text).toList();
  if (m1.isNotEmpty) {
    final last = m1.last;
    final digits = (last.group(2) ?? '').replaceAll(',', '');
    final val = int.tryParse(digits);
    if (val != null) return val;
  }

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
