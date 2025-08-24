// api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  final http.Client _client = http.Client();
  static String? _authToken;
  static void setAuthToken(String? t) => _authToken = t;
  // 백엔드 주소
  // •	Android 에뮬레이터 → http://10.0.2.2:8080
  // •	iOS 시뮬레이터 → http://localhost:8080
  static const String baseUrl = 'http://10.0.2.2:8080';

  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
  };
  static Future<Map<String, dynamic>> googleLoginByIdToken({
    required String idToken,
    String address = '',
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/google/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'address': address}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('googleLogin failed: ${res.statusCode} ${res.body}');
  }

  // -----------------------------
  // Auth: 서버에 사용자 upsert (회원가입/로그인 동기화)
  // -----------------------------
  static Future<Map<String, dynamic>> upsertLogin({
    required String uid,
    required String name,
    required String email,
    required String profileUrl,
    required String loginProvider, // "kakao" | "google"
    String address = "",
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login/$uid');
    final body = jsonEncode({
      "name": name,
      "email": email,
      "profileUrl": profileUrl,
      "address": address,
      "loginProvider": loginProvider,
    });

    final res = await http.post(url, headers: _jsonHeaders, body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('upsertLogin failed: ${res.statusCode} ${res.body}');
  }

  // -----------------------------
  // User: 단건 조회
  // -----------------------------
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final url = Uri.parse('$baseUrl/api/users/$uid');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    if (res.statusCode == 404) return null;
    throw Exception('getUser failed: ${res.statusCode} ${res.body}');
  }

  // -----------------------------
  // User: 지역(Province/City/District) 패치
  // -----------------------------
  static Future<Map<String, dynamic>> patchRegion({
    required String uid,
    required String province,
    required String city,
    required String district,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$uid/region');
    final body = jsonEncode({
      "province": province,
      "city": city,
      "district": district,
    });

    final res = await http.patch(url, headers: _jsonHeaders, body: body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('patchRegion failed: ${res.statusCode} ${res.body}');
  }
  static Future<void> upsertUser({
    required String uid,
    required String name,
    required String email,
    required String profileUrl,
    required String loginProvider,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login/$uid');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'profileUrl': profileUrl,
        'address': '',
        'loginProvider': loginProvider,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('upsertUser failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> deleteUser(String uid) async {
    final url = Uri.parse('$baseUrl/api/users/$uid');
    final res = await http.delete(url);
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('deleteUser failed: ${res.statusCode} ${res.body}');
    }
  }
  /// 현재 사용자 포인트만 정수로 반환
  static Future<int> fetchUserPoint(String uid) async {
    final m = await getUser(uid); // GET /api/users/{uid}
    if (m == null) return 0;

    // 서버/파이어스토어 어떤 키를 쓰든 안전하게 캐치
    final v = m['point'] ?? m['balance'] ?? 0;
    return (v as num).toInt();
  }

  /// 영수증 적립 (고정 100)
  static Future<int> earnByReceipt(String uid, {
    required String receiptId,
    String title = '영수증 인증 적립',
    String detail = '',
  }) async {
    final url = Uri.parse('$baseUrl/api/points/earn/receipt/$uid');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'receiptId': receiptId,
        'title': title,
        'detail': detail,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('earnByReceipt failed: ${res.statusCode} ${res.body}');
    }
    final m = jsonDecode(res.body) as Map<String, dynamic>;
    return (m['balance'] as num).toInt();
  }

  /// 이벤트 참여 적립 (고정 100)
  static Future<int> earnByEvent(String uid, {
    required String eventId,
    String title = '이벤트 참여 적립',
    String detail = '',
  }) async {
    final url = Uri.parse('$baseUrl/api/points/earn/event/$uid');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'eventId': eventId,
        'title': title,
        'detail': detail,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('earnByEvent failed: ${res.statusCode} ${res.body}');
    }
    final m = jsonDecode(res.body) as Map<String, dynamic>;
    return (m['balance'] as num).toInt();
  }

  /// 친구초대 적립 (고정 500)
  static Future<int> earnByInvite(String uid, {
    required String inviteId,
    String title = '친구초대 적립',
    String detail = '',
  }) async {
    final url = Uri.parse('$baseUrl/api/points/earn/invite/$uid');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'inviteId': inviteId,
        'title': title,
        'detail': detail,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('earnByInvite failed: ${res.statusCode} ${res.body}');
    }
    final m = jsonDecode(res.body) as Map<String, dynamic>;
    return (m['balance'] as num).toInt();
  }

  /// 포인트 히스토리 조회 (source: all|receipt|event|invite)
  static Future<List<Map<String, dynamic>>> fetchPointHistory(
      String uid, {
        String source = 'all',
        int limit = 20,
        String? beforeIso,
      }) async {
    final qs = {
      'source': source,
      'limit': '$limit',
      if (beforeIso != null) 'before': beforeIso,
    };
    final url = Uri.parse('$baseUrl/api/points/history/$uid')
        .replace(queryParameters: qs);
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('fetchPointHistory failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }
  static Future<Map<String, dynamic>> updateAddress({
    required String uid,
    String? address,
    String? regionProvince,
    String? regionCity,
    String? regionDistrict,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$uid/address');
    final body = {
      if (address != null) 'address': address,
      if (regionProvince != null) 'regionProvince': regionProvince,
      if (regionCity != null) 'regionCity': regionCity,
      if (regionDistrict != null) 'regionDistrict': regionDistrict,
    };

    final res = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('주소 업데이트 실패: ${res.statusCode} ${res.body}');
    }
  }
  Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken'); // 있으면 넣고 없으면 무시
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    if (extra != null) h.addAll(extra);
    return h;
  }
  // GET /path
  Future<http.Response> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    return _client.get(uri, headers: await _headers());
  }

  // POST /path (JSON body)
  Future<http.Response> postJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    return _client.post(uri,
        headers: await _headers(), body: jsonEncode(body));
  }
}
