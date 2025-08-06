import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../screens/notification_screen.dart';
import '../screens/store_screen.dart';
import '../screens/support_screen.dart';
import '../screens/mypage.dart';
import '../screens/invite.dart';
import '../widgets/event_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
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
                  const ListTile(title: Text("공지사항")),
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
          ],
        ),
      ),
    );
  }
}
