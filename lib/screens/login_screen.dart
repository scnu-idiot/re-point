// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> _routeAfterLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final regionSet = prefs.getBool('region_set') ?? false;

    if (!mounted) return;

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
      if (!mounted) return;
      if (saved == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }


  Future<void> _loginKakao() async {
    final ok = await KakaoLoginService.login();
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
  }

  Future<void> _loginGoogle() async {
    final ok = await GoogleLoginService.login();
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
              Image.asset('assets/images/splashscreen.png', width: 180),
              const SizedBox(height: 60),

              GestureDetector(
                onTap: _loginKakao,
                child: SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: Image.asset('assets/images/kakao_icon.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _loginGoogle,
                child: SizedBox(
                  width: btnWidth,
                  height: btnHeight,
                  child: Image.asset('assets/images/google_logo.png', fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}