
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:done/Data/Data.dart'; 
import 'package:firebase_database/firebase_database.dart';

class Warning {
  final String id;
  final String khuPhoId;
  final double value;
  final double threshold;
  final DateTime timestamp;

  Warning({
    required this.id,
    required this.khuPhoId,
    required this.value,
    required this.threshold,
    required this.timestamp,
  });
}


final Guid dataCharUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");
final Guid thresholdCharUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a9"); 

class DataPoint {
  final DateTime timestamp;
  final double value;

  DataPoint(this.timestamp, this.value);

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
    };
  }
}

class KhuPhoRuntimeState {
  String connectionStatus = "Chưa kết nối thiết bị nào";
  BluetoothDevice? targetDevice;
  StreamSubscription<List<int>>? dataSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;
  BluetoothCharacteristic? thresholdCharacteristic;

  List<DataPoint> allElecReadings = [];
  List<DataPoint> allWaterReadings = [];
  List<FlSpot> elecChartSpots = [];
  List<FlSpot> waterChartSpots = [];
  double chartCounter = 0;
  bool isChartPaused = false;

  double yearlyElecTotal;
  double yearlyWaterTotal;

  double? warningThreshold;

  final StreamController<void> _updateController = StreamController.broadcast();
  Stream<void> get updateStream => _updateController.stream;

  KhuPhoRuntimeState({
    required this.yearlyElecTotal,
    required this.yearlyWaterTotal,
  });

  void notifyUI() {
    if (!_updateController.isClosed) {
      _updateController.add(null);
    }
  }

  void dispose() {
    _updateController.close();
    dataSubscription?.cancel();
    connectionSubscription?.cancel();
    targetDevice?.disconnect();
  }
}


class KhuPhoStateManager {
  KhuPhoStateManager._privateConstructor();
  static final KhuPhoStateManager instance =
  KhuPhoStateManager._privateConstructor();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final Map<String, KhuPhoRuntimeState> _states = {};
  final StreamController<void> _mainScreenUpdater = StreamController.broadcast();
  Stream<void> get mainScreenUpdateStream => _mainScreenUpdater.stream;

  final List<Warning> activeWarnings = [];
  final StreamController<void> _warningUpdater = StreamController.broadcast();
  Stream<void> get warningUpdateStream => _warningUpdater.stream;

  List<Warning> getWarnings() => activeWarnings;

  void removeWarning(String warningId) {
    activeWarnings.removeWhere((w) => w.id == warningId);
    if (!_warningUpdater.isClosed) {
      _warningUpdater.add(null);
    }
  }

  double _parseKWh(String text) =>
      double.tryParse(text.replaceAll(' kWh', '').trim()) ?? 0.0;
  double _parseM3(String text) =>
      double.tryParse(text.replaceAll(' m³', '').trim()) ?? 0.0;

  KhuPhoRuntimeState getStateFor(
      String khuPhoId, String initialElec, String initialWater) {
    if (!_states.containsKey(khuPhoId)) {
      _states[khuPhoId] = KhuPhoRuntimeState(
        yearlyElecTotal: _parseKWh(initialElec),
        yearlyWaterTotal: _parseM3(initialWater),
      );
    }
    return _states[khuPhoId]!;
  }


  Future<void> deleteKhuPho(String khuPhoId) async {
    final summaryRef = _database.ref('summaries/$khuPhoId');
    final readingRef = _database.ref('readings/$khuPhoId');
    try {
      await Future.wait([summaryRef.remove(), readingRef.remove()]);
      final state = _states.remove(khuPhoId);
      state?.dispose();
      MyData.removeWhere((e) => e['KhuPho'] == khuPhoId);
      if (!_mainScreenUpdater.isClosed) _mainScreenUpdater.add(null);
    } catch (e) {
      debugPrint("Lỗi khi xóa $khuPhoId: $e");
    }
  }

  Future<void> _updateFirebaseSummary(String khuPho, KhuPhoRuntimeState state) async {
    try {
      final ref = _database.ref('summaries/$khuPho');
      await ref.update({
        'tong_dien_nam': state.yearlyElecTotal,
        'tong_nuoc_nam': state.yearlyWaterTotal,
        'ten_khu_pho': khuPho,
        'cap_nhat_luc': ServerValue.timestamp,
      });
    } catch (e) { print('Lỗi update summary: $e'); }
  }

  Future<void> _updateMonthlyReading(String khuPho, String type, DataPoint newReading) async {
    try {
      final int month = newReading.timestamp.month;
      final ref = _database.ref('readings/$khuPho/$type/$month');
      await ref.set(newReading.toJson());
    } catch (e) { print('Lỗi update monthly: $e'); }
  }


