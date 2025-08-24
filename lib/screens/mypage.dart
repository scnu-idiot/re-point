import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';


// screens
import 'history_screen.dart';
import 'notice_screen.dart';
import 'support_screen.dart';
import 'invite.dart';
import '../widgets/event_card.dart';
import 'withdrawal_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'location_terms_screen.dart';
import 'app_version_screen.dart';
import 'region_setting_screen.dart';
import '../services/api_client.dart';

class MyPageScreen extends StatefulWidget {
  final String nickname;
  const MyPageScreen({super.key, required this.nickname});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  // ==== 연도/월 소비 데이터 ====
  final Map<int, Map<int, Map<String, int>>> yearlyData = {
    2025: {
      1: {'식비': 490000, '쇼핑': 190000, '그 외': 142000},
      2: {'식비': 310000, '쇼핑': 120000, '그 외': 231000},
      3: {'식비': 320000, '쇼핑': 110000, '그 외': 311000},
      4: {'식비': 330000, '쇼핑': 200000, '그 외': 231000},
      5: {'식비': 360000, '쇼핑': 210000, '그 외': 231000},
      6: {'식비': 390000, '쇼핑': 220000, '그 외': 341000},
      7: {'식비': 420000, '쇼핑': 180000, '그 외': 95000},
      8: {'식비': 380000, '쇼핑': 257400, '그 외': 116400},
    },
    2024: {
      12: {'식비': 310000, '쇼핑': 150000, '그 외': 87000},
    },
  };

  int currentYear = DateTime.now().year;
  int currentMonth = DateTime.now().month;

  // ==== 기본 데이터 ====
  String email = 'walkholic@likelion.org';
  int points = 0;

  // 프로필 & 지역
  String? profileImageUrl;
  String regionDisplay = '지역 미설정'; // 닉네임과 이메일 사이에 표시될 텍스트

