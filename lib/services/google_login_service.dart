// lib/services/google_login_service.dart
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class GoogleLoginService {
  // 반드시 "웹 클라이언트 ID"로 교체하세요.
  static const String kWebClientId = '132968321662-fg6rju0i89qva47jggm04bguc1i1igk4.apps.googleusercontent.com';

  /// 실제 로그인 + 백엔드 검증 + Firestore upsert 까지 수행
  static Future<Map<String, dynamic>> signInViaBackend({String address = ''}) async {
    final g = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: kWebClientId, // <- idToken aud가 웹클라ID로 나오도록 필수
    );

    final user = await g.signIn();
    if (user == null) throw Exception('사용자가 로그인 취소');

    final auth = await user.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('idToken을 가져오지 못했습니다');
    }

    // 백엔드로 전송 → 검증 + Firestore upsert
    final saved = await ApiClient.googleLoginByIdToken(
      idToken: idToken,
      address: address,
    );

    // 로컬 세션 저장 (카카오와 동일 키)
    final prefs = await SharedPreferences.getInstance();
    final uid = (saved['uid'] as String?) ?? '';
    final name = (saved['name'] as String?) ?? '';
    final email = (saved['email'] as String?) ?? '';
    await prefs.setString('userId', uid);
    await prefs.setString('loginProvider', 'google');
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);

    // (선택) 백엔드가 지역을 돌려주면 region_set 플래그도 설정
    final hasRegion = (saved['regionProvince'] ?? '').toString().isNotEmpty;
    await prefs.setBool('region_set', hasRegion);

    return saved;
  }

  /// LoginScreen에서 쓰기 좋은 래퍼: 성공/실패만 반환
  static Future<bool> login({String address = ''}) async {
    try {
      await signInViaBackend(address: address);
      return true;
    } catch (e, st) {
      debugPrint('Google login failed: $e\n$st');
      return false;
    }
  }

  /// 구글 로그아웃 + 로컬 세션 삭제
  static Future<void> logout() async {
    try { await GoogleSignIn().signOut(); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}