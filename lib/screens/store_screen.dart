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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: const Text(
            '스토어',
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
          // 탭바를 AppBar의 bottom으로 배치
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Column(
              children: [
                TabBar(
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
                    Tab(text: '상품'),
                    Tab(text: '구매내역'),
                  ],
                ),
                // 탭바 아래 얇은 전체 구분선 (스크린샷 느낌)
                Container(
                  height: 1,
                  color: Colors.black12,
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // 탭 1: 상품 그리드
            Padding(
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 탭 2: 구매내역 (빈 상태 예시)
            const _EmptyHistoryView(),
          ],
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
      appBar: AppBar(
        title: const Text('구매하기'),
        centerTitle: true,
      ),
      body: Center(
        child: Text('$priceText 구매 화면입니다.', style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

// 구매내역 빈 화면 예시
class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '구매내역이 없습니다.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.black45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
