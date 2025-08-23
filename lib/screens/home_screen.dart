import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

// 🔽 화면 import
import 'notification_screen.dart';
import 'receipt_scan_screen.dart';
import 'store_screen.dart';
import 'history_screen.dart';
import 'support_screen.dart';
import 'chatbot_screen.dart';
import 'mypage.dart';
import '../widgets/event_card.dart';
import '../widgets/side_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? nickname;
  String? email;
  String? profileImageUrl;

  // ✅ 포인트(나중에 DB 연동 예정)
  int userPoints = 0; // 화면 확인용 더미 값

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final user = await UserApi.instance.me();
      setState(() {
        nickname = user.kakaoAccount?.profile?.nickname ?? '사용자';
        email = user.kakaoAccount?.email ?? '이메일 없음';
        profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;
      });
    } catch (e) {
      debugPrint('유저 정보 불러오기 실패: $e');
    }
  }

  String _formatPoints(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) buf.write(',');
    }
    return buf.toString().split('').reversed.join();
  }

  // 🔹 영수증 스캔 → 적립 포인트 받아 합산
  Future<void> _openReceiptScan() async {
    final earned = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptScanScreen()),
    );
    if (earned != null && earned > 0) {
      setState(() => userPoints += earned);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$earned point 적립 완료!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawerEnableOpenDragGesture: false,
      endDrawer: const SideMenu(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          width: 160,
          height: 50,
          colorFilter:
          const ColorFilter.mode(Color(0xFF5E2AD7), BlendMode.srcIn),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            // 공지 배너
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EDFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.volume_up, color: Color(0xFF5E2AD7)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'RE:POINT에 오신 것을 환영합니다.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 마이페이지 카드
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyPageScreen(nickname: nickname ?? '사용자'),
                  ),
                );
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F2FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단: 닉네임 / 아바타
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${nickname ?? "사용자"} 님',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        profileImageUrl != null
                            ? CircleAvatar(
                          radius: 18,
                          backgroundImage:
                          NetworkImage(profileImageUrl!),
                        )
                            : const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFF9EC3D6),
                          child: Icon(Icons.person,
                              size: 20, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 현재 포인트 표시
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '포인트 내역',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Text(
                          '${_formatPoints(userPoints)} point',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 두 개 카드 (왼쪽: 영수증 스캔)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _openReceiptScan,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/receipt_icon.png',
                        fit: BoxFit.cover,
                        height: 200,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EventCardScreen()),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/fire_icon.png',
                        fit: BoxFit.cover,
                        height: 200,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 스토어 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E2AD7),
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoreScreen()),
              ),
              child: const Text(
                "스토어",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 아래 두 메뉴
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HistoryScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long),
                          SizedBox(height: 6),
                          Text("이용내역"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SupportScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.headset_mic),
                          SizedBox(height: 6),
                          Text("고객센터"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 배너 (하단)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/banner_forest.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // 챗봇 플로팅 버튼
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: ClipOval(
            child: Image.asset(
              'assets/images/AI.png',
              fit: BoxFit.cover,
              width: 70,
              height: 70,
            ),
          ),
        ),
      ),
    );
  }
}