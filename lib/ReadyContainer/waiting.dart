import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_database/firebase_database.dart';

import '../Container/room.dart' as main;

class Waiting extends StatefulWidget {
  const Waiting({super.key, required this.roomId, required this.nickname});
  final String roomId;
  final String nickname;

  @override
  State<Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<Waiting> {
  final Logger logger = Logger();
  late TextEditingController _messageController;

  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  late io.Socket _socket;
  final _messages = <Map<String, dynamic>>[];
  final _members = <String>[];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();

    _initializeSocketIO();
    _listenToFirebaseUpdates();
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

  void _listenToFirebaseUpdates() {
    // USER JOINED
    _databaseReference
        .child('GameRoom-Status/${widget.roomId}/members')
        .onChildAdded
        .listen((event) {
      final member = event.snapshot.key as String;
      setState(() {
        _members.add(member);
      });
    });

    // get out of the room if the number of users exceeds the limit
    _databaseReference
        .child('GameRoom-Status/${widget.roomId}/quantity')
        .onValue
        .listen((event) {
      final quantity = event.snapshot.value as int;
      if (_members.length > quantity) {
        _databaseReference
            .child(
                'GameRoom-Status/${widget.roomId}/members/${widget.nickname}')
            .remove();
        Navigator.of(context).pop();
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const main.Room()));
      }
    });

    // REALTIME MESSAGE
    _databaseReference
        .child('GameRoom-Status/${widget.roomId}/messages')
        .onChildAdded
        .listen((event) {
      final message = event.snapshot.value as Map<String, dynamic>;
      setState(() {
        _messages.add(message);
      });
    });

    if (_messages.length > 10) {
      _databaseReference
          .child('GameRoom-Status/${widget.roomId}/messages')
          .onChildRemoved
          .listen((event) {
        Map<String, dynamic> message = _messages.reduce((prev, current) {
          return prev['timestamp'] < current['timestamp'] ? prev : current;
        });
        setState(() {
          _messages.remove(message);
        });
      });
    }
  }

  @override
  void dispose() {
    _databaseReference
        .child('GameRoom-Status/${widget.roomId}/members/${widget.nickname}')
        .remove();
    _socket.disconnect();
    super.dispose();
  }

  void _sendmessage(String message) {
    final newMessage = {
      'text': message,
      'sender': widget.nickname,
    };
    _databaseReference
        .child('GameRoom-Status/${widget.roomId}/messages')
        .push()
        .set(newMessage);
    _socket.emit('message', newMessage);
    _messageController.clear();
  }

  void _leaveRoom() {
    _databaseReference
        .child('GameRoom-Status/${widget.roomId}/members/${widget.nickname}')
        .remove()
        .then((_) {
      Navigator.of(context).pop();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const main.Room()));
    }).catchError((error) {
      logger.e('Error leaving room: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting'),
        actions: [
          ElevatedButton(
            onPressed: _leaveRoom,
            child: const Text('Leave Room'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final correntUser = message['sender'] == widget.nickname;
                return Align(
                  alignment: correntUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: correntUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!correntUser)
                          Text(
                            message['sender'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                        Text(message['text'] as String),
                      ],
                    ),
                  ),
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
          ElevatedButton(
            onPressed: () {
              _sendmessage(_messageController.text);
            },
            child: const Text('Send'),
          ),
          const SizedBox(height: 30.0),
        ],
      ),
    );
  }
}
