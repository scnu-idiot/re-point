import 'package:flutter/material.dart';

import '../screens/notification_screen.dart';
import '../screens/store_screen.dart';
import '../screens/support_screen.dart';
import '../widgets/event_card.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

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
                  const ListTile(title: Text("나의 정보")),
                  ListTile(
                    title: const Text("스토어"),
                    onTap: () {
                      Navigator.pop(context); // 사이드 메뉴 닫기
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StoreScreen()),
                      );
                    },
                  ),
                  const ListTile(title: Text("친구초대")),
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
