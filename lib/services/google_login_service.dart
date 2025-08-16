// lib/services/google_login_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google 로그인 헬퍼
///
/// - 로그인 전 signOut()을 호출해 이전 세션 꼬임을 방지
/// - 성공 시 SharedPreferences에 로그인 플래그/간단 프로필 저장
/// - 실패 시 상세 로그 출력
class GoogleLoginService {
  // Firebase를 쓰고 있고 android/app/google-services.json, iOS/GoogleService-Info.plist가
  // 제대로 설정되어 있다면 기본 설정으로 충분합니다.
  // 서버에서 ID Token 검증이 필요하면 아래에 serverClientId(webClientId)를 넣어주세요.
  //
  // 예) serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
    // serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
  );

  /// Google 로그인
  /// - true: 로그인 성공
  /// - false: 취소/실패
  static Future<bool> login() async {
    try {
      // ⛑️ 세션 꼬임 방지: 이전 로그인 세션 정리
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        // signOut 실패는 치명적이지 않으므로 로그만 남김
        // (일부 기기/상황에서 발생 가능)
        // ignore
        // print('GoogleSignIn pre signOut ignore error: $e');
      }

      // 실제 로그인
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // 사용자가 로그인 플로우 중 취소한 경우
        print('[GoogleSignIn] User cancelled sign-in.');
        return false;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      // 성공 로그 (민감정보는 출력하지 않음)
      print('[GoogleSignIn] SUCCESS');
      print('  email       : ${account.email}');
      print('  displayName : ${account.displayName}');
      print('  photoUrl    : ${account.photoUrl}');
      print('  idToken?    : ${auth.idToken != null} (length=${auth.idToken?.length ?? 0})');
      print('  accessToken?: ${auth.accessToken != null}');

      // 간단한 세션 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loginProvider', 'google');
      await prefs.setString('googleEmail', account.email);
      await prefs.setString('googleDisplayName', account.displayName ?? '');
      await prefs.setString('googlePhotoUrl', account.photoUrl ?? '');

      // (선택) 서버 검증(스프링부트)나 Firebase Auth 커스텀 토큰으로 연동할 경우:
      // - auth.idToken / auth.accessToken을 백엔드로 전송하여 검증
      // - 이후 자체 세션/토큰 발급
      // TODO: send idToken to backend for verification (Spring Boot/Firebase)

      return true;
    } catch (e, st) {
      // 상세 오류 로그
      print('[GoogleSignIn] ERROR: $e');
      print('[GoogleSignIn] STACK: $st');

      // 흔한 오류 힌트:
      // - DEVELOPER_ERROR / 10 / 12500 등: SHA-1 누락, 패키지명/서명 불일치, google-services.json 미배치
      // - Firebase 콘솔/Google Cloud Console의 OAuth 동의화면/테스트 사용자 설정 필요

      return false;
    }
  }

  /// 로그아웃 (로컬 세션 및 구글 세션 정리)
  static Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('[GoogleSignIn] logout done');
    } catch (e, st) {
      print('[GoogleSignIn] logout error: $e');
      print('[GoogleSignIn] STACK: $st');
    }
  }

  /// 현재 로그인 여부 (로컬 플래그 기준)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  /// 현재 계정 정보 (로그인 성공 후 사용)
  static Future<GoogleSignInAccount?> getCurrentAccount() async {
    try {
      // 이미 로그인되어 있으면 currentUser 반환,
      // 아니면 silentSignIn으로 기존 세션 복구 시도
      final current = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      return current;
    } catch (e) {
      print('[GoogleSignIn] getCurrentAccount error: $e');
      return null;
    }
  }
}