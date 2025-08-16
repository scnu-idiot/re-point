import 'package:flutter/material.dart';
// 앱 버전을 동적으로 표시하려면 pubspec.yaml에 package_info_plus 추가하세요:
// dependencies:
//   package_info_plus: ^8.0.0
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionScreen extends StatefulWidget {
  const AppVersionScreen({super.key});

  @override
  State<AppVersionScreen> createState() => _AppVersionScreenState();
}

class _AppVersionScreenState extends State<AppVersionScreen> {
  String _version = '-';
  String _buildNumber = '-';
  String _appName = 'RE:POINT';
  String _packageName = '-';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
        _appName = info.appName;
        _packageName = info.packageName;
      });
    } catch (_) {
      // 실패 시 기본값 유지
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        title: const Text(
          '앱 버전',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('앱 이름', _appName),
          _tile('패키지', _packageName),
          _tile('버전', _version),
          _tile('빌드', _buildNumber),
          const SizedBox(height: 8),
          const Text(
            '※ 스토어 배포/빌드에 따라 버전 표기가 달라질 수 있습니다.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _tile(String k, String v) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(k, style: const TextStyle(color: Colors.black54)),
      trailing: Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
