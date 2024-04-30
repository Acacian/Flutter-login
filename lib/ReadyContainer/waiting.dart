import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_database/firebase_database.dart';

import '../Container/room.dart' as main;

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

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();

    _initializeSocketIO();
    membersjoin();
    memberslist();
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

  Stream<Map<String, Map<String, dynamic>>> memberslist() {
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
      logger.i('members: $members');
      return members;
    });
  }

  @override
  void dispose() {
    _databaseReference
        .child('GameRoom-Status/${widget.roomId}/members/${widget.nickname}')
        .remove();
    _socket.disconnect();
    super.dispose();
  }

  void _leaveRoom() async {
    await _databaseReference
        .child('GameRoom-Status/${widget.roomId}/members/${widget.nickname}')
        .remove()
        .then((_) {
      Navigator.of(context).pop();
    }).catchError((error) {
      logger.e('Error leaving room: $error');
    });
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

  void _getoutofroom() {
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
                              'GameRoom-Status/${widget.roomId}/members/${widget.nickname}')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          // 유저 리스트 영역
          StreamBuilder<Map<String, Map<String, dynamic>>>(
            stream: memberslist(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  final members = snapshot.data;
                  final userList =
                      members?.values.toList() ?? []; // 멤버 정보를 리스트로 변환
                  return SizedBox(
                    height: 100, // 유저 리스트 영역의 높이 조정
                    child: ListView.builder(
                      itemCount: userList.length,
                      itemBuilder: (context, index) {
                        final user = userList[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(user['Username'][0]),
                          ),
                          title: Text(user['Username']),
                          subtitle: Text('Rank: ${user['rankpoint']}'),
                        );
                      },
                    ),
                  );
                } else {
                  return const Center(child: Text('No data available'));
                }
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
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
