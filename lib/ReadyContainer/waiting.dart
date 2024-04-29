import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_database/firebase_database.dart';

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

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();

    _initializeSocketIO();
    _listenToFirebaseUpdates();
  }

  void _initializeSocketIO() {
    _socket = io.io(
        'https://real-app-710f5-default-rtdb.asia-southeast1.firebasedatabase.app/GameRoom-Status/${widget.roomId}/messages.json',
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
        });
    _socket.connect();
  }

  void _listenToFirebaseUpdates() {
    _databaseReference
        .child('GameRoom-Status/${widget.roomId}/messages')
        .onChildAdded
        .listen((event) {
      final message = event.snapshot.value as Map<String, dynamic>;
      setState(() {
        _messages.add(message);
      });
    });
  }

  void _sendmessage(String message) {
    final newMessage = {
      'text': message,
      'sender': widget.nickname,
    };
    _databaseReference
        .child('GameRoom-Status/${widget.roomId}/messages')
        .push()
        .set(message);
    _socket.emit('message', newMessage);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final user = message['sender'] == widget.nickname;
                return Align(
                  alignment:
                      user ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: user ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!user)
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
        ],
      ),
    );
  }
}
