import 'dart:convert';
import 'package:flutter/material.dart';
// 🔌 나중에 서버 연동 시 주석 해제
// import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // ===== 더미 알림 데이터 (이용내역에서 만들어진 이벤트라고 가정) =====
  List<_NotifyItem> items = [
    _NotifyItem(
      title: '영수증 처리가 승인되었습니다.',
      subtitle: 'QR 스캔 적립 +100P',
      timeAgo: '2시간 전',
      kind: _NotifyKind.reward,
    ),
    _NotifyItem(
      title: '지역상품권 구입 완료',
      subtitle: '지역상품권 5,000P 사용',
      timeAgo: '1일 전',
      kind: _NotifyKind.purchase,
    ),
    _NotifyItem(
      title: '추천 보상 적립',
      subtitle: '친구 첫 로그인 보상 +100P',
      timeAgo: '3일 전',
      kind: _NotifyKind.reward,
    ),
  ];

  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    // 🔌 서버 연동 시 초기 로딩
    // _fetchNotifications();
  }

  // ================================
  // 🔌 서버 연동 (나중에 주석 해제)
  // 이용내역(구매/적립) API 두 개에서 가져와 알림 리스트로 합치기
  // ================================
  /*
  Future<void> _fetchNotifications() async {
    setState(() { loading = true; error = null; });

    try {
      // 1) Firebase ID 토큰
      // final token = await FirebaseAuth.instance.currentUser!.getIdToken();

      // 2) 구매내역
      // final pRes = await http.get(
      //   Uri.parse('https://api.your.app/history/purchases'),
      //   headers: {'Authorization': 'Bearer $token'},
      // );

      // 3) 적립내역
      // final rRes = await http.get(
      //   Uri.parse('https://api.your.app/history/rewards'),
      //   headers: {'Authorization': 'Bearer $token'},
      // );

      // if (pRes.statusCode == 200 && rRes.statusCode == 200) {
      //   final pJson = json.decode(pRes.body) as List<dynamic>;
      //   final rJson = json.decode(rRes.body) as List<dynamic>;

      //   // 서버 응답 스키마 예시:
      //   // purchase: {title: "문화상품권 구입", subtitle: "5,000P 사용", createdAt: "2025-08-05T12:00:00Z"}
      //   // reward:   {title: "QR 적립",        subtitle: "+100P",      createdAt: "2025-08-06T01:00:00Z"}

      //   final fromPurchases = pJson.map<_NotifyItem>((e) => _NotifyItem(
      //         title: (e['title'] ?? '구매내역') as String,
      //         subtitle: (e['subtitle'] ?? '') as String,
      //         timeAgo: _formatTime(e['createdAt'] as String?),
      //         kind: _NotifyKind.purchase,
      //         createdAt: DateTime.tryParse(e['createdAt'] ?? ''),
      //       ));

      //   final fromRewards = rJson.map<_NotifyItem>((e) => _NotifyItem(
      //         title: (e['title'] ?? '포인트 적립') as String,
      //         subtitle: (e['subtitle'] ?? '') as String,
      //         timeAgo: _formatTime(e['createdAt'] as String?),
      //         kind: _NotifyKind.reward,
      //         createdAt: DateTime.tryParse(e['createdAt'] ?? ''),
      //       ));

      //   final merged = [...fromPurchases, ...fromRewards].toList()
      //     ..sort((a, b) {
      //       final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      //       final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      //       return tb.compareTo(ta); // 최신순
      //     });

      //   setState(() {
      //     items = merged;
      //     loading = false;
      //   });
      // } else {
      //   setState(() {
      //     error = '서버 오류: ${pRes.statusCode}/${rRes.statusCode}';
      //     loading = false;
      //   });
      // }
    } catch (e) {
      setState(() {
        error = '네트워크 오류: $e';
        loading = false;
      });
    }
  }
  */

  // 🔄 당겨서 새로고침
  Future<void> _onRefresh() async {
    // 🔌 서버 연동 시:
    // await _fetchNotifications();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {});
  }

  // 서버에서 ISO8601 시간 오면 "n시간 전" 등으로 표시
  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          '알림',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
          ? _ErrorView(message: error!, onRetry: _onRefresh)
          : RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final it = items[index];
            final color = it.kind == _NotifyKind.purchase
                ? const Color(0xFF5E2AD7) // 구매: 보라
                : const Color(0xFF219653); // 적립: 초록

            final icon = it.kind == _NotifyKind.purchase
                ? Icons.card_giftcard
                : Icons.check_circle;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (it.subtitle != null && it.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            it.subtitle!,
                            style: const TextStyle(fontSize: 13.5, color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    it.timeAgo,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _NotifyKind { purchase, reward }

class _NotifyItem {
  final String title;
  final String? subtitle;
  final String timeAgo;
  final _NotifyKind kind;

  // 서버 정렬용 (옵션)
  final DateTime? createdAt;

  _NotifyItem({
    required this.title,
    required this.timeAgo,
    required this.kind,
    this.subtitle,
    this.createdAt,
  });
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
