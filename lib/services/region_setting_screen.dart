import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/region_data.dart';
import '../services/api_client.dart';

class RegionSettingScreen extends StatefulWidget {
  final bool forceMode; // true면 '건너뛰기' 없이 반드시 저장해야 함
  const RegionSettingScreen({super.key, this.forceMode = true});

  @override
  State<RegionSettingScreen> createState() => _RegionSettingScreenState();
}

class _RegionSettingScreenState extends State<RegionSettingScreen> {
  String? selectedProvince;
  String? selectedCity;
  String? selectedTown;

  bool _loading = false;

  List<String> get cityList {
    if (selectedProvince == null) return [];
    return RegionData.citiesByProvince[selectedProvince] ?? [];
  }

  List<String> get townList {
    if (selectedProvince == '전라남도' && selectedCity == '순천시') {
      return RegionData.townsByJeonnam['순천시'] ?? [];
    }
    return [];
  }

  bool get canSave =>
      selectedProvince != null &&
          selectedCity != null &&
          selectedTown != null &&
          RegionData.isSelectable(selectedProvince!, selectedCity);

  // --------- 공통: 프리퍼런스에서 uid 만들기 ----------
  Future<String?> _readUid() async {
    final prefs = await SharedPreferences.getInstance();
    // KakaoLoginService에서 저장한 값들
    final rawId = prefs.getString('userId');           // ex) "4386247443"
    final provider = prefs.getString('loginProvider'); // "kakao" | "google"
    if (rawId == null || rawId.isEmpty) return null;

    // 서버 문서 id는 "kakao:{id}" 형태이므로 prefix 붙여 사용
    if (provider == 'kakao') return '$rawId';
    // 구글을 쓰면 'google:'로 맞추면 됨(백엔드와 규칙 통일)
    if (provider == 'google') return '$rawId';
    // 그 외엔 raw 그대로
    return rawId;
  }

  // --------- 서버에서 현재 지역값 불러오기 ----------
  Future<void> _loadFromServer() async {
    setState(() => _loading = true);
    try {
      final uid = await _readUid();
      if (uid == null) return;

      final user = await ApiClient.getUser(uid); // 404면 null 반환
      if (user == null) return;

      final rp = (user['regionProvince'] as String?)?.trim();
      final rc = (user['regionCity'] as String?)?.trim();
      final rd = (user['regionDistrict'] as String?)?.trim();

      if (rp != null && rc != null && rd != null) {
        setState(() {
          selectedProvince = rp;
          selectedCity = rc;
          selectedTown = rd;
        });

        // 로컬에도 동기화
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('region_do', rp);
        await prefs.setString('region_sigungu', rc);
        await prefs.setString('region_eupmyeondong', rd);
        await prefs.setBool('region_set', true);
      }
    } catch (e) {
      // 굳이 토스트 안 띄워도 됨. 콘솔만.
      // debugPrint('loadFromServer error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --------- 저장 ----------
  Future<void> _save() async {
    if (!canSave) return;
    setState(() => _loading = true);

    try {
      final uid = await _readUid();
      if (uid == null) throw Exception('로그인 정보가 없습니다.');

      // 1) 우선 /region 엔드포인트 시도
      Map<String, dynamic> updated;
      try {
        updated = await ApiClient.patchRegion(
          uid: uid,
          province: selectedProvince!,
          city: selectedCity!,
          district: selectedTown!,
        );
      } catch (_) {
        // 2) 서버가 아직 /region이 없다면 /address 엔드포인트로 대체
        updated = await ApiClient.updateAddress(
          uid: uid,
          regionProvince: selectedProvince!,
          regionCity: selectedCity!,
          regionDistrict: selectedTown!,
        );
      }

      // 로컬 캐시도 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('region_do', selectedProvince!);
      await prefs.setString('region_sigungu', selectedCity!);
      await prefs.setString('region_eupmyeondong', selectedTown!);
      await prefs.setBool('region_set', true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지역이 저장되었습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지역 저장에 실패했어요. 잠시 후 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFromServer();
  }

  @override
  Widget build(BuildContext context) {
    const keyColor = Color(0xFF5E2AD7);

    return Scaffold(
      appBar: AppBar(
        title: const Text('지역 설정', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: AbsorbPointer(
        absorbing: _loading,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('도 선택', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedProvince,
                items: RegionData.provinces
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedProvince = v;
                    selectedCity = null;
                    selectedTown = null;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '시·도 선택',
                ),
              ),
              const SizedBox(height: 16),

              const Text('시/군/구 선택', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCity,
                items: cityList
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedCity = v;
                    selectedTown = null;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '시·군·구 선택',
                ),
              ),
              const SizedBox(height: 16),

              const Text('읍/면/동 선택', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedTown,
                items: townList
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => selectedTown = v),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '읍/면/동 선택',
                ),
              ),
              const SizedBox(height: 20),

              if (!(RegionData.isSelectable(selectedProvince ?? '', selectedCity)))
                Row(
                  children: const [
                    Icon(Icons.info_outline, size: 18, color: Colors.redAccent),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '현재는 전라남도 → 순천시만 설정 가능합니다.',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: keyColor,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('지역 저장',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              if (!widget.forceMode)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('건너뛰기'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}