import 'package:chat_with_love/screens/login_screen.dart';
import 'package:chat_with_love/screens/splash_screen.dart';
import 'package:chat_with_love/view_models/login_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  // ১. Flutter Binding নিশ্চিত করুন
  WidgetsFlutterBinding.ensureInitialized();
  // ২. Firebase Initialize করুন
  await Firebase.initializeApp();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LoginViewModel()),
    ],
    child: const MyApp(),
  ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
     debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}




