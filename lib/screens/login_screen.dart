import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/kakao_login_service.dart';
import '../services/google_login_service.dart';
import 'home_screen.dart';
import 'region_setting_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _routeAfterLogin() async {
    // 1) 로그인 유저 확인
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 세션이 없어서 이동을 취소했어. 다시 시도해줘.')),
      );
      return;
    }

    // 2) users/{uid} 가져오기
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // 문서가 아예 없으면 → 신규 유저 취급: 일단 홈으로 보낼지, 지역부터 받게 할지 선택
      if (!snap.exists) {
        // ▶ 선택 1: 홈으로 보내기
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;

        // ▶ 선택 2: 바로 지역 설정 강제
        // final saved = await Navigator.push<bool>(
        //   context,
        //   MaterialPageRoute(builder: (_) => const RegionSettingScreen(forceMode: true)),
        // );
        // if (saved == true && mounted) {
        //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        // }
        // return;
      }

      final data = snap.data() ?? {};
      final hasRegion = (data['region_province'] != null &&
          data['region_city'] != null &&
          data['region_distract'] != null);

      if (hasRegion) {
        // 3-a) 지역 설정 되어 있으면 홈
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // 3-b) 지역 설정 안 되어 있으면 설정 화면으로
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const RegionSettingScreen(forceMode: true),
          ),
        );
        if (saved == true && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자 정보 확인 실패: $e')),
      );
    }
  }

  Future<void> _loginKakao() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final ok = await KakaoLoginService.login(); // ✅ 서비스 내부에서 users upsert 수행
      if (!mounted) return;
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_provider', 'kakao');
        await _routeAfterLogin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카카오 로그인 실패')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인 오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      // 🔥 계정 선택 강제
      final ok = await GoogleLoginService.login(forceAccountSelection: true);

      if (!mounted) return;
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_provider', 'google');
        await _routeAfterLogin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구글 로그인 실패')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인 오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double btnWidth = 300;
    const double btnHeight = 45;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/splashscreen.png', width: 180),
                  const SizedBox(height: 60),

                  // 카카오 로그인 버튼
                  SizedBox(
                    width: btnWidth,
                    height: btnHeight,
                    child: InkWell(
                      onTap: _loading ? null : _loginKakao,
                      borderRadius: BorderRadius.circular(8),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/kakao_icon.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 구글 로그인 버튼
                  SizedBox(
                    width: btnWidth,
                    height: btnHeight,
                    child: InkWell(
                      onTap: _loading ? null : _loginGoogle,
                      borderRadius: BorderRadius.circular(8),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/google_logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 로딩 오버레이
            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
