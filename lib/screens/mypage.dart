import 'package:flutter/material.dart';
import '../widgets/profile_appbar.dart';

class MyPageScreen extends StatelessWidget {
  final String nickname;

  const MyPageScreen({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProfileAppBar(nickname: nickname),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("내 정보", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _infoTile("이름", nickname),
            _infoTile("가입일", "2024-06-15"),
            _infoTile("현재 포인트", "12,500pt"),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(title, style: const TextStyle(fontSize: 15))),
          Text(content, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}