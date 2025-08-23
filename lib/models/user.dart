import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid; // 문서 id = auth uid
  final String? address;
  final Timestamp? createdAt;
  final String? email;
  final String? kakaoId;
  final String loginProvider; // 'google' | 'kakao'
  final String? name;
  final int point;
  final String? profileUrl;
  final String? region;
  final String? regionCity;
  final String? regionDistract;   // ← 네가 준 키 그대로 사용 (오타면 여기/맵 둘 다 동일하게)
  final String? regionProvince;
  final Timestamp? updatedAt;

  AppUser({
    required this.uid,
    required this.loginProvider,
    this.address,
    this.createdAt,
    this.email,
    this.kakaoId,
    this.name,
    this.point = 0,
    this.profileUrl,
    this.region,
    this.regionCity,
    this.regionDistract,
    this.regionProvince,
    this.updatedAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      address: map['address'] as String?,
      createdAt: map['created_at'] as Timestamp?,
      email: map['email'] as String?,
      kakaoId: map['kakao_id'] as String?,
      loginProvider: map['login_provider'] as String? ?? 'google',
      name: map['name'] as String?,
      point: (map['point'] ?? 0) as int,
      profileUrl: map['profile_url'] as String?,
      region: map['region'] as String?,
      regionCity: map['region_city'] as String?,
      regionDistract: map['region_distract'] as String?,
      regionProvince: map['region_province'] as String?,
      updatedAt: map['updated_at'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'address': address,
      'created_at': FieldValue.serverTimestamp(),
      'email': email,
      'kakao_id': kakaoId,
      'login_provider': loginProvider,
      'name': name,
      'point': point,
      'profile_url': profileUrl,
      'region': region,
      'region_city': regionCity,
      'region_distract': regionDistract,
      'region_province': regionProvince,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      if (address != null) 'address': address,
      if (email != null) 'email': email,
      if (kakaoId != null) 'kakao_id': kakaoId,
      'login_provider': loginProvider,
      if (name != null) 'name': name,
      'profile_url': profileUrl,
      if (region != null) 'region': region,
      if (regionCity != null) 'region_city': regionCity,
      if (regionDistract != null) 'region_distract': regionDistract,
      if (regionProvince != null) 'region_province': regionProvince,
      'updated_at': FieldValue.serverTimestamp(),
      // point는 적립 로직에서 별도 업데이트 권장
    };
  }
}

