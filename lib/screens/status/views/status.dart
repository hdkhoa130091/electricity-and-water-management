import 'dart:async';
import 'package:done/services/khupho_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:done/screens/price_table/views/price_table_screen.dart';

class MonitorScreen extends StatefulWidget {
  final String khuPho;
  final String initialTongDien;
  final String initialTongNuoc;

  const MonitorScreen({
    super.key,
    required this.khuPho,
    required this.initialTongDien,
    required this.initialTongNuoc,
  });

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  late KhuPhoRuntimeState _state;
  StreamSubscription? _updateListener;
  final TextEditingController _thresholdController = TextEditingController();
  final KhuPhoStateManager _stateManager = KhuPhoStateManager.instance;

  @override
  void initState() {
    super.initState();
    _state = _stateManager.getStateFor(
      widget.khuPho,
      widget.initialTongDien,
      widget.initialTongNuoc,
    );

    _updateListener = _state.updateStream.listen((_) {
      if (mounted) setState(() {});
    });

    BangGiaHienTai.loadFromFirebase();

    _stateManager.loadFirebaseData(widget.khuPho);
  }

  @override
  void dispose() {
    _updateListener?.cancel();
    _thresholdController.dispose();
    super.dispose();
  }

  void _startScanAndShowDialog() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Chọn thiết bị ESP32"),
            content: SizedBox(
              width: double.maxFinite,
              child: StreamBuilder<List<ScanResult>>(
                stream: FlutterBluePlus.scanResults,
                initialData: const [],
                builder: (c, snapshot) {
                  if (snapshot.data!.isEmpty) return const Center(child: Text("Đang quét..."));
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final r = snapshot.data![index];
                      return ListTile(
                        title: Text(r.device.platformName.isNotEmpty ? r.device.platformName : "Không tên"),
                        subtitle: Text(r.device.remoteId.toString()),
                        onTap: () {
                          FlutterBluePlus.stopScan();
                          Navigator.pop(context);
                          _stateManager.connect(widget.khuPho, r.device);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            actions: [TextButton(onPressed: () { FlutterBluePlus.stopScan(); Navigator.pop(context); }, child: const Text("Hủy"))],
          );
        },
      ),
    );
  }

  void _disconnectDevice() { _stateManager.disconnect(widget.khuPho); }

  Future<void> _sendThreshold() async {
    FocusScope.of(context).unfocus();
    final value = _thresholdController.text;
    final message = await _stateManager.sendThreshold(widget.khuPho, value);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    if (!message.startsWith("Lỗi")) _thresholdController.clear();
  }

  Map<int, double> _getMonthlyTotals(List<DataPoint> readings) {
    Map<int, double> monthlyData = {};
    int currentYear = DateTime.now().year;
    for (var point in readings) {
      if (point.timestamp.year == currentYear) {
        int m = point.timestamp.month;
        if (!monthlyData.containsKey(m) || point.value > monthlyData[m]!) {
          monthlyData[m] = point.value;
        }
      }
    }
    return monthlyData;
  }

