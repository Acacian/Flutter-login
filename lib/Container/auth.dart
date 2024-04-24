import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginState();
}

class _LoginState extends State<Loginpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                signInWithGoogle(context);
              },
              child: const Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
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
        // Check the credential(자격증명 확인)
        print("idToken: ${authentication.idToken}");

        // 인증 자격증명을 사용해 Firebase에 로그인
        UserCredential credential =
            await firebaseAuth.signInWithCredential(googleCredential);
        // 로그인 성공 시 user변수에 로그인한 사용자 정보를 저장
        if (credential.user != null) {
          user = credential.user;
          logger.e(user);
        }
      }
    } catch (e) {
      logger.e('Error during google sign in: $e');
    }
  }

  Future<void> signOut() async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

    await firebaseAuth.signOut();
    await GoogleSignIn().signOut();
  }
}
