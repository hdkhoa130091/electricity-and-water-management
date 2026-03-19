import 'dart:async';
import 'package:done/Data/Data.dart';
import 'package:done/screens/add_khupho/views/them_khupho.dart';
import 'package:done/screens/xoa_khupho/views/xoa_khupho.dart';
import 'package:done/screens/status/views/status.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:done/services/khupho_state_manager.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:done/screens/price_table/views/price_table_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  StreamSubscription? _mainScreenUpdateListener;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFirebaseData();
    _mainScreenUpdateListener =
        KhuPhoStateManager.instance.mainScreenUpdateStream.listen((_) {
          if (mounted) {
            setState(() {});
          }
        });
  }

  Future<void> _loadFirebaseData() async {
    try {
      final ref = FirebaseDatabase.instance.ref('summaries');
      final snapshot = await ref.get();

      MyData.clear();

      if (snapshot.exists && snapshot.value != null) {
        final dynamic snapshotValue = snapshot.value;

        if (snapshotValue is Map<dynamic, dynamic>) {
          final data = snapshotValue;
          data.forEach((key, value) {
            final khuPhoId = key as String;
            final summaryData = value as Map<dynamic, dynamic>;
            MyData.add({
              'KhuPho': khuPhoId,
              'TongDien': '${summaryData['tong_dien_nam'] ?? 0} kWh',
              'TongNuoc': '${summaryData['tong_nuoc_nam'] ?? 0} m³',
            });
          });
        } else if (snapshotValue is List<Object?>) {
          final dataList = snapshotValue;
          for (var item in dataList) {
            if (item != null && item is Map<dynamic, dynamic>) {
              final summaryData = item;
              final khuPhoId = summaryData['ten_khu_pho'] as String?;

              if (khuPhoId != null) {
                MyData.add({
                  'KhuPho': khuPhoId,
                  'TongDien': '${summaryData['tong_dien_nam'] ?? 0} kWh',
                  'TongNuoc': '${summaryData['tong_nuoc_nam'] ?? 0} m³',
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu Firebase: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải dữ liệu: $e")),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mainScreenUpdateListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildWelcomeBanner(),
            const SizedBox(height: 30),
            _buildActionRow(), 
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : MyData.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20.0,
                  mainAxisSpacing: 20.0,
                  childAspectRatio: 1.2,
                ),
                itemCount: MyData.length,
                itemBuilder: (context, index) {
                  final data = MyData[index];
                  return _buildKhuPhoCard(data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Quản Lý Điện Nước",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  "Cho Khu Phố",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.width / 6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.tertiary,
          ],
          transform: const GradientRotation(3.14 / 4),
        ),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: const Center(
        child: Text(
          "Xin chào, Quản trị viên",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PriceTableScreen()),
            );
          },
          child: Container(
            width: 180,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                "Giá điện + nước",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),

        Row(
          children: [
            _buildActionButton(
              icon: CupertinoIcons.plus,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddKhupho()),
              ).then((_) {
                setState(() { _isLoading = true; });
                _loadFirebaseData();
              }),
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: CupertinoIcons.minus,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const XoaKhuPhoScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(child: Icon(icon, size: 24)),
      ),
    );
  }

  Widget _buildKhuPhoCard(Map<String, String> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MonitorScreen(
              khuPho: data['KhuPho']!,
              initialTongDien: data['TongDien'] ?? '0 kWh',
              initialTongNuoc: data['TongNuoc'] ?? '0 m³',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Khu Phố ${data['KhuPho']}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow("Tổng điện:", data['TongDien'] ?? '0 kWh',
                const Color(0xFFFFC107)),
            const SizedBox(height: 6),
            _buildInfoRow("Tổng nước:", data['TongNuoc'] ?? '0 m³',
                const Color(0xFF2196F3)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: valueColor),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_city, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Chưa có khu phố nào",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Nhấn + để thêm khu phố mới",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}