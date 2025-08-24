import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? _uid;
  List<HistoryRecord> items = [];

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUidAndNotifications();
  }

  Future<void> _loadUidAndNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getString('userId');
    if (_uid != null) {
      await _loadNotifications();
    } else {
      setState(() {
        loading = false;
        error = '사용자 정보를 불러올 수 없습니다.';
      });
    }
  }

  Future<void> _loadNotifications() async {
    if (_uid == null) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final pointHistory = await ApiClient.fetchPointHistory(_uid!);
      final giftCardTransactions = await ApiClient.fetchGiftCardTransactions(_uid!);

      List<HistoryRecord> combinedList = [];

      for (var e in pointHistory) {
        combinedList.add(HistoryRecord(
          title: e['title'] ?? '',
          subtitle: e['detail'] ?? '',
          timeAgo: _formatTimeAgo(e['created_at']),
          kind: HistoryKind.reward,
          timestamp: _getDateTimeFromTimestamp(e['created_at']),
        ));
      }

      for (var e in giftCardTransactions) {
        combinedList.add(HistoryRecord(
          title: '${e['amount']}원 상품권 교환',
          subtitle: '코드: ${e['code']}',
          timeAgo: _formatTimeAgo(e['issued_at']),
          kind: HistoryKind.purchase,
          timestamp: _getDateTimeFromTimestamp(e['issued_at']),
        ));
      }

      // Sort by timestamp, latest first
      combinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        setState(() {
          items = combinedList;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
      if (mounted) {
        setState(() {
          loading = false;
          error = '알림을 불러오는데 실패했습니다: ${e.toString()}';
        });
      }
    }
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = _getDateTimeFromTimestamp(timestamp);
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

  DateTime _getDateTimeFromTimestamp(dynamic timestamp) {
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is Map && timestamp.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else {
      return DateTime.now(); // Fallback
    }
  }

  // 🔄 당겨서 새로고침 (데모에선 UI만 갱신)
  Future<void> _onRefresh() async {
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5E2AD7);
    const green = Color(0xFF219653);

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
            final color = it.kind == HistoryKind.purchase ? purple : green;
            final icon = it.kind == HistoryKind.purchase
                ? Icons.card_giftcard
                : Icons.check_circle;

            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
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
                        const SizedBox(height: 4),
                        Text(
                          it.subtitle,
                          style: const TextStyle(
                              fontSize: 13.5, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    it.timeAgo,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
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

enum HistoryKind {
  purchase, // 구매
  reward,   // 적립
}

class HistoryRecord {
  final String title;
  final String subtitle;
  final String timeAgo;
  final HistoryKind kind;
  final DateTime timestamp;

  const HistoryRecord({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.kind,
    required this.timestamp,
  });
}
