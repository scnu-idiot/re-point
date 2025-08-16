import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleLoginService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      // 필요 시 추가 스코프
    ],
  );

  static Future<bool> login() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // 사용자가 취소
        return false;
      }

      // idToken / accessToken 필요 시:
      // final auth = await account.authentication;
      // final idToken = auth.idToken;
      // final accessToken = auth.accessToken;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loginProvider', 'google');
      await prefs.setString('userId', account.id);
      await prefs.setString('userEmail', account.email);
      await prefs.setString('userName', account.displayName ?? '');
      await prefs.setString('userPhoto', account.photoUrl ?? '');

      return true;
    } catch (e) {
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
