import 'package:chat_with_love/widgets/login/login_screen_body.dart';
import 'package:chat_with_love/widgets/login/login_screen_header.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: const [
            LoginScreenHeader(),
            SizedBox(height: 25),
            LoginScreenBody(),
          ],
        ),
      ),
    );
  }
}