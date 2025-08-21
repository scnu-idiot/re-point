// lib/data/history_data.dart
import 'package:flutter/foundation.dart';

enum HistoryKind { purchase, reward }

@immutable
class HistoryRecord {
  final HistoryKind kind;
  final String title;
  final String subtitle;
  final String timeAgo;     // "n시간 전" 같은 표기
  final DateTime? createdAt;

  const HistoryRecord({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.createdAt,
  });
}

/// 구매내역 (상품권/기프티콘 구입 등)
const List<HistoryRecord> demoPurchases = [
  HistoryRecord(
    kind: HistoryKind.purchase,
    title: '지역상품권 구입',
    subtitle: '5,000P 사용',
    timeAgo: '16시간 전',
  ),        ///시간순으로 변경해야하고 구입 및 적립이 이루어진 시간에 맞게 뜨도록 설정해야함
  HistoryRecord(
    kind: HistoryKind.purchase,
    title: '지역상품권 구입',
    subtitle: '10,000P 사용',
    timeAgo: '1일 전',
  ),
  HistoryRecord(
    kind: HistoryKind.purchase,
    title: '지역상품권 구입',
    subtitle: '5,000P 사용',
    timeAgo: '3일 전',
  ),
];

/// 포인트 적립 내역
const List<HistoryRecord> demoRewards = [
  HistoryRecord(
    kind: HistoryKind.reward,
    title: '포인트 적립 +100',
    subtitle: 'QR 스캔 적립',
    timeAgo: '2일 전',
  ),
  HistoryRecord(
    kind: HistoryKind.reward,
    title: '포인트 적립 +200',
    subtitle: 'QR 스캔 적립',
    timeAgo: '3일 전',
  ),
  HistoryRecord(
    kind: HistoryKind.reward,
    title: '포인트 적립 +100',
    subtitle: '추천 보상',
    timeAgo: '3일 전',
  ),
  HistoryRecord(
    kind: HistoryKind.reward,
    title: '포인트 적립 +100',
    subtitle: '첫 로그인 보상',
    timeAgo: '5일 전',
  ),
];

/// 알림 화면에서 한 번에 보여주고 싶을 때 사용할 수 있는 병합 도우미
List<HistoryRecord> mergedHistoryLatestFirst() {
  // createdAt이 없으니 현재는 원본 순서 유지해서 합치기
  return [...demoPurchases, ...demoRewards];
}
