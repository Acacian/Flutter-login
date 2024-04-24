import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth.dart' as auth;

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});

  @override
  State<Signuppage> createState() => _SignUpState();
}

class _SignUpState extends State<Signuppage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  void _signUp() async {
    // 회원가입 로직 구현
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // 입력 값 검증
    if (name.isEmpty) {
      setState(() {
        _errorMessage = '이름을 입력하세요';
      });
      return;
    }
    if (email.isEmpty) {
      setState(() {
        _errorMessage = '이메일을 입력하세요';
      });
      return;
    }
    if (password.isEmpty) {
      setState(() {
        _errorMessage = '비밀번호를 입력하세요';
      });
      return;
    }
    if (confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = '비밀번호 확인을 입력하세요';
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = '비밀번호가 일치하지 않습니다';
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _errorMessage = '비밀번호는 6자 이상이어야 합니다';
      });
      return;
    }
    // email은 @이 들어가야 하고, @가 2개 이상이면 안됨
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() {
        _errorMessage = '이메일 형식이 올바르지 않습니다';
      });
      return;
    }

    void showSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    final Logger logger = Logger();
    User? user;
    try {
      FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      UserCredential credential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        user = credential.user;
        logger.i(user);
      } else {
        showSnackBar("Server Error");
      }
    } on FirebaseAuthException catch (error) {
      logger.e(error.code);
      String? errorCode;
      switch (error.code) {
        case "email-already-in-use":
          errorCode = error.code;
          break;
        case "invalid-email":
          errorCode = error.code;
          break;
        case "weak-password":
          errorCode = error.code;
          break;
        case "operation-not-allowed":
          errorCode = error.code;
          break;
        default:
          errorCode = null;
      }
      if (errorCode != null) {
        showSnackBar(errorCode);
      }
    }

    // 회원가입 로직 구현
    // 예: Firebase Authentication 사용
    try {
      var db = FirebaseFirestore.instance;
      db.collection('Users').add({
        'id': email,
        'is_login': false,
        'nickname': name,
        'pw': password,
        'rankpoint': 500,
        'createTime': Timestamp.now(),
      });

      // 회원가입 성공 시, 로그인 페이지로 이동
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const auth.Loginpage()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '회원가입에 실패했습니다. 다시 시도해주세요';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _signUp,
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
