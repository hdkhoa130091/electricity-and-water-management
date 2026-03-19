import 'package:flutter/material.dart';
import 'screens/home/views/home_screen.dart';
import 'screens/login/views/login_screen.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Electricity Tracker",
      theme:ThemeData(
        colorScheme: ColorScheme.light(
          surface: Colors.grey.shade200,
            onSurface: Colors.black,
          primary: Color(0xFF0288D1),
          secondary: Color(0xFF00C853),
          tertiary: Color(0xFF81D4FA),
          outline: Colors.black,
        )
      ),
    home: const LoginScreen(),
    );
  }
}