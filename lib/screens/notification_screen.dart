// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import '../data/history_data.dart'; // HistoryRecord, HistoryKind, mergedHistoryLatestFirst

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // ✅ 이용내역에서 생성된 이벤트를 알림으로 재구성
  late List<HistoryRecord> items;

  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    // 공용 데이터 사용
    items = mergedHistoryLatestFirst();
  }

  // 🔄 당겨서 새로고침 (데모에선 UI만 갱신)
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      items = mergedHistoryLatestFirst();
    });
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
