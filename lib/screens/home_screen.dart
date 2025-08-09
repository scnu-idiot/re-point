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
      print('유저 정보 불러오기 실패: $e');
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
            colorFilter: const ColorFilter.mode(Color(0xFF5E2AD7), BlendMode.srcIn),
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
                      child: Text('RE:POINT에 오신 것을 환영합니다.', style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 사용자 카드
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F2FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${nickname ?? "사용자"} 님',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text("포인트 내역"),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: 0.5, // 예시 값
                              minHeight: 10,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5E2AD7)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('5,000 / 10,000 pt'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    profileImageUrl != null
                        ? CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(profileImageUrl!),
                    )
                        : const CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xFF778899),
                      child: Icon(Icons.person, size: 30, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptScanScreen()));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/images/receipt_icon.png', fit: BoxFit.cover, height: 200),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCardScreen())),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/images/fire_icon.png', fit: BoxFit.cover, height: 200),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E2AD7),
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())),
                child: const Text("스토어", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/images/banner_forest.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: const [
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
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: const [
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
              const SizedBox(height: 20),
              // 로그아웃 버튼 제거됨
            ],
          ),
        ),
        floatingActionButton: SizedBox(
          width: 70, // 버튼 크기
          height: 70,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotScreen()),
              );
            },
            backgroundColor: Colors.transparent, // 배경 투명
            elevation: 0, // 그림자 제거
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
        )

    );
  }
}