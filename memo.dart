// waitingroom 초안

// import 'package:flutter/material.dart';
// import 'package:logger/logger.dart';

// import 'package:socket_io_client/socket_io_client.dart' as io;
// import 'package:firebase_database/firebase_database.dart';

// import '../main.dart';

// class Waiting extends StatefulWidget {
//   const Waiting({super.key});

//   @override
//   State<Waiting> createState() => _Waiting();
// }

// class _Waiting extends State<Waiting> {
//   final Logger logger = Logger();
//   late TextEditingController _messageController;

//   final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
//   late io.Socket _socket;
//   final List<String> _messages = [];

//   @override
//   void initState() {
//     // 소켓 연결이 정상적으로 되었는가? 소켓은 처음에 메인에서 연결한다.
//     _socket = MyServerWidgetState().socket;
//     if (_socket.connected) {
//       logger.i('Socket connected');
//     } else {
//       logger.e('Socket disconnected');
//     }

//     super.initState();
//     _messageController = TextEditingController();

//     _initializeSocketIO();
//     _listenToFirebaseUpdates();
//   }

//   void _initializeSocketIO() {
//     // _socket = io.io(
//     //     'https://real-app-710f5-default-rtdb.asia-southeast1.firebasedatabase.app/GameRoom-Status/-NwUoUr4qX6lqAZMv8zb.json',
//     //     <String, dynamic>{
//     //       'transports': ['websocket'],
//     //       'autoConnect': false,
//     //     });
//     _socket = MyServerWidgetState().socket;
//     _socket.connect();
//   }

//   void _listenToFirebaseUpdates() {
//     _databaseReference
//         .child('GameRoom-Status/-NwUoUr4qX6lqAZMv8zb/messages')
//         .onValue
//         .listen((event) {
//       final messages = Map<String, dynamic>.from(event.snapshot.value as Map);
//       final messagesList =
//           messages.values.map((m) => m['text'] as String).toList();

//       setState(() {
//         // 메세지는 최대 10개까지만 보여주기
//         _messages.clear();
//         _messages.addAll(messagesList.reversed.take(10));
//       });
//     });
//   }

//   void _sendMessage(String message) {
//     try {
//       _databaseReference
//           .child('GameRoom-Status/-NwUoUr4qX6lqAZMv8zb/messages/')
//           .push()
//           .set({'text': message});

//       // Socket.IO를 통해 새로운 메시지 전송
//       _socket.emit('new_message', message);

//       // 메시지가 비어있지 않다면 _messages 리스트의 맨 앞에 추가
//       if (message.isNotEmpty) {
//         setState(() {
//           _messages.insert(0, message);
//         });
//         _messageController.clear();
//       }
//     } catch (e) {
//       logger.e('Firebase | Error: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   title: Text(_messages[index]),
//                 );
//               },
//             ),
//           ),
//           TextField(
//             controller: _messageController,
//             onSubmitted: (value) {
//               _sendMessage(value);
//               logger.e(value); // 메시지 전송 시 텍스트 로깅
//             },
//             decoration: InputDecoration(
//               hintText: 'Type your message',
//               suffixIcon: IconButton(
//                 icon: const Icon(Icons.send),
//                 onPressed: () {
//                   _sendMessage(_messageController.text);
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
