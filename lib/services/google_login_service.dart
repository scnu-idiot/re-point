import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google 로그인 + Firestore users 업서트
class GoogleLoginService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _google = GoogleSignIn();

  /// 로그인 진행 후 users 컬렉션 upsert
  /// 성공 시 true, 취소/실패 시 false
  static Future<bool> login() async {
    try {
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
        'region_distract': null,   // 네가 지정한 키 그대로 사용
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
    } on FirebaseAuthException catch (e) {
      // DEVELOPER_ERROR(10) 등은 보통 Android SHA-1/256 미등록 이슈
      // 필요시 e.code 로그로 분기 처리 가능
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 로그아웃 (구글/파이어베이스 모두)
  static Future<void> logout() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// 현재 로그인한 UID (없으면 null)
  static String? get currentUid => _auth.currentUser?.uid;
}
