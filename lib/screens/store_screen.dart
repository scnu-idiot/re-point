import 'package:flutter/material.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  // 상품 정보 리스트
  final List<_Item> items = const [
    _Item('assets/images/money5.png', '5,000 포인트'),
    _Item('assets/images/money10.png', '10,000 포인트'),
    _Item('assets/images/money20.png', '20,000 포인트'),
    _Item('assets/images/money30.png', '30,000 포인트'),
    _Item('assets/images/money50.png', '50,000 포인트'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '스토어',
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2열
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PurchaseScreen(priceText: item.label),
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(item.imagePath, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

class _Item {
  final String imagePath;
  final String label;

  const _Item(this.imagePath, this.label);
}

// 구매 화면 예시
class PurchaseScreen extends StatelessWidget {
  final String priceText;

  const PurchaseScreen({super.key, required this.priceText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('구매하기')),
      body: Center(
        child: Text('$priceText 구매 화면입니다.', style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