  @override
  Widget build(BuildContext context) {
    Map<int, double> monthlyElec = _getMonthlyTotals(_state.allElecReadings);
    Map<int, double> monthlyWater = _getMonthlyTotals(_state.allWaterReadings);
    var sortedElecMonths = monthlyElec.keys.toList()..sort();
    var sortedWaterMonths = monthlyWater.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A64FE),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quản Lý Điện Nước', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Khu phố ${widget.khuPho}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        actions: [
          _state.targetDevice != null
              ? IconButton(icon: const Icon(Icons.bluetooth_disabled, color: Colors.white), onPressed: _disconnectDevice)
              : IconButton(icon: const Icon(Icons.bluetooth_searching, color: Colors.white), onPressed: _startScanAndShowDialog)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _stateManager.simulateData(widget.khuPho);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi dữ liệu giả lập!")));
        },
        child: const Icon(Icons.bug_report),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_state.connectionStatus, style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _buildYearlySummary(_state.yearlyElecTotal, _state.yearlyWaterTotal),
            ),

            const SizedBox(height: 24),
            _buildThresholdSection(),

            const SizedBox(height: 24),
            _buildMonthlySection("Lượng điện hàng tháng", "kWh", sortedElecMonths, monthlyElec),

            const SizedBox(height: 24),
            _buildMonthlySection("Lượng nước hàng tháng", "m³", sortedWaterMonths, monthlyWater),

            const SizedBox(height: 24),
            _buildChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Thiết lập ngưỡng cảnh báo điện", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _thresholdController,
            decoration: const InputDecoration(labelText: 'Nhập ngưỡng (kWh)', border: OutlineInputBorder(), suffixText: "kWh"),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A64FE), foregroundColor: Colors.white), onPressed: _state.targetDevice != null ? _sendThreshold : null, child: const Text('Lưu Ngưỡng'))),
        ],
      ),
    );
  }

  Widget _buildYearlySummary(double elecTotal, double waterTotal) {
    final formatCurrency = NumberFormat("#,##0", "vi_VN");
    final elecCost = BangGiaHienTai.tinhTienDien(elecTotal);
    final waterCost = BangGiaHienTai.tinhTienNuoc(waterTotal);

    return Row(
      children: [
        Expanded(child: SummaryCard(title: 'Tổng điện/năm', value: '${elecTotal.toStringAsFixed(2)} kWh', cost: '${formatCurrency.format(elecCost)} VNĐ', color: const Color(0xFFF9A825))),
        const SizedBox(width: 16),
        Expanded(child: SummaryCard(title: 'Tổng nước/năm', value: '${waterTotal.toStringAsFixed(2)} m³', cost: '${formatCurrency.format(waterCost)} VNĐ', color: const Color(0xFF1E88E5))),
      ],
    );
  }

  Widget _buildMonthlySection(String title, String unit, List<int> sortedMonths, Map<int, double> monthlyData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: sortedMonths.isEmpty
              ? Container(alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: const Text("Chưa có dữ liệu"))
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sortedMonths.length,
            itemBuilder: (context, index) {
              int month = sortedMonths[index];
              double value = monthlyData[month]!;
              double prev = index > 0 ? monthlyData[sortedMonths[index - 1]]! : 0;
              double change = value - prev;
              return MonthlyDataCard(month: month.toString(), value: value.toStringAsFixed(2), change: "${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}", unit: unit, changeColor: change >= 0 ? Colors.red : Colors.green);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Row(children: [Icon(Icons.flash_on, color: Colors.red, size: 16), SizedBox(width: 4), Icon(Icons.water_drop, color: Colors.blue, size: 16), SizedBox(width: 8), Text("Biểu đồ tiêu thụ real-time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          IconButton(icon: Icon(_state.isChartPaused ? Icons.play_arrow : Icons.pause, color: const Color(0xFF4A64FE)), onPressed: () => _stateManager.toggleChartPause(widget.khuPho)),
        ]),
        const SizedBox(height: 20),
        InteractiveViewer(
          maxScale: 5.0, minScale: 0.5,
          child: SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(spots: _state.elecChartSpots, isCurved: true, color: Colors.red, barWidth: 3, dotData: const FlDotData(show: false)),
                  LineChartBarData(spots: _state.waterChartSpots, isCurved: true, color: Colors.blue, barWidth: 3, dotData: const FlDotData(show: false)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title, value, cost;
  final Color color;
  const SummaryCard({super.key, required this.title, required this.value, required this.cost, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)), const SizedBox(height: 8), Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(cost, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
    );
  }
}

class MonthlyDataCard extends StatelessWidget {
  final String month, value, change, unit;
  final Color changeColor;
  const MonthlyDataCard({super.key, required this.month, required this.value, required this.change, required this.unit, required this.changeColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tháng $month', style: TextStyle(color: Colors.grey[600])), Text(change, style: TextStyle(color: changeColor))]), Text('$value $unit', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
    );
  }
}