import 'dart:convert';
import 'package:flutter/material.dart';
// 🔌 나중에 백엔드 연결 시 주석 해제
// import 'package:http/http.dart' as http;
// import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // ===== 더미 데이터 (화면 확인용) =====
  // 구매내역: 포인트로 상품권/기프티콘 구입
  List<_HistoryItem> purchases = const [
    _HistoryItem(
      type: _HistoryType.purchase,
      title: '지역상품권 구입',
      subtitle: '5,000P 사용',
      timeAgo: '16시간 전',
    ),
    _HistoryItem(
      type: _HistoryType.purchase,
      title: '지역상품권 구입',
      subtitle: '10,000P 사용',
      timeAgo: '1일 전',
    ),
    _HistoryItem(
      type: _HistoryType.purchase,
      title: '지역상품권 구입',
      subtitle: '5,000P 사용',
      timeAgo: '3일 전',
    ),
  ];

  // 포인트 적립 내역
  List<_HistoryItem> rewards = const [
    _HistoryItem(
      type: _HistoryType.reward,
      title: '포인트 적립 +100',
      subtitle: 'QR 스캔 적립',
      timeAgo: '2일 전',
    ),
    _HistoryItem(
      type: _HistoryType.reward,
      title: '포인트 적립 +100',
      subtitle: '추천 보상',
      timeAgo: '3일 전',
    ),
    _HistoryItem(
      type: _HistoryType.reward,
      title: '포인트 적립 +100',
      subtitle: '첫 로그인 보상',
      timeAgo: '5일 전',
    ),
  ];

  bool loading = false; // 🔌 연동 시 로딩 제어
  String? error;        // 🔌 연동 시 에러 메시지

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    // 🔌 초기 로딩 시 서버호출 넣고 싶으면 주석 해제
    // _fetchAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // =======================
  // 🔌 백엔드 연동 자리 (나중에 주석 해제)
  // =======================
  /*
  Future<void> _fetchAll() async {
    setState(() { loading = true; error = null; });

    try {
      // 1) Firebase ID 토큰
      // final token = await FirebaseAuth.instance.currentUser!.getIdToken();

      // 2) 구매내역 요청
      // final res1 = await http.get(
      //   Uri.parse('https://api.your.app/history/purchases'),
      //   headers: {'Authorization': 'Bearer $token'},
      // );

      // 3) 포인트 적립내역 요청
      // final res2 = await http.get(
      //   Uri.parse('https://api.your.app/history/rewards'),
      //   headers: {'Authorization': 'Bearer $token'},
      // );

      // if (res1.statusCode == 200 && res2.statusCode == 200) {
      //   final pJson = json.decode(res1.body) as List<dynamic>;
      //   final rJson = json.decode(res2.body) as List<dynamic>;
      //
      //   setState(() {
      //     purchases = pJson.map((e) => _HistoryItem.fromJson(e, _HistoryType.purchase)).toList();
      //     rewards   = rJson.map((e) => _HistoryItem.fromJson(e, _HistoryType.reward)).toList();
      //     loading = false;
      //   });
      // } else {
      //   setState(() {
      //     error = '서버 오류: ${res1.statusCode}/${res2.statusCode}';
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

  // 🔄 탭별 새로고침(풀투리프레시)
  Future<void> _onRefresh() async {
    // 🔌 연동 시 서버 재호출
    // await _fetchAll();

    // 지금은 UI만 갱신
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final divider = Container(height: 1, color: Colors.black12);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          '이용내역',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              TabBar(
                controller: _tab,
                labelPadding: const EdgeInsets.symmetric(vertical: 8),
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.black26,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3, color: Colors.black87),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: '구매내역'),
                  Tab(text: '포인트 적립'),
                ],
              ),
              divider,
            ],
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
          ? _ErrorView(message: error!, onRetry: _onRefresh)
          : TabBarView(
        controller: _tab,
        children: [
          // 구매내역 탭
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: _HistoryList(items: purchases),
          ),
          // 포인트 적립 탭
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: _HistoryList(items: rewards),
          ),
        ],
      ),
    );
  }
}

/// 공통 리스트 위젯
class _HistoryList extends StatelessWidget {
  final List<_HistoryItem> items;

  const _HistoryList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          _EmptyView(text: '내역이 없습니다.'),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final it = items[index];
        final icon = it.type == _HistoryType.purchase
            ? Icons.card_giftcard   // 🎁 상품권/기프티콘
            : Icons.qr_code_scanner; // QR 적립

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.black12,
              child: Icon(icon, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  if (it.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      it.subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              it.timeAgo,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _HistoryType { purchase, reward }

class _HistoryItem {
  final _HistoryType type;
  final String title;
  final String? subtitle;
  final String timeAgo;

  const _HistoryItem({
    required this.type,
    required this.title,
    required this.timeAgo,
    this.subtitle,
  });

  // 🔌 나중에 서버 JSON 파싱할 때 사용 (스키마 예시)
  factory _HistoryItem.fromJson(Map<String, dynamic> j, _HistoryType type) {
    return _HistoryItem(
      type: type,
      title: j['title'] as String,
      subtitle: j['subtitle'] as String?, // ex) '5,000P 사용' / 'QR 스캔 적립'
      timeAgo: j['timeAgo'] as String,    // ex) '1일 전'
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String text;
  const _EmptyView({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.black45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
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
