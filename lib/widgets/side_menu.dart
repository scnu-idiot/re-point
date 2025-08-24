import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../screens/notification_screen.dart';
import '../screens/store_screen.dart';
import '../screens/support_screen.dart';
import '../screens/mypage.dart';
import '../screens/invite.dart';
import '../screens/notice_screen.dart';
import '../widgets/event_card.dart';
import '../screens/login_screen.dart';

// ✅ 통합 로그아웃 헬퍼
import '../services/auth_helper.dart';

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
    _loadNickname();
  }

  /// 카카오/구글 모두 대응한 닉네임 로딩
  Future<void> _loadNickname() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('loginProvider');

      if (provider == 'kakao') {
        // 카카오 프로필에서 닉네임
        final user = await UserApi.instance.me();
        setState(() {
          _nickname = user.kakaoAccount?.profile?.nickname ?? '사용자';
        });
      } else {
        // 구글 또는 기타: SharedPreferences 저장값 사용
        final savedName = prefs.getString('userName');
        setState(() {
          _nickname = (savedName != null && savedName.isNotEmpty) ? savedName : '사용자';
        });
      }
    } catch (e) {
      // 실패 시 기본값 유지
      debugPrint('닉네임 로딩 실패: $e');
    }
  }

  Future<void> _logout() async {
    await unifiedLogout(); // ✅ provider에 맞춰 자동 로그아웃
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
                          builder: (_) => const MyPageScreen(),
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
                          builder: (_) => const InviteScreen(),
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

            // 하단 로그아웃 (가운데 정렬 + 밑줄)
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
