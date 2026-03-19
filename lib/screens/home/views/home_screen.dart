import 'package:done/screens/home/views/main_screen.dart';
import 'package:done/screens/profile/views/profile.dart';
import 'package:done/screens/Warning/Warning.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var widgetList = [
    WarningScreen(), 
    MainScreen(),
    ProfileScreen(),
  ];

  int index = 1; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (value) {
          setState(() {
            index = value; 
          });
        },
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 3,
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_2, size: 40),
            label: 'chats',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                  transform: const GradientRotation(3.14 / 4),
                ),
              ),
              child: const Icon(
                CupertinoIcons.home,
                size: 40,
                color: Colors.white,
              ),
            ),
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.profile_circled, size: 40),
            label: 'profile',
          ),
        ],
      ),
      body: widgetList[index],
    );
  }
}