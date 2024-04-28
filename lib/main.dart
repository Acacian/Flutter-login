import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';

// 대기페이지 가져오기
import 'Container/auth.dart' as login;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //서버 켜기
  final server = const MyServerWidget();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Game',
      home: const login.Loginpage(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

class MyServerWidget extends StatefulWidget {
  const MyServerWidget({super.key});

  @override
  MyServerWidgetState createState() => MyServerWidgetState();
}

class MyServerWidgetState extends State<MyServerWidget> {
  final logger = Logger();
  late io.Socket socket;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  void _connectToServer() {
    socket = io.io('http://localhost:3000');
    socket.onConnect((_) {
      socket.emit('msg', 'test');
    });

    socket.on('event', (data) => logger.i(data));
    socket.onDisconnect((_) => logger.e('disconnect'));
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // 빈 컨테이너를 반환
  }
}
