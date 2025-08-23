import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/kakao_login_service.dart';
import '../services/google_login_service.dart';
import 'home_screen.dart';
import '../services/region_setting_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

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
      if (saved == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
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
      final ok = await GoogleLoginService.login(); // ✅ 서비스 내부에서 users upsert 수행
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
