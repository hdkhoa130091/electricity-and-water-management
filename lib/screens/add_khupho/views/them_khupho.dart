import 'package:done/Data/Data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddKhupho extends StatefulWidget {
  const AddKhupho({super.key});

  @override
  State<AddKhupho> createState() => _AddKhuphoState();
}

class _AddKhuphoState extends State<AddKhupho> {
  final _formKey = GlobalKey<FormState>();
  final _tenKhuPhoController = TextEditingController();

  @override
  void dispose() {
    _tenKhuPhoController.dispose();
    super.dispose();
  }

  void _themKhuPho() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final khuPho = _tenKhuPhoController.text.trim();

    final isExist = MyData.any((e) =>
    e['KhuPho']?.toLowerCase() == khuPho.toLowerCase());

    if (isExist) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khu phố "$khuPho" đã tồn tại!'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final DatabaseReference ref = FirebaseDatabase.instance.ref('summaries/$khuPho');

      await ref.set({
        'ten_khu_pho': khuPho,
        'tong_dien_nam': 0,
        'tong_nuoc_nam': 0,
        'cap_nhat_luc': ServerValue.timestamp,
      });

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm Khu Phố "$khuPho" thành công!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context, true);
      }

    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quản Lý Điện Nước",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            Text(
              "Cho Khu Phố",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
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
              ),

              const SizedBox(height: 40),

              const Text(
                "Thêm khu phố",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 30),

              _buildTextField(
                controller: _tenKhuPhoController,
                label: "Tên khu phố",
                hint: "VD: Khu 3",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên khu phố';
                  }
                  final trimmed = value.trim();
                  if (MyData.any((e) =>
                  e['KhuPho']?.toLowerCase() == trimmed.toLowerCase())) {
                    return 'Tên khu phố đã tồn tại';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              GestureDetector(
                onTap: _themKhuPho,
                child: Container(
                  width: 180,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                      transform: const GradientRotation(3.14 / 4),
                    ),
                    borderRadius: BorderRadius.circular(28.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Thêm",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width / 1.2,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1.0),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: validator,
      ),
    );
  }
}