  Future<void> loadFirebaseData(String khuPhoId) async {
    debugPrint("--- 📥 TẢI DỮ LIỆU CHO $khuPhoId ---");
    final state = getStateFor(khuPhoId, "0", "0");

    try {
      final summaryRef = _database.ref('summaries/$khuPhoId');
      final summarySnapshot = await summaryRef.get();
      if (summarySnapshot.exists) {
        final data = summarySnapshot.value as Map<dynamic, dynamic>;
        state.yearlyElecTotal = double.tryParse(data['tong_dien_nam'].toString()) ?? 0;
        state.yearlyWaterTotal = double.tryParse(data['tong_nuoc_nam'].toString()) ?? 0;
      }

      final readingRef = _database.ref('readings/$khuPhoId');
      final readingSnapshot = await readingRef.get();

      if (readingSnapshot.exists) {
        final data = readingSnapshot.value as Map<dynamic, dynamic>;
        state.allElecReadings.clear();
        state.allWaterReadings.clear();
        state.elecChartSpots.clear();
        state.waterChartSpots.clear();
        state.chartCounter = 0;

        if (data.containsKey('dien')) {
          final dData = data['dien'];
          if(dData is Map) {
            dData.forEach((k, v) => state.allElecReadings.add(DataPoint(DateTime.parse(v['timestamp']), double.parse(v['value'].toString()))));
          } else if (dData is List) {
            for(var i in dData) if(i!=null) state.allElecReadings.add(DataPoint(DateTime.parse(i['timestamp']), double.parse(i['value'].toString())));
          }
        }
        if (data.containsKey('nuoc')) {
          final nData = data['nuoc'];
          if(nData is Map) {
            nData.forEach((k, v) => state.allWaterReadings.add(DataPoint(DateTime.parse(v['timestamp']), double.parse(v['value'].toString()))));
          } else if (nData is List) {
            for(var i in nData) if(i!=null) state.allWaterReadings.add(DataPoint(DateTime.parse(i['timestamp']), double.parse(i['value'].toString())));
          }
        }

        state.allElecReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        state.allWaterReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        for (var p in state.allElecReadings) {
          state.chartCounter++;
          state.elecChartSpots.add(FlSpot(state.chartCounter, p.value));
        }
        double tempCounter = 0;
        for (var p in state.allWaterReadings) {
          tempCounter++;
          state.waterChartSpots.add(FlSpot(tempCounter, p.value));
        }
        if (tempCounter > state.chartCounter) state.chartCounter = tempCounter;
      }
      state.notifyUI();
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu: $e");
    }
  }


  Future<void> connect(String khuPhoId, BluetoothDevice device) async {
    final state = getStateFor(khuPhoId, "0", "0");
    await state.targetDevice?.disconnect();
    state.dataSubscription?.cancel();
    state.connectionSubscription?.cancel();
    state.targetDevice = device;
    state.connectionStatus = "Đang kết nối...";
    state.notifyUI();
    try {
      await device.connect();
      state.connectionStatus = "Đã kết nối!";
      state.notifyUI();
      state.connectionSubscription = device.connectionState.listen((status) {
        if (status == BluetoothConnectionState.disconnected) {
          state.connectionStatus = "Mất kết nối.";
          state.targetDevice = null;
          state.notifyUI();
        }
      });
      _discoverServices(khuPhoId, device);
    } catch (e) {
      state.connectionStatus = "Lỗi kết nối.";
      state.notifyUI();
    }
  }

