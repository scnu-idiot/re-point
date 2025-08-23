import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KakaoLoginService {
  static Future<bool> login() async {
    try {
      if (await isKakaoTalkInstalled()) {
        await UserApi.instance.loginWithKakaoTalk();
      } else {
        await UserApi.instance.loginWithKakaoAccount();
      }

      final user = await UserApi.instance.me();
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loginProvider', 'kakao');
      await prefs.setString('userId', user.id.toString());
      await prefs.setString('userEmail', user.kakaoAccount?.email ?? '');
      await prefs.setString('userName', user.kakaoAccount?.profile?.nickname ?? '');
      await prefs.setString('userPhoto', user.kakaoAccount?.profile?.profileImageUrl ?? '');

      return true;
    } catch (e) {
      // print("카카오 로그인 실패: $e");
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      await UserApi.instance.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<User?> getUser() async {
    try {
      return await UserApi.instance.me();
    } catch (_) {
      return null;
    }
  }
}