import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/region_data.dart';

// TODO: (백엔드 연동 준비)
// - Firebase Firestore 저장 예시
//   await FirebaseFirestore.instance.collection('users')
//     .doc(currentUserId).set({
//       'region': {
//         'do': selectedProvince,
//         'sigungu': selectedCity,
//         'eupmyeondong': selectedTown,
//       }
//     }, SetOptions(merge: true));
// - Spring Boot 저장 예시
//   await http.post(Uri.parse('https://api.example.com/users/region'),
//     headers: {'Authorization': 'Bearer $token'},
//     body: jsonEncode({...}));

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

  Future<void> _save() async {
    if (!canSave) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('region_do', selectedProvince!);
    await prefs.setString('region_sigungu', selectedCity!);
    await prefs.setString('region_eupmyeondong', selectedTown!);
    await prefs.setBool('region_set', true);

    if (!mounted) return;
    Navigator.pop(context, true); // 저장 성공
  }

  @override
  Widget build(BuildContext context) {
    const keyColor = Color(0xFF5E2AD7);

    return Scaffold(
      appBar: AppBar(
        title: const Text('지역 설정', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Padding(
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
                  .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              ))
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
              onChanged: (v) {
                setState(() => selectedTown = v);
              },
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('지역 저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            if (!widget.forceMode) // 선택사항: 건너뛰기 버튼
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('건너뛰기'),
              ),
          ],
        ),
      ),
    );
  }
}
