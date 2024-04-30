import 'package:flutter/material.dart';
import 'Container/auth.dart' as login;  // 대기페이지 가져오기

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Game',
      home: const login.Loginpage(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}