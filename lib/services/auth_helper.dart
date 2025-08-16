import 'package:shared_preferences/shared_preferences.dart';
import 'kakao_login_service.dart';
import 'google_login_service.dart';

Future<void> unifiedLogout() async {
  final prefs = await SharedPreferences.getInstance();
  final provider = prefs.getString('loginProvider');
  if (provider == 'kakao') {
    await KakaoLoginService.logout();
  } else if (provider == 'google') {
    await GoogleLoginService.logout();
  } else {
    await prefs.clear();
  }
}