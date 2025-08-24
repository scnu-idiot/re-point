import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  String? _uid;
  List<HistoryRecord> purchases = [];
  List<HistoryRecord> rewards = [];

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadUidAndHistory();
  }

  Future<void> _loadUidAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getString('userId');
    if (_uid != null) {
      await _loadHistory();
    } else {
      setState(() {
        loading = false;
        error = '사용자 정보를 불러올 수 없습니다.';
      });
    }
  }

  Future<void> _loadHistory() async {
    if (_uid == null) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Fetch point history
      final pointHistory = await ApiClient.fetchPointHistory(_uid!);
      final fetchedRewards = pointHistory.map((e) => HistoryRecord(
        title: e['title'] ?? '',
        subtitle: e['detail'] ?? '',
        timeAgo: _formatTimeAgo(e['created_at']),
        kind: HistoryKind.reward,
      )).toList();

      // Fetch gift card transactions
      final giftCardTransactions = await ApiClient.fetchGiftCardTransactions(_uid!);
      final fetchedPurchases = giftCardTransactions.map((e) => HistoryRecord(
        title: '${e['amount']}원 상품권 교환',
        subtitle: '코드: ${e['code']}',
        timeAgo: _formatTimeAgo(e['issued_at']),
        kind: HistoryKind.purchase,
      )).toList();

      if (mounted) {
        setState(() {
          purchases = fetchedPurchases;
          rewards = fetchedRewards;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load history: $e');
      if (mounted) {
        setState(() {
          loading = false;
          error = '내역을 불러오는데 실패했습니다: ${e.toString()}';
        });
      }
    }
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    // Assuming timestamp is a String in ISO 8601 format or a Map with _seconds and _nanoseconds
    DateTime dateTime;
    if (timestamp is String) {
      dateTime = DateTime.parse(timestamp);
    } else if (timestamp is Map && timestamp.containsKey('_seconds')) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else {
      return '';
    }

    final Duration diff = DateTime.now().difference(dateTime);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}년 전';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}개월 전';
    } else if (diff.inDays > 7) {
      return '${(diff.inDays / 7).floor()}주 전';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // 🔄 풀투리프레시
  Future<void> _onRefresh() async {
    await _loadHistory();
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
          ? _ErrorView(
        message: error!,
        onRetry: () => _onRefresh(),
      )
          : TabBarView(
        controller: _tab,
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: _HistoryList(items: purchases),
          ),
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
  final List<HistoryRecord> items;

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
        final icon = it.kind == HistoryKind.purchase
            ? Icons.card_giftcard
            : Icons.qr_code_scanner;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              child: Icon(icon, color: Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    it.subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              it.timeAgo,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        );
      },
    );
  }
}

/// 에러 뷰
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
            Text(message,
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontSize: 14, color: Colors.red, height: 1.5)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

/// 빈 내역 안내
class _EmptyView extends StatelessWidget {
  final String text;
  const _EmptyView({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text,
          style: const TextStyle(fontSize: 14, color: Colors.black38)),
    );
  }
}

enum HistoryKind {
  purchase, // 구매
  reward,   // 적립
}

class HistoryRecord {
  final String title;
  final String subtitle;
  final String timeAgo;
  final HistoryKind kind;

  const HistoryRecord({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.kind,
  });
}
