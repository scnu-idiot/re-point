import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../screens/notification_screen.dart';
import '../screens/store_screen.dart';
import '../screens/support_screen.dart';
import '../screens/mypage.dart';
import '../screens/invite.dart';
import '../screens/notice_screen.dart'; // ✅ 공지사항 화면 import
import '../widgets/event_card.dart';
import '../screens/login_screen.dart';
import '../services/kakao_login_service.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String _nickname = '사용자';

  @override
  void initState() {
    super.initState();
    _loadKakaoUser();
  }

  Future<void> _loadKakaoUser() async {
    try {
      final user = await UserApi.instance.me();
      setState(() {
        _nickname = user.kakaoAccount?.profile?.nickname ?? '사용자';
      });
    } catch (e) {
      print('카카오 사용자 정보 불러오기 실패: $e');
    }
  }

  Future<void> _logout() async {
    await KakaoLoginService.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // 상단 알림 + 닫기 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),

            // 메뉴 리스트
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ListTile(
                    title: const Text("나의 정보"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyPageScreen(nickname: _nickname),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("스토어"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StoreScreen()),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("친구초대"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InviteScreen(nickname: _nickname),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("공지사항"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NoticeScreen()),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("이벤트"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EventCardScreen()),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("고객센터"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SupportScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 하단 로그아웃
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: _logout,
                child: const Text(
                  "로그아웃",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
