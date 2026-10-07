import 'package:chat_with_love/screens/chat_screen.dart';
import 'package:chat_with_love/widgets/navigation/navigation_bar_widget.dart';
import 'package:flutter/material.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 0;

  // আপনার পেজগুলোর লিস্ট (Index 0 তে ChatScreen আছে)
  final List<Widget> _pages = const [
    ChatScreen(), // Index 0: চ্যাট স্ক্রিন
    Center(child: Text("Calls Screen", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    Center(child: Text("Reels Screen", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    Center(child: Text("Profile Screen", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      // IndexedStack ছাড়াই সাধারণ ভাবে পেজ সিলেক্ট করা হচ্ছে
      body: _pages[_currentIndex],

      bottomNavigationBar: SafeArea(
        child: NavigationBarWidget(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index; // ক্লিক করা ইন্ডিকেটর অনুযায়ী পেজ আপডেট হবে
            });
          },
        ),
      ),
    );
  }
}