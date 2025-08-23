// lib/screens/withdrawal_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 소셜 연동 해제용
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

// 로그인 화면
import 'login_screen.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  bool _busy = false;

  /// 카카오/구글 계정 모두에 대해 연결 해제(가입 정보 삭제) 시도
  Future<void> _revokeSocialAccounts() async {
    // 1) 카카오 연결 해제
    try {
      await UserApi.instance.unlink();
    } catch (_) {}

    // 2) 구글 연결 해제
    try {
      final google = GoogleSignIn(scopes: const ['email']);
      if (await google.isSignedIn()) {
        await google.disconnect();
      }
    } catch (_) {
      try {
        final google = GoogleSignIn(scopes: const ['email']);
        if (await google.isSignedIn()) {
          await google.signOut();
        }
      } catch (_) {}
    }
  }

  /// 앱 내부 데이터/세션 정리
  Future<void> _clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> _doDeleteAccount() async {
    setState(() => _busy = true);
    try {
      await _revokeSocialAccounts();
      await _clearLocalSession();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원 탈퇴 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !_busy,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '정말로 회원 탈퇴 하시겠어요?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            '회원 탈퇴하실 경우 잔여 포인트 및 이용내역이 모두 소멸됩니다.',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: _busy ? null : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5E2AD7), // purple
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('탈퇴하기', style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _doDeleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5E2AD7);
    const grey = Color(0xFF7A7A7A);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '회원 탈퇴',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '정말 RE:POINT를 떠나실 건가요?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),

                  // 안내 박스
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.check_circle, color: purple),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '아래 항목을 포함한 모든 정보가 영구적으로 삭제되어 복구할 수 없습니다.',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.only(left: 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ThinItem('포인트'),
                              _ThinItem('소비 리포트'),
                              _ThinItem('구매 상품 정보'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: const [
                            Icon(Icons.check_circle, color: purple),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '복구는 회원탈퇴 후 30일 이내까지 가능합니다.',
                                style: TextStyle(color: grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 하단 버튼 2개
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _confirmAndDelete,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: purple),
                            foregroundColor: purple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('탈퇴하기', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _busy ? null : () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('계속 이용하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThinItem extends StatelessWidget {
  final String text;
  const _ThinItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF9E9E9E)),
      ),
    );
  }
}

