// lib/screens/history_screen.dart
import 'package:flutter/material.dart';

// ✅ 공유 더미 데이터
import '../data/history_data.dart'; // HistoryRecord, HistoryKind, demoPurchases, demoRewards

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // ✅ 공유 데이터 사용
  List<HistoryRecord> purchases = List.of(demoPurchases);
  List<HistoryRecord> rewards = List.of(demoRewards);

  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // 🔄 풀투리프레시
  Future<void> _onRefresh() async {
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
