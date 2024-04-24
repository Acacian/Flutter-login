import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  late final _LoginpageController;

  @override
  void initState() {
    super.initState();
    _LoginpageController = TextEditingController();
  }

  @override
  void dispose() {
    // 페이지를 벗어날 때 controller를 삭제해서 메모리 차지를 방지
    super.dispose();
    _LoginpageController.dispose();
  }

// CRUD
  void _createUsers() {
    var db = FirebaseFirestore.instance;
    db.collection('Users').add({
      'id': _LoginpageController.text,
      'is_login': false,
      'nickname': _LoginpageController.text,
      'pw': _LoginpageController.text,
      'rankpoint': 500,
      'createTime': Timestamp.now(),
    });
  }

  Future<void> _updateUsers(String docID, bool isDone) async {
    var db = FirebaseFirestore.instance;
    try {
      db.collection('Users').doc(docID).update({
        'isDone': !isDone,
      });
    } on FirebaseException catch (e) {
      print(e.message);
    }
  }

  Future<void> _deleteUsers(String docID) async {
    var db = FirebaseFirestore.instance;
    try {
      db.collection('Users').doc(docID).delete();
    } on FirebaseException catch (e) {
      print(e.message);
    }
  }

  //Oauth : Google
  Future<void> signInWithGoogle(BuildContext context) async {
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
          logger.e(user);
        }
      }
    } catch (e) {
      logger.e('Error during sign in: $e');
    }
  }

  Future<void> signOut() async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

    await firebaseAuth.signOut();
    await GoogleSignIn().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Column(
        children: [
          _buildTop(),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildTop() {
    return Row(
      children: [
        Flexible(
          child: TextField(
            controller: _LoginpageController,
          ),
        ),
        ElevatedButton(
            onPressed: _createUsers, child: const Text('Signup/회원가입')),
      ],
    );
  }

  Widget _buildBody() {
    return Expanded(
        child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Users').snapshots(),
            // 삼항연산자를 사용, 연결 상태가 대기 중일 때는 로딩 표시
            builder: (context, snapshot) {
              return (snapshot.connectionState == ConnectionState.waiting)
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final data = snapshot.data!.docs[index];
                        final id = data['id'].toString();
                        final is_login = data['is_login'];
                        final nickname = data['nickname'].toString();
                        final pw = data['pw'].toString();
                        final rankpoint = data['rankpoint'];
                        return ListTile(
                          onTap: () => _updateUsers(data.id, is_login),
                          title: Text(id),
                          leading: (is_login)
                              ? const Icon(
                                  //true면 초록색
                                  Icons.done,
                                  color: Colors.green,
                                )
                              : const Icon(
                                  //false면 빨간색
                                  Icons.close,
                                  color: Colors.red,
                                ),
                          trailing: IconButton(
                            //데이터 삭제 버튼
                            onPressed: () {
                              _deleteUsers(id); //데이터 삭제
                            },
                            icon: const Icon(Icons.delete_forever),
                          ),
                        );
                      });
            }));
  }
}
