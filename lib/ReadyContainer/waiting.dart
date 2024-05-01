import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_database/firebase_database.dart';

import '../Container/room.dart' as main;
import '../game/game_page.dart' as game;

class Waiting extends StatefulWidget {
  const Waiting(
      {super.key,
      required this.roomId,
      required this.nickname,
      required this.rankpoint});
  final String roomId;
  final String nickname;
  final int rankpoint;

  @override
  State<Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<Waiting> {
  final Logger logger = Logger();
  late TextEditingController _messageController;

  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  late io.Socket _socket;

  // 버튼 눌러야 이동
  bool _isGameStart = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();

    _initializeSocketIO();
    _membersStream();
    membersjoin();
    _getoutofroom();
    _chating();
  }

  void _initializeSocketIO() {
    _socket = io.io(
        'https://real-app-710f5-default-rtdb.asia-southeast1.firebasedatabase.app/GameRoom-Status.json',
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
        });
    _socket.connect();
  }

  Future<void> _sendMessage(String text) async {
    if (text.isNotEmpty) {
      final newMessage = {
        'sender': widget.nickname,
        'text': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      try {
        await _databaseReference
            .child('GameRoom-Status/${widget.roomId}/messages')
            .push()
            .set(newMessage);
        _messageController.clear();
        _socket.emit('message', <String, dynamic>{
          'roomId': widget.roomId,
          'message': newMessage,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: $e'),
            ),
          );
        }
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _chating() {
    return _databaseReference
        .child('GameRoom-Status/${widget.roomId}/messages')
        .onValue
        .map((event) {
      final messages = <Map<String, dynamic>>[];
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final message = Map<String, dynamic>.from(value);
            messages.add(message);
          }
        });
      }
      logger.i('messages: $messages');
      return messages;
    });
  }

  void membersjoin() async {
    if (widget.nickname.isNotEmpty) {
      final newUser = {
        'Username': widget.nickname,
        'rankpoint': widget.rankpoint,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      try {
        final newMemberRef = _databaseReference
            .child('GameRoom-Status/${widget.roomId}/members')
            .push();
        await newMemberRef.set(newUser);
        _socket.emit('member', <String, dynamic>{
          'roomId': widget.roomId,
          'member': newUser,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('방에 입장할 수 없습니다 : $e'),
            ),
          );
        }
      }
    }
  }

  Stream<Map<String, Map<String, dynamic>>> _membersStream() {
    return _databaseReference
        .child('GameRoom-Status/${widget.roomId}/members')
        .onValue
        .map((event) {
      final members = <String, Map<String, dynamic>>{};
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            members[key] = Map<String, dynamic>.from(value);
          }
        });
      }
      return members;
    });
  }

  void _leaveRoom() async {
    // 데이터베이스에서 유저 찾기
    final DataSnapshot snapshot = await _databaseReference
        .child('GameRoom-Status/${widget.roomId}/members')
        .get();
    final members = snapshot.value as Map<dynamic, dynamic>;
    final newMemberRef = members.entries.firstWhere(
      (element) => element.value['Username'] == widget.nickname,
    );

    try {
      // 유저 정보 삭제
      await _databaseReference
          .child('GameRoom-Status/${widget.roomId}/members/${newMemberRef.key}')
          .remove();
      // 방 정보 업데이트
      DatabaseReference roomRef =
          _databaseReference.child('GameRoom-Status/${widget.roomId}');
      DataSnapshot snapshot = await roomRef.child('members').get();
      if (snapshot.value != null) {
        Map<String, dynamic> updatedMembers =
            Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        updatedMembers.remove(widget.nickname);
        await roomRef.update({'members': updatedMembers});
        _socket.disconnect();
        super.dispose();
      } else {
        await roomRef.remove();
        _socket.disconnect();
        super.dispose();
      }
      // 방 나가기
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      logger.e('방을 나갈 수 없습니다!: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('방을 나가는 데 실패했습니다. 다시 시도해 주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _getoutofroom() async {
    final DataSnapshot snapshot = await _databaseReference
        .child('GameRoom-Status/${widget.roomId}/members')
        .get();
    final members = snapshot.value as Map<dynamic, dynamic>;
    final newMemberRef = members.entries.firstWhere(
      (element) => element.value['Username'] == widget.nickname,
    );
    _membersStream().listen((members) {
      _databaseReference
          .child('GameRoom-Status/${widget.roomId}/quantity')
          .onValue
          .first
          .then((event) {
        final quantity = event.snapshot.value as int;
        if (members.length > quantity) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('방 용량 초과'),
                content: const Text('방 용량이 초과되어 퇴장해야 합니다.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      // 사용자 데이터베이스에서 삭제
                      _databaseReference
                          .child(
                              'GameRoom-Status/${widget.roomId}/members/${newMemberRef.key}')
                          .remove()
                          .then((_) {
                        // 사용자 퇴장 처리
                        Navigator.of(context).pop();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const main.Room()));
                      });
                    },
                    child: const Text('Exit'),
                  ),
                ],
              );
            },
          );
        }
      });
    });
  }

  void gotoGame() async {
    setState(() {
      _isGameStart = true;
    });
    try {
      final snapshot = await _databaseReference
          .child('GameRoom-Status')
          .child(widget.roomId)
          .get();
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final members = data['members'] as Map<dynamic, dynamic>;
        final memberList = members.values.toList();
        final member = memberList
            .firstWhere((element) => element['Username'] == widget.nickname);
        final server = {
          'roomId': widget.roomId,
          'nickname': widget.nickname,
          'rankpoint': member['rankpoint'],
        };
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => game.GamePage(dataServer: server),
            ),
          );
        }
      }
    } catch (e) {
      logger.e('게임 대기열로 이동할 수 없습니다. RSN : $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('입장할 수 없습니다.'),
              content: const Text('게임방에 입장할 수 없습니다. 다시 시도해주세요.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      setState(() {
        _isGameStart = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Waiting Room'),
        actions: [
          ElevatedButton(
            onPressed: _leaveRoom,
            child: const Text('Leave Room'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isGameStart)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            ElevatedButton(
              onPressed: () {
                gotoGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // 버튼 배경색
                foregroundColor: Colors.white, // 버튼 텍스트 색상
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 20), // 버튼 크기 조절
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게
                ),
              ),
              child: const Text(
                'Game Start',
                style: TextStyle(
                  fontSize: 18, // 텍스트 크기 조절
                  fontWeight: FontWeight.bold, // 텍스트 굵기 조절
                ),
              ),
            ),
          // 유저 리스트 영역
          SizedBox(
            height: 100, // 유저 리스트 영역의 높이 조정
            child: StreamBuilder<Map<String, Map<String, dynamic>>>(
              stream: _membersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    final members = snapshot.data;
                    final userList =
                        members?.values.toList() ?? []; // 멤버 정보를 리스트로 변환
                    return ListView.builder(
                      scrollDirection: Axis.horizontal, // 수평 스크롤
                      itemCount: userList.length,
                      itemBuilder: (context, index) {
                        final user = userList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                child: Text(user['Username'][0]),
                              ),
                              const SizedBox(height: 8),
                              Text(user['Username']),
                              const SizedBox(height: 4),
                              Text('Rank: ${user['rankpoint']}'),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('No data available'));
                  }
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chating(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return const Center(child: CircularProgressIndicator());
                  case ConnectionState.active:
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: Text('No data available'));
                    }
                  case ConnectionState.none:
                    return const Center(child: Text('No data available'));
                  case ConnectionState.done:
                    return const Center(child: Text('No data available'));
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final sender = message['sender'] as String;
                    final isSentByCurrentUser = sender == widget.nickname;
                    return Align(
                      alignment: isSentByCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: isSentByCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isSentByCurrentUser)
                              Text(
                                sender,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: isSentByCurrentUser
                                    ? Colors.blue
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(message['text'] as String),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              hintText: 'Enter message',
            ),
          ),
          const SizedBox(height: 40.0),
          ElevatedButton(
            onPressed: () {
              _sendMessage(_messageController.text);
              _messageController.clear();
            },
            child: const Text('Send'),
          ),
          const SizedBox(height: 30.0),
        ],
      ),
    );
  }
}
