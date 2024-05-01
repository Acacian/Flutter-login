import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room.dart' as room;
import 'package:http/http.dart' as http;
import '../ReadyContainer/waiting.dart' as waiting;

class Make extends StatefulWidget {
  const Make({super.key});

  @override
  State<Make> createState() => _Make();
}

class _Make extends State<Make> {
  late TextEditingController _nameController;
  late TextEditingController _maxController;
  late TextEditingController _publicController;
  late TextEditingController _privateController;
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _maxController = TextEditingController();
    _publicController = TextEditingController();
    _publicController.text = 'Public';
    _privateController = TextEditingController();
  }

  final storeNickname = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .get()
      .then((value) => value.data()?['nickname'] as String);

  Logger logger = Logger();
  List<bool> isSelected = [true, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('CREATE ROOM'),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 200.0),
                Container(
                  width: 320,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Game Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 40.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      child: TextField(
                        controller: _maxController,
                        decoration: const InputDecoration(
                          hintText: 'Max Users',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    ToggleButtons(
                      isSelected: isSelected,
                      borderColor: Colors.grey,
                      borderWidth: 2,
                      borderRadius: BorderRadius.circular(8),
                      selectedBorderColor: Colors.blue,
                      selectedColor: Colors.white,
                      fillColor: Colors.blue,
                      color: Colors.black,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      onPressed: (int index) {
                        setState(() {
                          isSelected[0] = index == 0;
                          isSelected[1] = index == 1;
                          _publicController.text =
                              isSelected[0] ? 'Public' : 'Private';
                          logger.i(index);
                        });
                      },
                      children: const <Widget>[
                        Text('Public'),
                        Text('Private'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40.0),
                if (_publicController.text == 'Private') ...[
                  Container(
                    width: 320,
                    child: TextField(
                      controller: _privateController,
                      decoration: const InputDecoration(
                        hintText: 'Password for Private Game',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ]
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      createGame();
                    },
                    child: const Text('Create Game'),
                  ),
                  const SizedBox(width: 16.0),
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
                    child: const Text('Back to Main'),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> createGame() async {
    final gamename = _nameController.text;
    final quantity = _maxController.text;
    final ispublic = _publicController.text;
    // quentity는 숫자여야 하고, 아니면 error
    if (int.tryParse(quantity) == null) {
      setState(() {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('최대 유저 수에는 숫자를 입력해주세요!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    }
    // gamename이 비어있으면 error
    if (gamename.isEmpty) {
      setState(() {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('게임 이름을 입력해주세요!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    }
    if (ispublic == 'Private' && _privateController.text.isEmpty) {
      setState(() {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('비밀번호를 입력해주세요!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    }
    // '🔒' 모양 넣으면 에러
    if (gamename.contains('🔒')) {
      setState(() {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('게임 이름에 \'🔒\'를 넣을 수 없습니다!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    }

    // 간단한 데이터를 json으로 변환하여 POST로 데이터를 보낸다.
    final url = Uri.https(
      'real-app-710f5-default-rtdb.asia-southeast1.firebasedatabase.app',
      'GameRoom-Status.json',
    );
    // 만약 _publicController.text이 'Public'이면, 비밀번호를 보내지 않는다.
    if (ispublic == 'Public' &&
        gamename.isNotEmpty &&
        int.tryParse(quantity) != null) {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          {
            'game_name': gamename,
            'quantity': quantity,
            'ispublic': ispublic,
            'createdTime': DateTime.now().toString(),
            'createdUser': FirebaseAuth.instance.currentUser?.uid,
            'messages': <Map<String, dynamic>>[],
            'members': <String>[],
          },
        ),
      );
    }
    if (ispublic == 'Private' &&
        gamename.isNotEmpty &&
        int.tryParse(quantity) != null &&
        _privateController.text.isNotEmpty) {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          {
            'game_name': gamename,
            'quantity': quantity,
            'ispublic': ispublic,
            'game_password': _privateController.text,
            'createdTime': DateTime.now().toString(),
            'createdUser': FirebaseAuth.instance.currentUser?.uid,
            'messages': <Map<String, dynamic>>[],
            'members': <String>[],
          },
        ),
      );
    }
    // 정상적으로 만들었는지 확인하고, 만들지 않았다면 error
    final response = await http.get(url);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    bool isCreated = false;
    data.forEach((key, value) {
      if (value['game_name'] == gamename) {
        isCreated = true;
      }
    });
    if (!isCreated) {
      setState(() {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('게임을 만들지 못했습니다!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    }
    // not use only game name, use game name and user id
    final selectedGameId = data.keys.firstWhere(
      (key) =>
          data[key]['game_name'] == gamename &&
          data[key]['createdUser'] == FirebaseAuth.instance.currentUser?.uid,
    );

    if (mounted && isCreated == true) {
      Navigator.pushAndRemoveUntil(
          // send game id to waiting.dart
          context,
          MaterialPageRoute(
            builder: (context) => waiting.Waiting(
                roomId: selectedGameId,
                nickname: FirebaseAuth.instance.currentUser?.displayName ??
                    storeNickname.toString()),
            fullscreenDialog: true,
          ),
          (route) => false);
    }
  }
}
