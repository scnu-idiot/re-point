import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
// 백엔드 연결 시 주석 해제하세요.
// import 'package:http/http.dart' as http;

import '../widgets/profile_appbar.dart';

/// InviteScreen (백엔드 연동 전 단계 버전)
/// - 지금은 더미 데이터로 화면 표시
/// - 추후 /me 연동 시, 아래 주석된 코드와 import(http)만 해제하면 됨
class InviteScreen extends StatefulWidget {
  final String nickname;

  // ↓ 나중에 실제 엔드포인트/토큰으로 교체 (현재는 사용 안 함)
  // final String meEndpoint;
  // final String authToken;

  const InviteScreen({
    super.key,
    required this.nickname,
    // required this.meEndpoint,
    // required this.authToken,
  });

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  // ====== 더미 데이터(화면 확인용) ======
  String? referralLink = 'https://your.page.link/abcd?ref=AB12CD34';
  int invitedCount = 4;
  int get earnedCredit => invitedCount * 100;

  bool loading = false; // 백엔드 붙이면 true로 시작해서 로딩 처리
  String? error;        // 백엔드 에러 메시지용

  @override
  void initState() {
    super.initState();
    // 나중에 백엔드 연결 시 주석 해제
    // _loadMe();
  }

  /// 🔗 백엔드 연결 (나중에 주석 해제해서 사용)
  /*
  Future<void> _loadMe() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await http.get(
        Uri.parse(widget.meEndpoint),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );

      if (res.statusCode == 200) {
        final j = json.decode(res.body) as Map<String, dynamic>;
        setState(() {
          referralLink = j['referralLink'] as String?;
          invitedCount = (j['invitedCount'] ?? 0) as int;
          earnedCredit = (j['earnedCredit'] ?? 0) as int;
          loading = false;
        });
      } else {
        setState(() {
          error = '서버 오류: ${res.statusCode}';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = '네트워크 오류: $e';
        loading = false;
      });
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: ProfileAppBar(nickname: '친구초대'),
      body: Builder(
        builder: (context) {
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (error != null) {
            return _ErrorView(
              message: error!,
              onRetry: () {
                // _loadMe(); // 백엔드 붙이면 활성화
              },
            );
          }
          if (referralLink == null) {
            return _ErrorView(
              message: '초대 링크가 없습니다.',
              onRetry: () {
                // _loadMe(); // 백엔드 붙이면 활성화
              },
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 일러스트 (에셋으로 교체 권장)
                Center(
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: Image.asset('assets/images/invite.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  '친구를 초대하면\n친구도 나도 100 포인트 적립',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  '친구에게 100 포인트를 선물하고, 친구가 전화번호 인증 회원가입 후 첫 로그인을 하면 나에게도 100 포인트 적립돼요!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                _LinkCopyBox(
                  link: referralLink!,
                  onCopy: () async {
                    await Clipboard.setData(ClipboardData(text: referralLink!));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('링크가 복사되었어요.')),
                    );
                  },
                ),
                const SizedBox(height: 16),

                const Divider(height: 24),

                _InfoRow(
                  icon: Icons.group_outlined,
                  title: '지금까지 초대한 친구',
                  valueText: '$invitedCount 명',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.receipt_long_outlined,
                  title: '지금까지 받은 포인트',
                  valueText: '$earnedCredit',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 링크 + COPY 버튼 박스
class _LinkCopyBox extends StatelessWidget {
  final String link;
  final VoidCallback onCopy;

  const _LinkCopyBox({
    required this.link,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.ios_share_outlined, size: 20),
          ),
          Expanded(
            child: Text(
              link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onCopy,
            child: const Text('COPY'),
          ),
        ],
      ),
    );
  }
}

/// 하단 정보 1행
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueText;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            valueText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 에러/재시도 뷰
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도'))
          ],
        ),
      ),
    );
  }
}
