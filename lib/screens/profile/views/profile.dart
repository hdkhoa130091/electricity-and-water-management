import 'package:flutter/material.dart';
import 'package:done/screens/login/views/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle nameStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    );

    final List<String> members = [
      "Thành viên nhóm:",
      "Hồ Đăng Khoa - 22139034",
      "Huỳnh Phước Long - 22139037",
      "Ngô Đình Thái Long - 22139038",
      "Nguyễn Quang Minh - 22139041",
    ];
    return SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Column(
              children: [
                const SizedBox(
                  height: 40,
                ),
                Container(
                  child: Center(
                      child: Text("Edit Profile",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ))),
                ),
                const SizedBox(
                  height: 20,
                ),
                CircleAvatar(
                  radius: 50, 
                  backgroundImage: AssetImage(
                      'assets/images/profile_placeholder.png'), 
                ),


                const SizedBox(height: 20,),

                GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (Route<dynamic> route) => false, 
                    );
                  },
                  child: Container(
                      height: 50,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Center(
                          child: Text("Đăng Xuất",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )))),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: members.map((name) {
                  return Container(
                    child: Center(
                      child: Text(
                        name,
                        style: nameStyle,
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ));
  }
}