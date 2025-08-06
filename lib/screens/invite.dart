import 'package:flutter/material.dart';
import '../widgets/profile_appbar.dart';

class InviteScreen extends StatelessWidget {
  final String nickname;

  const InviteScreen({super.key, required this.nickname});

  // ✅ const 추가
  final Map<int, int> rewardMap = const {
    1: 500,
    5: 3000,
    10: 10000,
    20: 20000,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProfileAppBar(nickname: nickname),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("친구 초대하기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...rewardMap.entries.map(
                  (entry) => _inviteButton(context, entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inviteButton(BuildContext context, int friendCount, int reward) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () {
          _inviteFriends(context, friendCount, reward);
        },
        child: Text('$friendCount명 초대 → ${reward}pt 적립'),
      ),
    );
  }

  void _inviteFriends(BuildContext context, int count, int reward) {
    // TODO: 실제 API 연동
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count명 초대 완료! ${reward}pt가 적립되었습니다.')),
    );
  }
}
