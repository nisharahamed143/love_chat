import 'dart:math' as math;
import 'package:flutter/material.dart';

class LoginScreenHeader extends StatefulWidget {
  const LoginScreenHeader({super.key});

  @override
  State<LoginScreenHeader> createState() => _LoginScreenHeaderState();
}

class _LoginScreenHeaderState extends State<LoginScreenHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous smooth color rotation loop
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Smooth color transition logic
        final double progress = _controller.value;
        final double angle = progress * 2 * math.pi;

        return Container(
          height: size.height * 0.32, // Responsive height
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(angle),
                math.sin(angle),
              ),
              end: Alignment(
                math.cos(angle + math.pi),
                math.sin(angle + math.pi),
              ),
              colors: const [
                Color(0xFF00F2FE), // Bright Cyan
                Color(0xFF4FACFE), // Ocean Blue
                Color(0xFF00C9A7), // Soft Teal
                Color(0xFF26D0CE), // Bright Mint
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Icon / Brand Mark
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Main Title
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Text(
                  "Sign in to continue your journey",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}