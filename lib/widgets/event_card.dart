import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EventCardScreen extends StatelessWidget {
  const EventCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_EventItem>[
      _EventItem(
        title: '🌟 친구야, RE:POINT 하자!',
        subtitle: '8월 친구 초대 이벤트',
        url: 'https://www.notion.so/RE-POINT-2497a334f94680daae22fa24c88fe20d?source=copy_link',
        thumbnail: null,
      ),
      _EventItem(
        title: '🌟 RE:챌린지',
        subtitle: '연속 방문 미션',
        url: 'https://www.notion.so/RE-2497a334f94680329144e3d08b777937?source=copy_link',
        thumbnail: null,
      ),
      _EventItem(
        title: '🌟 핫플레이스 리워드',
        subtitle: '지금이 기회!',
        url: 'https://www.notion.so/2497a334f94680d28c57c4276d83a814?source=copy_link',
        thumbnail: null,
      ),
      _EventItem(
        title: '🌟 영수증도 운이 따라야지!',
        subtitle: '랜덤 추첨 이벤트',
        url: 'https://www.notion.so/2497a334f94680a3a63ccf56336cf129?source=copy_link',
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
                builder: (_) => EventWebViewPage(
                  title: it.title,
                  initialUrl: it.url,
                ),
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
                  if (it.thumbnail != null) ...[
                    it.thumbnail!,
                    const SizedBox(width: 12),
                  ],
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

class EventWebViewPage extends StatefulWidget {
  final String title;
  final String initialUrl;

  const EventWebViewPage({
    super.key,
    required this.title,
    required this.initialUrl,
  });

  @override
  State<EventWebViewPage> createState() => _EventWebViewPageState();
}

class _EventWebViewPageState extends State<EventWebViewPage> {
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

class _EventItem {
  final String title;
  final String subtitle;
  final String url;
  final Widget? thumbnail;

  _EventItem({
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