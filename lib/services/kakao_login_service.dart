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

      print("카카오 로그인 성공: ${user.kakaoAccount?.email}");
      return true;
    } catch (e) {
      print("카카오 로그인 실패: $e");
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      await UserApi.instance.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("로그아웃 완료");
    } catch (e) {
      print("로그아웃 실패: $e");
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<User?> getUser() async {
    try {
      return await UserApi.instance.me();
    } catch (e) {
      print("유저 정보 가져오기 실패: $e");
      return null;
    }
  }
}
