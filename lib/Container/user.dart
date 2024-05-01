import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'room.dart' as room;

class User extends StatefulWidget {
  const User({super.key});

  @override
  State<User> createState() => _User();
}

class _User extends State<User> {
  Logger logger = Logger();
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? ud;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    final userData = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user?.uid)
        .get();
    setState(() {
      ud = userData.data();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('User Page'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/quiz-logo.png',
              width: 300,
              color: const Color.fromARGB(200, 255, 255, 255),
              ),
              const SizedBox(height: 60.0),
              // 유저 닉네임
              Text(
                'Nickname: ${ud?['nickname']}',
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
        
              // 유저 UID
              Text(
                'UID: ${ud?['id']}',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16.0),
        
              // 유저 랭크 포인트
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8.0),
                  Text(
                    'Rank Point: ${ud?['rankpoint']}',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 64.0),
              // 뒤로가기 버튼
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const room.Room(),
                      fullscreenDialog: true,
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Back to waiting room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
