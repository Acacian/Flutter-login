import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

// DB 저장할거임
import 'package:cloud_firestore/cloud_firestore.dart';

// 로그인 성공 시 다음 화면으로 넘어감
import 'home.dart' as home;
import 'signup.dart' as signup;

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginState();
}

class _LoginState extends State<Loginpage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String? _errorMessage; // 에러 메시지를 저장할 변수

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Login Page'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              if (_errorMessage != null) // 에러시에만 표시
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _login();
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // 회원가입 화면으로 이동하는 로직 추가
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const signup.Signuppage(),
                      ));
                },
                child: const Text('Sign Up'),
              ),
              ElevatedButton(
                onPressed: () {
                  signInWithGoogle(context);
                },
                child: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _login() async {
    FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    Logger logger = Logger();
    User? user;

    UserCredential credential = await firebaseAuth.signInWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (credential.user != null) {
      user = credential.user;
      logger.i(user);
      if (mounted) {
        Logger().i('Login Success');
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const home.Home()));
      }
    }
  }

  //Oauth : Google
  void signInWithGoogle(BuildContext context) async {
    final Logger logger = Logger(); // logger 인스턴스를 생성
    try {
      // firebase/google init
      User? user; // User 타입의 변수를 선언합니다.
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      GoogleSignIn googleSignIn = GoogleSignIn();

      // Trigger the Google Sign In process(구글 계정 가져오기)
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        GoogleSignInAuthentication authentication =
            await googleUser.authentication;

        // Create a new credential(새로운 인증 자격 증명 생성)
        OAuthCredential googleCredential = GoogleAuthProvider.credential(
          idToken: authentication.idToken,
          accessToken: authentication.accessToken,
        );

        // 인증 자격증명을 사용해 Firebase에 로그인
        UserCredential credential =
            await firebaseAuth.signInWithCredential(googleCredential);
        // 로그인 성공 시 user변수에 로그인한 사용자 정보를 저장
        if (credential.user != null) {
          user = credential.user;
          logger.i(user);
        }
        //기존에 firebase에 저장되어 있던 유저가 아닐 경우,
        //* 새로운 DB로 저장
        if (user != null) {
          var db = FirebaseFirestore.instance;
          db.collection('Users').doc(user.uid).get().then((doc) {
            if (!doc.exists) {
              db.collection('Users').doc(user?.uid).set({
                'id': user?.uid,
                'is_login': false,
                'nickname': user?.displayName,
                'rankpoint': 500,
                'createTime': Timestamp.now(),
                'pw': 'google',
              });
            }
          });
        }
        //* 만약 기존의 유저라면, 로그인 시간을 업데이트
        else {
          var db = FirebaseFirestore.instance;
          db.collection('Users').doc(user?.uid).update({
            'is_login': true,
            'createTime': Timestamp.now(),
          });
        }

        // 모든 과정을 거치면 홈화면으로 이동.
        //! mounted를 통해 user정보가 null이 아닐 때 화면연동
        if (user != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const home.Home()),
          );
        }
      }
    } catch (e) {
      logger.e('Error during google sign in: $e');
    }
  }
}
