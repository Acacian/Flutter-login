import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

// 대기페이지 가져오기
import 'Container/auth.dart' as login;

Response _echoRequest(Request request) {
  return Response.ok('You said: ${request.url}');
}

void main() async {
  final logger = Logger();
  // 서버 생성
  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(_echoRequest);

  final server = await io.serve(handler, 'localhost', 3000);
  logger.i('Serving at http://${server.address.host}:${server.port}');

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
      logger.i('socket_connect');
    });

    socket.on('event', (data) => logger.i(data));
    socket.onDisconnect((_) => logger.e('disconnect'));
  }

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
