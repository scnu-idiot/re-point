import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadUid();
  }

  Future<void> _loadUid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _uid = prefs.getString('userId');
    });
  }

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
                // 탭바 아래 얇은 전체 구분선
                Container(height: 1, color: Colors.black12),
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
                      if (_uid != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PurchaseScreen(
                              uid: _uid!,
                              priceText: item.label, // '5,000 포인트'
                            ),
                          ),
                        );
                      } else {
                        // Optionally show a message if UID is not available
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.')),
                        );
                      }
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

// ======================= 구매 화면 =======================
class PurchaseScreen extends StatefulWidget {
  final String uid;
  final String priceText;

  const PurchaseScreen({
    super.key,
    required this.uid,
    required this.priceText,
  });

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  int _userPointBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPoints();
  }

  Future<void> _loadUserPoints() async {
    try {
      final balance = await ApiClient.fetchUserPoint(widget.uid);
      if (mounted) {
        setState(() {
          _userPointBalance = balance;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load user points: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('포인트를 불러오는데 실패했습니다.')),
      );
    }
  }

  int _extractAmount(String s) {
    // '5,000 포인트' -> 5000
    final onlyNum = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(onlyNum) ?? 0;
  }

  String _fmt(int v) =>
      v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('결제 확인', style: TextStyle(fontWeight: FontWeight.w700)),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final amount = _extractAmount(widget.priceText);
    final lack = _userPointBalance < amount;
    final remain = (_userPointBalance - amount).clamp(0, 1 << 31);


    const purple = Color(0xFF5A3DF0);
    const bgTop = Color(0xFFFFF5FB);
    const bgBottom = Color(0xFFF8F0FF);
    const cardShadow = BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('결제 확인', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgTop, bgBottom]),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // 상단 금액 카드
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [cardShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'RE:POINT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      letterSpacing: 1.2,
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmt(amount),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text('원', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: purple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '지역상품권',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),


            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [cardShadow],
              ),
              child: Column(
                children: [
                  _row('포인트 사용', '${_fmt(amount)} 원'),
                  const Divider(height: 1),
                  _row('잔여 포인트', '${_fmt(remain)} 포인트'),
                ],
              ),
            ),

            const SizedBox(height: 16),


            Text(
              '한 번 사용한 포인트는 취소가 불가합니다',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 20),

            // 결제
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: lack ? const Color(0xFFEDE7FF) : purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: lack
                    ? null
                    : () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('결제 진행'),
                      content: Text('정말로 ${_fmt(amount)}원을 지역상품권으로 교환하시겠어요?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확인')),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    try {
                      await ApiClient.exchangePoints(widget.uid, amount);
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('결제 완료'),
                            ],
                          ),
                          content: const Text('교환 코드가 발급되었습니다.\n알림함 또는 구매내역에서 확인하세요.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
                          ],
                        ),
                      );
                    } catch (e) {
                      debugPrint('Exchange failed: $e');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('결제 실패: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: const Text('결제하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Text(left, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(right, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ====================== 구매내역 빈 화면 예시 ======================
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
