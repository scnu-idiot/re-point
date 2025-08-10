import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

// import 'package:http/http.dart' as http; // 🔗 Spring Boot 연동 시
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart'; // 🔗 Firebase 연동 시

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  bool loading = false;
  String? message;

  Future<void> _kakaoUnlink() async {
    setState(() { loading = true; message = null; });
    try {
      await UserApi.instance.unlink(); // ✅ 카카오 계정 연동 해제
      setState(() { message = '카카오 연결 해제가 완료되었습니다.'; });
    } catch (e) {
      setState(() { message = '카카오 연결 해제 실패: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> _deleteAccount() async {
    setState(() { loading = true; message = null; });
    try {
      // ====== Spring Boot 서버에 계정 삭제 요청 (주석) ======
      /*
      final res = await http.delete(
        Uri.parse('https://api.example.com/me'),
        headers: {'Authorization': 'Bearer YOUR_TOKEN'},
      );
      if (res.statusCode != 200) {
        throw '서버 응답 오류: ${res.statusCode}';
      }
      */

      // ====== Firebase 데이터 정리(예시, 주석) ======
      /*
      final uid = 'CURRENT_USER_ID';
      final batch = FirebaseFirestore.instance.batch();
      // 유저 하위 데이터 정리 후 최종 삭제 …
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      */

      setState(() { message = '계정 삭제 처리가 완료되었습니다.'; });
      if (!mounted) return;
      Navigator.of(context).pop(); // 필요 시 로그인 화면으로 pushReplacement
    } catch (e) {
      setState(() { message = '계정 삭제 실패: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const keyColor = Color(0xFF5E2AD7);

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 탈퇴'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('탈퇴 전 안내', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              '• 탈퇴 시 보유 포인트 및 이용내역이 모두 삭제됩니다.\n'
                  '• 카카오 연결 계정은 별도로 “연결 끊기”를 진행해야 합니다.\n'
                  '• 일정 기간 복구가 불가할 수 있습니다.',
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1) 카카오 연결 끊기', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: loading ? null : _kakaoUnlink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: keyColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('카카오 연결 해제'),
                  ),
                  const SizedBox(height: 16),
                  const Text('2) 계정 삭제', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: loading ? null : _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('계정 완전 삭제'),
                  ),
                ],
              ),
            ),

            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!, style: const TextStyle(color: Colors.black87)),
            ],

            if (loading) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
