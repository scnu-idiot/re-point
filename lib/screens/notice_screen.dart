// notice_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_NoticeItem>[
      _NoticeItem(
        title: '📢 RE:챌린지 이벤트 기간 연장 안내',
        subtitle: 'RE:챌린지에 보내주신 뜨거운 관심과 참여에 감사드립니다!',
        url: 'https://www.notion.so/RE-2497a334f94680f49734e5ddbe918ba5?source=copy_link', // 1번: 썸네일 없음
        thumbnail: null,
      ),
      _NoticeItem(
        title: '📢 8월 3주차 핫플레이스 장소 안내',
        subtitle: '📍 8월 3주차 핫플레이스 – 순천시 옥리단길',
        url: 'https://www.notion.so/8-3-2497a334f94680a18988fecb91cb9ed7?source=copy_link',
        thumbnail: null,
      ),
      _NoticeItem(
        title: '📢 8월 2주차 핫플레이스 장소 안내',
        subtitle: '📍 8월 2주차 핫플레이스 – 순천시 금당',
        url: 'https://www.notion.so/8-2-2497a334f94680f491f7ec204d7d144d?source=copy_link',
        thumbnail: null,
      ),
      _NoticeItem(
        title: '📢 8월 1주차 핫플레이스 장소 안내',
        subtitle: '📍 8월 1주차 핫플레이스 – 순천시 서면',
        url: 'https://www.notion.so/8-1-2497a334f946802db5e8c2f7c2298e9b?source=copy_link',
        thumbnail: null,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xFFF8F4FF),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '공지사항',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final it = items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoticeWebViewPage(title: it.title, initialUrl: it.url),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 썸네일 (첫 번째 아이템은 null이므로 표시 안 함)
                  if (it.thumbnail != null) ...[
                    it.thumbnail!,
                    const SizedBox(width: 12),
                  ],
                  // 텍스트
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          it.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.black54,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class NoticeWebViewPage extends StatefulWidget {
  final String title;
  final String initialUrl;

  const NoticeWebViewPage({
    super.key,
    required this.title,
    required this.initialUrl,
  });

  @override
  State<NoticeWebViewPage> createState() => _NoticeWebViewPageState();
}

class _NoticeWebViewPageState extends State<NoticeWebViewPage> {
  late final WebViewController _controller;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p / 100),
          onPageFinished: (_) => setState(() => _progress = 0),
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _progress > 0
              ? LinearProgressIndicator(
            value: _progress,
            minHeight: 2,
            backgroundColor: Colors.black12,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF5E2AD7)),
          )
              : const SizedBox.shrink(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class _NoticeItem {
  final String title;
  final String subtitle;
  final String url;
  final Widget? thumbnail;

  _NoticeItem({
    required this.title,
    required this.subtitle,
    required this.url,
    this.thumbnail,
  });
}

class _Thumb extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _Thumb({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.black54, size: 28),
    );
  }
}