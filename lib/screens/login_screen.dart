import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/kakao_login_service.dart';
import '../services/google_login_service.dart';
import 'home_screen.dart';
import '../services/region_setting_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // 로그인 이후 공통 분기: 지역 설정 여부 확인 → 미설정 시 지역 설정 화면으로
  Future<void> _routeAfterLogin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final regionSet = prefs.getBool('region_set') ?? false;

    if (!context.mounted) return;

    if (regionSet) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const RegionSettingScreen(forceMode: true),
        ),
      );
      if (saved == true && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _loginKakao(BuildContext context) async {
    final ok = await KakaoLoginService.login();
    if (ok && context.mounted) {
      // 어떤 로그인으로 들어왔는지 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_provider', 'kakao');

      await _routeAfterLogin(context);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카카오 로그인 실패')),
        );
      }
    }
  }

  Future<void> _loginGoogle(BuildContext context) async {
    final ok = await GoogleLoginService.login();
    if (ok && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_provider', 'google');

      await _routeAfterLogin(context);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구글 로그인 실패')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double btnWidth = 300;
    const double btnHeight = 45;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 로고
              Image.asset('assets/images/splashscreen.png', width: 180),
              const SizedBox(height: 60),

              // 카카오 로그인 (이미지 버튼)
              GestureDetector(
                onTap: () => _loginKakao(context),
                child: SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: Image.asset(
                    'assets/images/kakao_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 구글 로그인 (이미지 버튼) - 카카오와 동일 크기
              GestureDetector(
                onTap: () => _loginGoogle(context),
                child: SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: Image.asset(
                    // ⚠️ 300x45 크기의 버튼 이미지 준비 권장
                    // 예) 'assets/images/google_signin_button.png'
                    // 현재 google_logo.png 가 단일 아이콘이면, 버튼 배경으로 보이도록 별도 버튼 이미지를 쓰는 게 좋습니다.
                    'assets/images/google_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
