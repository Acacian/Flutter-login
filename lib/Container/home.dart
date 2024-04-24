import 'package:flutter/material.dart';
import "auth.dart";
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {},
              child: const Text('Game Start'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Public/Private'),
            ),
            ElevatedButton(
              onPressed: () {
                showUsers();
              },
              child: const Text('Max Users'),
            ),
            ElevatedButton(
              onPressed: () {
                signsOut();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Loginpage()),
                );
                Navigator.maybePop(context);
              },
              child: const Text('Log Out'),
            ),
            Expanded(
              child: showUsers(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> signsOut() async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    Navigator.maybePop(context);
    await firebaseAuth.signOut();
    await GoogleSignIn().signOut();

    // logout할 때, islogin을 false로 변경
    var user = FirebaseAuth.instance.currentUser;
    var db = FirebaseFirestore.instance;
    db.collection('Users').doc(user?.uid).update({
      'is_login': false,
    });
  }

  // show top 10 users
  Widget showUsers() {
    var db = FirebaseFirestore.instance;
    return FutureBuilder<QuerySnapshot>(
      future: db
          .collection('Users')
          .orderBy('rankpoint', descending: true)
          .limit(10)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User ID: ${doc.id}'),
                            const SizedBox(height: 8.0),
                            Text('Rankpoint: ${doc['rankpoint']}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
