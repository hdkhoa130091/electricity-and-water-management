import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

class BangGiaHienTai {
  static double dienBac1 = 1806;
  static double dienBac2 = 1866;
  static double dienBac3 = 2167;
  static double dienBac4 = 2729;
  static double dienBac5 = 3050;
  static double dienBac6 = 3151;

  static double nuocCoBan = 6869;
  static double thueMoiTruong = 0.10;
  static double thueVAT = 0.05;

  static Future<void> loadFromFirebase() async {
    try {
      final ref = FirebaseDatabase.instance.ref('pricing');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        dienBac1 = double.tryParse(data['dien_bac_1'].toString()) ?? 1806;
        dienBac2 = double.tryParse(data['dien_bac_2'].toString()) ?? 1866;
        dienBac3 = double.tryParse(data['dien_bac_3'].toString()) ?? 2167;
        dienBac4 = double.tryParse(data['dien_bac_4'].toString()) ?? 2729;
        dienBac5 = double.tryParse(data['dien_bac_5'].toString()) ?? 3050;
        dienBac6 = double.tryParse(data['dien_bac_6'].toString()) ?? 3151;
        nuocCoBan = double.tryParse(data['nuoc_co_ban'].toString()) ?? 6869;
      }
    } catch (e) {
      debugPrint("Lỗi tải bảng giá: $e");
    }
  }

  static double tinhTienDien(double kwh) {
    if (kwh <= 0) return 0;
    double totalCost = 0;
    double remaining = kwh;

    if (remaining > 0) {
      double amount = (remaining > 50) ? 50 : remaining;
      totalCost += amount * dienBac1;
      remaining -= amount;
    }
    if (remaining > 0) {
      double amount = (remaining > 50) ? 50 : remaining;
      totalCost += amount * dienBac2;
      remaining -= amount;
    }
    if (remaining > 0) {
      double amount = (remaining > 100) ? 100 : remaining;
      totalCost += amount * dienBac3;
      remaining -= amount;
    }
    if (remaining > 0) {
      double amount = (remaining > 100) ? 100 : remaining;
      totalCost += amount * dienBac4;
      remaining -= amount;
    }
    if (remaining > 0) {
      double amount = (remaining > 100) ? 100 : remaining;
      totalCost += amount * dienBac5;
      remaining -= amount;
    }
    if (remaining > 0) {
      totalCost += remaining * dienBac6;
    }
    return totalCost * 1.08;
  }

  static double tinhTienNuoc(double m3) {
    if (m3 <= 0) return 0;
    double thanhTien = m3 * nuocCoBan;
    double phiBVMT = thanhTien * thueMoiTruong;
    double thueGTGT = (thanhTien + phiBVMT) * thueVAT;
    return thanhTien + phiBVMT + thueGTGT;
  }
}

class PriceTableScreen extends StatefulWidget {
  const PriceTableScreen({super.key});

  @override
  State<PriceTableScreen> createState() => _PriceTableScreenState();
}

class _PriceTableScreenState extends State<PriceTableScreen> {
  @override
  void initState() {
    super.initState();
    BangGiaHienTai.loadFromFirebase().then((_) {
      if(mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Bảng Giá Hiện Hành"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSectionHeader("⚡ Giá Điện Sinh Hoạt (EVN)", Colors.orange),
            const SizedBox(height: 10),
            Container(
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  _buildTableHeader(),
                  _buildTableRow("Bậc 1", "0 - 50 kWh", "${fmt.format(BangGiaHienTai.dienBac1)} ₫"),
                  _buildTableRow("Bậc 2", "51 - 100 kWh", "${fmt.format(BangGiaHienTai.dienBac2)} ₫"),
                  _buildTableRow("Bậc 3", "101 - 200 kWh", "${fmt.format(BangGiaHienTai.dienBac3)} ₫"),
                  _buildTableRow("Bậc 4", "201 - 300 kWh", "${fmt.format(BangGiaHienTai.dienBac4)} ₫"),
                  _buildTableRow("Bậc 5", "301 - 400 kWh", "${fmt.format(BangGiaHienTai.dienBac5)} ₫"),
                  _buildTableRow("Bậc 6", "401 kWh trở lên", "${fmt.format(BangGiaHienTai.dienBac6)} ₫"),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader("💧 Giá Nước Sạch", Colors.blue),
            const SizedBox(height: 10),
            Container(
              decoration: _boxDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildWaterRow("Giá tiêu chuẩn", "${fmt.format(BangGiaHienTai.nuocCoBan)} ₫ / m³"),
                  const Divider(),
                  _buildWaterRow("Phí bảo vệ môi trường", "${(BangGiaHienTai.thueMoiTruong * 100).toInt()}%"),
                  const Divider(),
                  _buildWaterRow("Thuế GTGT (VAT)", "${(BangGiaHienTai.thueVAT * 100).toInt()}%"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))],
    );
  }
  Widget _buildSectionHeader(String title, Color color) {
    return Row(children: [Container(width: 5, height: 25, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87))]);
  }
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(color: Color(0xFFFFF3E0), borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))),
      child: const Row(children: [Expanded(flex: 2, child: Text("Bậc thang", style: TextStyle(fontWeight: FontWeight.bold))), Expanded(flex: 3, child: Text("Sản lượng", style: TextStyle(fontWeight: FontWeight.bold))), Expanded(flex: 2, child: Text("Đơn giá", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right))]),
    );
  }
  Widget _buildTableRow(String bac, String sanLuong, String gia) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), child: Row(children: [Expanded(flex: 2, child: Text(bac, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(flex: 3, child: Text(sanLuong, style: TextStyle(color: Colors.grey[700]))), Expanded(flex: 2, child: Text(gia, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange), textAlign: TextAlign.right))]));
  }
  Widget _buildWaterRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 16)), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue))]));
  }
}