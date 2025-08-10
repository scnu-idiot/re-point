import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'history_screen.dart';
import 'notice_screen.dart';
import 'support_screen.dart';
import 'invite.dart';
import '../widgets/event_card.dart';
import 'withdrawal_screen.dart';

// import 'package:http/http.dart' as http; // 🔗 Spring Boot 연동 시
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart'; // 🔗 Firebase 연동 시

class MyPageScreen extends StatefulWidget {
  final String nickname;
  const MyPageScreen({super.key, required this.nickname});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  // ===== 화면 데이터 (연동 전 더미) =====
  String email = 'walkholic@likelion.org';
  int points = 5000;
  int month = DateTime.now().month;
  int total = 753800;
  final Map<String, int> categories = {
    '식비': 380000,
    '쇼핑': 257400,
    '그 외': 116400,
  };

  // 카카오 프로필
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadKakaoProfile();
    // _loadProfileFromServer();   // 🔗 Spring Boot
    // _loadProfileFromFirebase(); // 🔗 Firebase
    // _loadReportFromServer();
    // _loadReportFromFirebase();
  }

  Future<void> _loadKakaoProfile() async {
    try {
      final user = await UserApi.instance.me();
      setState(() {
        profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;
        email = user.kakaoAccount?.email ?? email;
      });
    } catch (e) {
      debugPrint('카카오 프로필 불러오기 실패: $e');
    }
  }

  /* ==========================
   *  Spring Boot 예시 (주석)
   * ==========================
  Future<void> _loadProfileFromServer() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.example.com/me'),
        headers: {'Authorization': 'Bearer YOUR_TOKEN'},
      );
      if (res.statusCode == 200) {
        final j = json.decode(res.body) as Map<String, dynamic>;
        setState(() {
          email = j['email'] ?? email;
          points = (j['points'] ?? 0) as int;
        });
      }
    } catch (e) { debugPrint('profile load error: $e'); }
  }

  Future<void> _loadReportFromServer() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.example.com/me/consumption?month=$month'),
        headers: {'Authorization': 'Bearer YOUR_TOKEN'},
      );
      if (res.statusCode == 200) {
        final j = json.decode(res.body) as Map<String, dynamic>;
        setState(() {
          total = (j['total'] ?? 0) as int;
          categories
            ..clear()
            ..addAll((j['categories'] as Map).map(
              (k, v) => MapEntry(k.toString(), int.parse(v.toString())),
            ));
        });
      }
    } catch (e) { debugPrint('report load error: $e'); }
  }
  */

  /* ==========================
   *  Firebase 예시 (주석)
   * ==========================
  Future<void> _loadProfileFromFirebase() async {
    final doc = await FirebaseFirestore.instance
      .collection('users').doc('CURRENT_USER_ID').get();
    if (doc.exists) {
      setState(() {
        email  = doc.data()?['email']  ?? email;
        points = doc.data()?['points'] ?? points;
      });
    }
  }

  Future<void> _loadReportFromFirebase() async {
    final snap = await FirebaseFirestore.instance
      .collection('users').doc('CURRENT_USER_ID')
      .collection('reports').doc('$month').get();
    if (snap.exists) {
      final data = snap.data()!;
      setState(() {
        total = data['total'] ?? total;
        categories
          ..clear()
          ..addAll(Map<String, int>.from(data['categories'] ?? {}));
      });
    }
  }
  */

  String _fmt(int v) {
    final s = v.toString();
    final b = StringBuffer();
    var c = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      b.write(s[i]); c++;
      if (c % 3 == 0 && i != 0) b.write(',');
    }
    return b.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    const keyColor = Color(0xFF5E2AD7);

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 정보', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileCard(context),
            const SizedBox(height: 12),
            const Divider(height: 24),

            const Text('내 소비 리포트',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _reportCard(),

            const SizedBox(height: 12),
            _quickMenuCard(context, keyColor),

            const SizedBox(height: 12),
            _policyCard(),

            const SizedBox(height: 18),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WithdrawalScreen()),
                  );
                },
                child: const Text(
                  '회원 탈퇴',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 구성 위젯 =====

  Widget _profileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('안녕하세요', style: TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.nickname,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFAED2E2),
                backgroundImage:
                profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                child: profileImageUrl == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 14),

          // 포인트 / 이용내역 바
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('내 포인트',
                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text('${_fmt(points)} point',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 42, color: Colors.black12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HistoryScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      alignment: Alignment.center,
                      child: const Text('이용내역',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  month = (month - 1) < 1 ? 12 : (month - 1);
                  // _loadReportFromServer(); // 또는 Firebase
                }),
              ),
              Text('$month월', style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  month = (month + 1) > 12 ? 1 : (month + 1);
                  // _loadReportFromServer(); // 또는 Firebase
                }),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('이번달 소비 금액',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${_fmt(total)} 원',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          _categoryRow(Colors.red, '식비', categories['식비'] ?? 0),
          const SizedBox(height: 6),
          _categoryRow(Colors.green, '쇼핑', categories['쇼핑'] ?? 0),
          const SizedBox(height: 6),
          _categoryRow(const Color(0xFF5270FF), '그 외', categories['그 외'] ?? 0),
        ],
      ),
    );
  }

  Widget _categoryRow(Color color, String label, int value) {
    return Row(
      children: [
        Container(width: 12, height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text('${_fmt(value)}원', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _quickMenuCard(BuildContext context, Color keyColor) {
    Widget item(IconData icon, String label, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: keyColor),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: item(Icons.campaign_outlined, '공지사항', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeScreen()));
              })),
              Container(width: 1, height: 60, color: Colors.black12),
              Expanded(child: item(Icons.person_add_alt_1_outlined, '친구초대', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => InviteScreen(nickname: widget.nickname)));
              })),
            ],
          ),
          Container(height: 1, color: Colors.black12),
          Row(
            children: [
              Expanded(child: item(Icons.headset_mic_outlined, '고객센터', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
              })),
              Container(width: 1, height: 60, color: Colors.black12),
              Expanded(child: item(Icons.celebration_outlined, '이벤트', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCardScreen()));
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _policyCard() {
    Widget dot() => Container(
      width: 6, height: 6,
      decoration: const BoxDecoration(color: Color(0xFF5E2AD7), shape: BoxShape.circle),
    );

    Widget row(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          dot(),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          row('서비스 이용약관'),
          const Divider(height: 1),
          row('개인정보 처리방침'),
          const Divider(height: 1),
          row('위치기반 서비스 이용 약관'),
          const Divider(height: 1),
          row('앱 버전'),
        ],
      ),
    );
  }
}
