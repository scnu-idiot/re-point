import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  final List<_HistoryItem> items = const [
    _HistoryItem('영수증이 처리 되었습니다.', '16시간전'),
    _HistoryItem('영수증이 처리 되었습니다.', '1일전'),
    _HistoryItem('영수증이 처리 되었습니다.', '2일전'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            '이용내역',
          style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold, // ✅ 폰트 굵게
          fontSize: 18,
        ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ 로고 이미지 적용 (40x40 크기)
                Image.asset(
                  'assets/images/logo.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.message,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.timeAgo,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistoryItem {
  final String message;
  final String timeAgo;

  const _HistoryItem(this.message, this.timeAgo);
}