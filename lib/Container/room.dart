import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'make.dart' as make;
import 'dart:convert';
import 'dart:async';
import 'user.dart' as user;
import '../ReadyContainer/waiting.dart' as waiting;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "auth.dart";

class Room extends StatefulWidget {
  const Room({super.key});

  @override
  State<Room> createState() => _Room();
}

class _Room extends State<Room> {
  // 검색어 입력을 위한 컨트롤러
  final _searchController = TextEditingController();
  final _gamepassword = TextEditingController();
  int _selectedGameIndex = -1;
  List<String> _filteredGameList = [];
  final List<String> _gameList = [];
  String gamepassword = '';

  @override
  void initState() {
    super.initState();
    _filteredGameList = List.from(_gameList);
    _searchController.addListener(() {
      // 검색어 입력 시 필터링
      _filterGameList(_searchController.text);
    });

    getGame();
  }

  Logger logger = Logger();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Your Game Page'),
        actions: [
          IconButton(
            iconSize: 120,
            icon: Image.asset('images/Sans.png'), // 임의의 캐릭터 모양 아이콘 사용
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const user.User()),
                (route) => false,
              );
              logger.i('내 정보창 이동');
            },
          ),
          // make padding
          const SizedBox(width: 25),
          IconButton(
            iconSize: 120,
            icon: Image.asset('images/rerun.png'),
            onPressed: () {
              getGame();
              logger.i('새로고침');
            },
          ),
          const SizedBox(width: 25),
          IconButton(
            iconSize: 120,
            icon: Image.asset('images/logout.png'),
            onPressed: () {
              signsOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Loginpage()),
                (route) => false,
              );
              Navigator.maybePop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: '검색할 게임을 입력하세요',
              ),
              controller: _searchController, // 검색어 입력을 위한 컨트롤러
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 검색 버튼을 너무 자주 누르면 안 되니까 1초 딜레이를 줌
                Future.delayed(const Duration(seconds: 1), () {});
                setState(() {
                  _filterGameList(_searchController.text);
                });
              },
              child: const Text('검색'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredGameList.length,
                itemBuilder: (context, index) {
                  // 클릭된 Tile의 색깔을 얕은 검은색으로 변경
                  Color tileColor = Colors.transparent;
                  if (_selectedGameIndex == index) {
                    tileColor = Colors.grey.withOpacity(0.5);
                  }
                  return ListTile(
                    tileColor: tileColor,
                    title: Text(_filteredGameList[index]),
                    onTap: () {
                      setState(() {
                        if (_selectedGameIndex == index) {
                          _selectedGameIndex = -1;
                        } else if (_filteredGameList.isEmpty) {
                          const Center(child: Text('방이 없습니다. 방을 만들어 주세요'));
                        } else {
                          _selectedGameIndex = index;
                        }
                      });
                      logger.i('게임 ${_filteredGameList[index]} 클릭');
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const make.Make()),
                  (route) => false,
                );
                logger.i('Create Game 버튼 클릭');
              },
              child: const Text('Create Game'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 선택된 listtile의 index, 즉 게임 이름을 가져와서 join하는 함수 호출
                if (_selectedGameIndex == -1) {
                  logger.e('게임을 선택해주세요');
                  return;
                }
                join();
              },
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }

// 게임 리스트 필터링 함수
  void _filterGameList(String searchText) {
    // 검색어를 기반으로 게임 리스트 필터링
    _filteredGameList =
        _gameList.where((game) => game.contains(searchText)).toList();
  }

// join을 통해 해당 이름의 대기방에 참가하기
  Future<void> join() async {
    final selectedGame = _filteredGameList[_selectedGameIndex];
    final url = Uri.https(
      'real-app-710f5-default-rtdb.asia-southeast1.firebasedatabase.app',
      'GameRoom-Status.json',
    );
    final response = await http.get(url);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // 선택된 게임의 id를 가져와서 참가하기
    final selectedGameId = data.keys.elementAt(_selectedGameIndex);

    if (selectedGame.contains('🔒')) {
      data.forEach((key, value) {
        // to find filtered game's id
        if (selectedGameId == key) {
          gamepassword = value['game_password'];
        }
      });
      // 비밀번호가 있는 게임이라면 비밀번호를 입력받아야 함
      if (mounted) {
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierLabel: "비밀번호 입력",
          transitionBuilder: (context, a1, a2, widget) {
            return Transform.scale(
              scale: a1.value,
              child: Opacity(
                opacity: a1.value,
                child: passwordInputDialog(context),
              ),
            );
          },
          pageBuilder: (context, animation1, animation2) {
            return passwordInputDialog(context);
          },
        );
      }
    } else {
      try {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const waiting.Waiting(),
              fullscreenDialog: true,
            ),
          );
        }
      } catch (e) {
        logger.e('게임 참가에 실패했습니다. RSN : $e');
      }
    }
  }

  Widget passwordInputDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('비밀번호를 입력해주세요'),
      content: TextField(
        controller: _gamepassword,
        decoration: const InputDecoration(
          labelText: '비밀번호',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            if (_gamepassword.text == gamepassword) {
              logger.i('비밀번호가 맞습니다');
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const waiting.Waiting(),
                  fullscreenDialog: true,
                ),
              );
            } else {
              _gamepassword.clear();
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('비밀번호가 틀렸습니다'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('확인'),
                      ),
                    ],
                  );
                },
              );
            }
          },
          child: const Text('확인'),
        ),
      ],
    );
  }

// 게임 리스트 데이터
  final user.User? now = const user.User();

  Future<void> getGame() async {
    try {
      if (now != null && mounted) {
        final url = Uri.https(
          'real-app-710f5-default-rtdb.asia-southeast1.firebasedatabase.app',
          'GameRoom-Status.json',
        );
        final response = await http.get(url);
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _gameList.clear();
        data.forEach((key, value) {
          // public이면 그대로 넣고, 아니면 자물쇠 그림을 추가함
          if (value['ispublic'] == 'Public') {
            _gameList.add(value['game_name']);
          } else {
            _gameList.add(value['game_name'] + '🔒');
          }
        });
        // 필터링된 게임 리스트 업데이트
        _filteredGameList = List.from(_gameList);
        setState(() {
          // 게임 리스트가 업데이트되었으므로 화면을 다시 그림
        });
      } else {
        logger.e('토큰이 없습니다');
      }
    } catch (e) {
      // db에 접근에는 성공했으나 데이터가 없는 경우
      if (e is NoSuchMethodError) {
        logger.e('게임 리스트가 없습니다');
      } else {
        logger.e('게임 리스트를 가져오기에 실패했습니다. RSN : $e');
      }
    }
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
}
