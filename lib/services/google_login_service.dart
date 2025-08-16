import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleLoginService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // 필요하면 scopes 추가
    scopes: <String>[
      'email',
      // 'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  static Future<bool> login() async {
    try {
      // 기존 계정으로 로그인되어 있으면 disconnect로 새로고침 원하면 주석 해제
      // await _googleSignIn.disconnect();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // 사용자가 취소
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loginProvider', 'google');
      await prefs.setString('userEmail', account.email);
      await prefs.setString('userName', account.displayName ?? '');
      await prefs.setString('userPhoto', account.photoUrl ?? '');
      await prefs.setString('userId', account.id);

      // idToken / accessToken이 필요하면 아래 사용 (백엔드 검증용)
      // final auth = await account.authentication;
      // final idToken = auth.idToken; final accessToken = auth.accessToken;

      return true;
    } catch (e) {
      // 디버깅용
      // print('Google login error: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}
