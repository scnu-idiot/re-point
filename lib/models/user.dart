class AppUser {
  final String id;
  final String? email;
  final String? nickname;
  final String? photoUrl;
  final String provider; // 'kakao' or 'google'

  AppUser({
    required this.id,
    required this.provider,
    this.email,
    this.nickname,
    this.photoUrl,
  });
}
