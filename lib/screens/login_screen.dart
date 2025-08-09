import 'package:flutter/material.dart';
import '../services/kakao_login_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _login(BuildContext context) async {
    final success = await KakaoLoginService.login();
    if (success && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 로고 이미지
              Image.asset(
                'assets/images/splashscreen.png',
                width: 180,
              ),

              const SizedBox(height: 80), // 간격 유지

              // 카카오 로그인 버튼 (이미지 하나만)
              GestureDetector(
                onTap: () => _login(context),
                child: SizedBox(
                  width: 300,
                  height: 45,
                  child: Image.asset(
                    'assets/images/kakao_icon.png',
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