  @override
  void initState() {
    super.initState();
    _loadKakaoProfile();
    _loadRegion();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId'); // 로그인 시 저장한 값
      if (uid == null || uid.isEmpty) return;

      final balance = await ApiClient.fetchUserPoint(uid);
      if (!mounted) return;
      setState(() => points = balance);
    } catch (e) {
      debugPrint('포인트 불러오기 실패: $e');
    }
  }

  Future<void> _loadKakaoProfile() async {
    try {
      final user = await UserApi.instance.me();
      if (!mounted) return;
      setState(() {
        profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;
        email = user.kakaoAccount?.email ?? email;
      });
    } catch (e) {
      debugPrint('카카오 프로필 불러오기 실패: $e');
    }
  }

  Future<void> _loadRegion() async {
    final prefs = await SharedPreferences.getInstance();
    final sido = prefs.getString('region_sido') ?? '';
    final sigungu = prefs.getString('region_sigungu') ?? '';
    final eupmyeondong = prefs.getString('region_eupmyeondong') ?? '';

    String formatted;
    if (sido.isEmpty && sigungu.isEmpty && eupmyeondong.isEmpty) {
      formatted = '지역 미설정';
    } else if (eupmyeondong.isNotEmpty) {
      formatted = '$sido $sigungu $eupmyeondong';
    } else if (sigungu.isNotEmpty) {
      formatted = '$sido $sigungu';
    } else {
      formatted = sido;
    }

    if (!mounted) return;
    setState(() {
      regionDisplay = formatted;
    });
  }

  // ==== 헬퍼 ====
  Map<String, int> _getCategoriesForMonth(int year, int month) {
    return yearlyData[year]?[month] ?? {'식비': 0, '쇼핑': 0, '그 외': 0};
  }

  int _calcTotal(Map<String, int> cats) {
    return cats.values.fold(0, (a, b) => a + b);
  }

  String _fmt(int v) {
    final s = v.toString();
    final b = StringBuffer();
    var c = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      b.write(s[i]);
      c++;
      if (c % 3 == 0 && i != 0) b.write(',');
    }
    return b.toString().split('').reversed.join();
  }

  void _prevMonth() {
    setState(() {
      if (currentMonth == 1) {
        currentMonth = 12;
        currentYear--;
      } else {
        currentMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (currentMonth == 12) {
        currentMonth = 1;
        currentYear++;
      } else {
        currentMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const keyColor = Color(0xFF5E2AD7);

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 정보', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileCard(context),
            const SizedBox(height: 12),
            const Divider(height: 24),

            const Text('내 소비 리포트',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _reportCard(),

            const SizedBox(height: 12),
            _quickMenuCard(context, keyColor),

            const SizedBox(height: 12),
            _policyCard(),

            const SizedBox(height: 18),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WithdrawalScreen()),
                  );
                },
                child: const Text(
                  '회원 탈퇴',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==== 프로필 카드 ====
  Widget _profileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('안녕하세요', style: TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${widget.nickname} 님',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFAED2E2),
                backgroundImage:
                profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                child: profileImageUrl == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ],
          ),

          // ▽▽▽ 지역 표시 + 변경 ▽▽▽
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              // 지역 변경으로 이동 -> 돌아오면 갱신
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegionSettingScreen(forceMode: false),
                ),
              );
              if (changed == true) {
                await _loadRegion();
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Color(0xFF5E2AD7)),
                const SizedBox(width: 4),
                Text(
                  regionDisplay,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF5E2AD7),
                  ),
                ),
              ],
            ),
          ),
          // △△△ 지역 표시 + 변경 △△△

          const SizedBox(height: 6),
          Text(email, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 14),

          // 포인트 / 이용내역 바
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('내 포인트',
                            style:
                            TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text('${_fmt(points)} point',
                            style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 42, color: Colors.black12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      alignment: Alignment.center,
                      child: const Text('이용내역',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==== 소비 리포트 카드 ====
  Widget _reportCard() {
    final categories = _getCategoriesForMonth(currentYear, currentMonth);
    final total = _calcTotal(categories);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
              Text('$currentYear년 $currentMonth월',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('이번달 소비 금액',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${_fmt(total)} 원',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          _categoryRow(Colors.red, '식비', categories['식비'] ?? 0),
          const SizedBox(height: 6),
          _categoryRow(Colors.green, '쇼핑', categories['쇼핑'] ?? 0),
          const SizedBox(height: 6),
          _categoryRow(const Color(0xFF5270FF), '그 외', categories['그 외'] ?? 0),
        ],
      ),
    );
  }

  Widget _categoryRow(Color color, String label, int value) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text('${_fmt(value)}원',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ==== 빠른 메뉴 카드 ====
  Widget _quickMenuCard(BuildContext context, Color keyColor) {
    Widget item(IconData icon, String label, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: keyColor),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: item(Icons.campaign_outlined, '공지사항', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NoticeScreen()),
                  );
                }),
              ),
              Container(width: 1, height: 60, color: Colors.black12),
              Expanded(
                child: item(Icons.person_add_alt_1_outlined, '친구초대', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            InviteScreen(nickname: widget.nickname)),
                  );
                }),
              ),
            ],
          ),
          Container(height: 1, color: Colors.black12),
          Row(
            children: [
              Expanded(
                child: item(Icons.headset_mic_outlined, '고객센터', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                  );
                }),
              ),
              Container(width: 1, height: 60, color: Colors.black12),
              Expanded(
                child: item(Icons.celebration_outlined, '이벤트', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EventCardScreen()),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==== 정책 카드 ====
  Widget _policyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text('서비스 이용약관'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('위치기반 서비스 이용약관'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationTermsScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('앱 버전'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppVersionScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
/// 지역 텍스트 위젯
/// - 부모의 regionDisplay를 직접 참조하려면 StatefulBuilder를 쓰거나
///   여기처럼 Inherited 접근이 없어 간단히 빌더 콜백으로도 처리할 수 있지만,
///   이번 구현은 상위 state의 값을 그대로 Text에 바인딩하도록
///   _MyPageScreenState의 build 과정에서 setState 시 갱신되도록 합니다.
///   따라서 이 위젯은 상수 형태로 두고, 상위에서 rebuild되며 텍스트가 갱신됩니다.
class _RegionText extends StatelessWidget {
  const _RegionText();

  @override
  Widget build(BuildContext context) {
    // 상위 State에 접근하기 위해 context.findAncestorStateOfType 사용
    final state = context.findAncestorStateOfType<_MyPageScreenState>();
    final value = state?.regionDisplay ?? '지역 미설정';
    return Text(
      value,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black87,
        decoration: TextDecoration.underline,
        decorationColor: Color(0xFF5E2AD7),
      ),
    );
  }
}
