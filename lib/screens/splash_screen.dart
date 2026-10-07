import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'navigation_screen.dart'; // আপনার Navigation Screen Import করুন

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // লোগো এবং টেক্সটের জন্য এনিমেশন সেটআপ
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    // ২ সেকেন্ড পর চেক করবে ইউজার লগইন করা আছে কিনা
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      // Firebase Authenticated User Check
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // ইউজার লগইন থাকলে সরাসরি NavigationScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NavigationScreen()),
        );
      } else {
        // ইউজার লগইন না থাকলে LoginScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()), // আপনার Login Parent Widget
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // আপনার লগইন বাটন ও কার্ডের সেম Gradient Background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF18ECB0),
              Color(0xFF00B4DB),
              Color(0xFF0083B0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Animated Logo Box
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chat_bubble_rounded, // অথবা আপনার অ্যাপের প্রধান আইকন
                      size: 56,
                      color: Color(0xFF0083B0),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App Name / Tagline
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: const [
                  Text(
                    "Chat With Love", // আপনার অ্যাপের নাম দিন
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Connect instantly, anywhere", // আপনার ট্যাগলাইন
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Loading Indicator at bottom
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}