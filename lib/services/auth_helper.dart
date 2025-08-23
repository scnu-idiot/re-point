// auth_helper.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
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

/// 현재 로그인된 사용자 uid 가져오기
Future<String?> currentUid() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
}

/// 서버에서 내 사용자 최신 정보 가져오기
Future<Map<String, dynamic>?> fetchMyUser() async {
  final uid = await currentUid();
  if (uid == null) return null;
  return await ApiClient.getUser(uid);
}

/// 서버에 지역 저장 (Province/City/District)
Future<Map<String, dynamic>> saveMyRegion({
  required String province,
  required String city,
  required String district,
}) async {
  final uid = await currentUid();
  if (uid == null) throw Exception('Not logged in');
  return await ApiClient.patchRegion(
    uid: uid,
    province: province,
    city: city,
    district: district,
  );
}