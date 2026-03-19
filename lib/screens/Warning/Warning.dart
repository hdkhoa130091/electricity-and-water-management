import 'dart:async';
import 'package:done/services/khupho_state_manager.dart'; 
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

class WarningScreen extends StatefulWidget {
  const WarningScreen({super.key});

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  final _stateManager = KhuPhoStateManager.instance;
  List<Warning> _warnings = [];
  StreamSubscription? _warningListener;
  final DateFormat _formatter = DateFormat('HH:mm dd/MM/yyyy');

  @override
  void initState() {
    super.initState();

    _warnings = _stateManager.getWarnings();

    _warningListener = _stateManager.warningUpdateStream.listen((_) {
      if (mounted) {
        setState(() {
          _warnings = _stateManager.getWarnings();
        });
      }
    });
  }

  @override
  void dispose() {
    _warningListener?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Danh Sách Cảnh Báo",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            Expanded(
              child: _warnings.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  crossAxisSpacing: 20.0,
                  mainAxisSpacing: 20.0,
                  childAspectRatio: 2.5, 
                ),
                itemCount: _warnings.length,
                itemBuilder: (context, int i) {
                  final warning = _warnings[i];

                  return Dismissible(
                    key: Key(warning.id),
                    direction: DismissDirection.horizontal,

                    onDismissed: (direction) {
                      _stateManager.removeWarning(warning.id);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã xóa cảnh báo khu phố ${warning.khuPhoId}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },

                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 20.0),
                            child: Icon(CupertinoIcons.delete, color: Colors.white),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 20.0),
                            child: Icon(CupertinoIcons.delete, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    child: _buildWarningCard(warning),
                  );
                },
              ),
            ),
          ]),
    );
  }

  Widget _buildWarningCard(Warning warning) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25.0), 
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 4))
          ]),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Khu phố ${warning.khuPhoId}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.outline,
                    )),
                Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Center(
                      child: Icon(CupertinoIcons.exclamationmark_triangle_fill,
                          color: Colors.red),
                    ))
              ],
            ),

            Text(
              "VƯỢT NGƯỠNG ĐIỆN",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            Text(
              "Đo được: ${warning.value.toStringAsFixed(2)} kWh "
                  "(Ngưỡng: ${warning.threshold.toStringAsFixed(2)} kWh)",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(CupertinoIcons.time, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Text(_formatter.format(warning.timestamp),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.check_mark_circled,
              size: 80, color: Colors.green.shade400),
          const SizedBox(height: 16),
          Text(
            "Không có cảnh báo",
            style: TextStyle(fontSize: 20, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            "Mọi thứ đều trong ngưỡng an toàn.",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}