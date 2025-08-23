import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google 로그인 + Firestore users 업서트
class GoogleLoginService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _google = GoogleSignIn(
    // 필요하면 scopes 추가 가능
    // scopes: ['email'],
  );

  /// forceAccountSelection: true면 기존 세션/캐시를 끊고 계정 선택 팝업을 강제로 띄움
  static Future<bool> login({bool forceAccountSelection = false}) async {
    try {
      if (forceAccountSelection) {
        // 기존 구글 세션/캐시 완전히 끊기
        try { await _google.disconnect(); } catch (_) {}
        try { await _google.signOut(); } catch (_) {}
        try { await _auth.signOut(); } catch (_) {}
      }
      // 1) 구글 계정 선택 (사용자가 취소하면 null)
      final googleUser = await _google.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;

      // 2) Firebase Auth 로그인
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) return false;

      // 3) Firestore users 업서트
      final docRef = _db.collection('users').doc(user.uid);
      final snap = await docRef.get();

      final nowServer = FieldValue.serverTimestamp();
      final dataCreate = {
        'address': null,
        'created_at': nowServer,
        'email': user.email,
        'kakao_id': null,
        'login_provider': 'google',
        'name': user.displayName,
        'point': 0,
        'profile_url': user.photoURL,
        'region': null,
        'region_city': null,
        'region_distract': null, // 네가 쓰던 키 그대로 유지
        'region_province': null,
        'updated_at': nowServer,
      };

      final dataUpdate = {
        if (user.email != null) 'email': user.email,
        'login_provider': 'google',
        if (user.displayName != null) 'name': user.displayName,
        'profile_url': user.photoURL,
        'updated_at': nowServer,
      };

      if (!snap.exists) {
        await docRef.set(dataCreate, SetOptions(merge: true));
      } else {
        await docRef.set(dataUpdate, SetOptions(merge: true));
      }

      return true;
    } on FirebaseAuthException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 로그아웃 (계정 연결 해제까지 확실히)
  static Future<void> logout() async {
    try { await _google.disconnect(); } catch (_) {}
    try { await _google.signOut(); } catch (_) {}
    await _auth.signOut();
  }

  static String? get currentUid => _auth.currentUser?.uid;
}