  void _discoverServices(String khuPhoId, BluetoothDevice device) async {
    final state = getStateFor(khuPhoId, "0", "0");
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid == dataCharUuid) {
          debugPrint("✅ Tìm thấy Data Characteristic");
          await characteristic.setNotifyValue(true);
          state.dataSubscription = characteristic.lastValueStream
              .listen((value) => _handleReceivedData(khuPhoId, value));
        }
        if (characteristic.uuid == thresholdCharUuid) {
          debugPrint("✅ Tìm thấy Threshold Characteristic");
          state.thresholdCharacteristic = characteristic;
          state.notifyUI();
        }
      }
    }
  }

  void _handleReceivedData(String khuPhoId, List<int> value) {
    final state = getStateFor(khuPhoId, "0", "0");
    if (value.isEmpty) return;
    String dataString = utf8.decode(value);

    try {
      final mainParts = dataString.split(';');
      if (mainParts.length != 3) return;

      final timestamp = int.parse(mainParts[0]);
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final newElecKWh = double.parse(mainParts[1].split(':')[1]);
      final newWaterM3 = double.parse(mainParts[2].split(':')[1]);

      final newElecPoint = DataPoint(dateTime, newElecKWh);
      final newWaterPoint = DataPoint(dateTime, newWaterM3);

      state.allElecReadings.add(newElecPoint);
      state.allWaterReadings.add(newWaterPoint);
      state.yearlyElecTotal = newElecKWh;
      state.yearlyWaterTotal = newWaterM3;

      _updateMonthlyReading(khuPhoId, 'dien', newElecPoint);
      _updateMonthlyReading(khuPhoId, 'nuoc', newWaterPoint);
      _updateFirebaseSummary(khuPhoId, state);

      if (!state.isChartPaused) {
        state.chartCounter++;
        state.elecChartSpots.add(FlSpot(state.chartCounter, newElecKWh));
        state.waterChartSpots.add(FlSpot(state.chartCounter, newWaterM3));
        if (state.elecChartSpots.length > 50) state.elecChartSpots.removeAt(0);
        if (state.waterChartSpots.length > 50) state.waterChartSpots.removeAt(0);
      }
      if (state.warningThreshold != null) {
        if (newElecKWh > state.warningThreshold!) {
          _updateOrAddWarning(khuPhoId, newElecKWh, state.warningThreshold!, dateTime);
        }
      }
      _updateMyData(khuPhoId);
      state.notifyUI();
    } catch (e) {
      debugPrint("Parse Error: $e");
    }
  }

  void _updateMyData(String khuPhoId) {
    final state = getStateFor(khuPhoId, "0", "0");
    final index = MyData.indexWhere((e) => e['KhuPho'] == khuPhoId);
    if (index != -1) {
      MyData[index]['TongDien'] = '${state.yearlyElecTotal.toStringAsFixed(2)} kWh';
      MyData[index]['TongNuoc'] = '${state.yearlyWaterTotal.toStringAsFixed(2)} m³';
      if (!_mainScreenUpdater.isClosed) _mainScreenUpdater.add(null);
    }
  }

  void _updateOrAddWarning(String khuPhoId, double value, double threshold, DateTime timestamp) {
    int existingIndex = activeWarnings.indexWhere((w) => w.khuPhoId == khuPhoId);
    final updatedWarning = Warning(
      id: timestamp.toIso8601String(),
      khuPhoId: khuPhoId,
      value: value,
      threshold: threshold,
      timestamp: timestamp,
    );
    if (existingIndex != -1) activeWarnings.removeAt(existingIndex);
    activeWarnings.insert(0, updatedWarning);
    if (!_warningUpdater.isClosed) _warningUpdater.add(null);
  }

  Future<void> disconnect(String khuPhoId) async {
    final state = getStateFor(khuPhoId, "0", "0");
    await state.targetDevice?.disconnect();
    state.dataSubscription?.cancel();
    state.connectionSubscription?.cancel();
    state.targetDevice = null;
    state.thresholdCharacteristic = null;
    state.connectionStatus = "Đã ngắt kết nối.";
    state.notifyUI();
  }

  Future<String> sendThreshold(String khuPhoId, String value) async {
    final state = getStateFor(khuPhoId, "0", "0");
    if (state.thresholdCharacteristic == null) return "Chưa kết nối ESP";
    final val = double.tryParse(value);
    if (val == null) return "Số không hợp lệ";
    try {
      await state.thresholdCharacteristic!.write(utf8.encode(value));
      state.warningThreshold = val;
      return "Đã lưu ngưỡng: $value kWh";
    } catch (e) { return "Lỗi gửi: $e"; }
  }

  void toggleChartPause(String khuPhoId) {
    final state = getStateFor(khuPhoId, "0", "0");
    state.isChartPaused = !state.isChartPaused;
    state.notifyUI();
  }

  void simulateData(String khuPhoId) {
    debugPrint("--- SIMULATING DATA ---");
    final state = getStateFor(khuPhoId, "0", "0");
    state.allElecReadings.clear();
    state.allWaterReadings.clear();
    state.elecChartSpots.clear();
    state.waterChartSpots.clear();
    state.chartCounter = 0;
    int year = DateTime.now().year;
    double cElec = 0;
    double cWater = 0;
    for (int m = 1; m <= 12; m++) {
      final ts = DateTime(year, m + 1, 0, 12, 0).millisecondsSinceEpoch ~/ 1000;
      cElec += (100 + m * 5);
      cWater += (20 + m);
      String fake = "$ts;Dien:$cElec;Nuoc:$cWater";
      _handleReceivedData(khuPhoId, utf8.encode(fake));
    }
    state.notifyUI();
  }
}