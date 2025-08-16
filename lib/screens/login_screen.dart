import 'package:flutter/material.dart';
import '../services/kakao_login_service.dart';
import '../services/google_login_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _loginKakao(BuildContext context) async {
    final ok = await KakaoLoginService.login();
    if (ok && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
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

              // 구글 로그인 (이미지 버튼) - 동일 크기
              GestureDetector(
                onTap: () => _loginGoogle(context),
                child: SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: Image.asset(
                    'assets/images/google_logo.png',
                    fit: BoxFit.cover, // 파일이 아이콘 형태여도 버튼 사이즈에 맞춰 채움
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
