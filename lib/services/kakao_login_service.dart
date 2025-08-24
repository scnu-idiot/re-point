// kakao_login_service.dart
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class KakaoLoginService {
  static Future<bool> login() async {
    try {
      if (await isKakaoTalkInstalled()) {
        await UserApi.instance.loginWithKakaoTalk();
      } else {
        await UserApi.instance.loginWithKakaoAccount();
      }

      // 카카오 유저 정보
      final user = await UserApi.instance.me();

      final uid = 'kakao:${user.id}';
      final name = user.kakaoAccount?.profile?.nickname ?? '';
      final email = user.kakaoAccount?.email ?? '';
      final photo = user.kakaoAccount?.profile?.profileImageUrl ?? '';

      // ✅ 백엔드에 upsert (회원 등록/수정)
      final saved = await ApiClient.upsertLogin(
        uid: uid,
        name: name,
        email: email,
        profileUrl: photo,
        loginProvider: 'kakao',
        address: '', // 초기값
      );

      // 로컬 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loginProvider', 'kakao');
      await prefs.setString('userId', uid);
      await prefs.setString('userEmail', saved['email'] ?? email);
      await prefs.setString('userName', saved['name'] ?? name);
      await prefs.setString('userPhoto', saved['profileUrl'] ?? photo);
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