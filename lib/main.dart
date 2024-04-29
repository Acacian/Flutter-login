import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:firebase_database/firebase_database.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart' as shelf_web_socket;
// import 'package:web_socket_channel/web_socket_channel.dart';

// 대기페이지 가져오기
import 'Container/auth.dart' as login;

Future<void> main() async {
  final logger = Logger();
  final webSocketHandler = shelf_web_socket.webSocketHandler((channel) {
    channel.stream.listen(
      (message) {
        // 메시지 처리 로직
        logger.i('Received message: $message');
      },
      onDone: () {
        logger.i('WebSocket connection closed');
      },
      onError: (error) {
        logger.e('WebSocket error: $error');
      },
    );
  });

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final router = shelf_router.Router();
  router
    ..get('/', _handleLoginRequest)
    ..get('/firebase', _handleFirebaseRequest)
    ..get('/socket.io/', webSocketHandler);

  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(router.call);
  final server = await shelf_io.serve(handler, 'localhost', 3000);

  if (server.address.isLoopback) {
    logger.i('Server running at http://${server.address.host}:${server.port}');
  } else {
    logger.e(
        'Server not running at http://${server.address.host}:${server.port}');
  }

  // Socket.IO 클라이언트 연결
  try {
    _connectToServer();
  } catch (e) {
    logger.e('Socket.IO 클라이언트 연결 실패: $e');
  }

  // 앱 실행
  runApp(const MyApp());
}

Future<shelf.Response> _handleLoginRequest(shelf.Request request) async {
  return shelf.Response.ok(
    'Welcome to the login page!',
    headers: {'content-type': 'text/plain'},
  );
}

Future<shelf.Response> _handleFirebaseRequest(shelf.Request request) async {
  final databaseRef = FirebaseDatabase.instance.ref();
  final snapshot = await databaseRef.child('data').get();
  if (snapshot.exists) {
    return shelf.Response.ok(snapshot.value.toString());
  } else {
    return shelf.Response.internalServerError(
        body: 'Error accessing Firebase Realtime Database');
  }
}

void _connectToServer() {
  final logger = Logger();
  final socket = io.io('http://localhost:3000');
  socket.connect();

  socket.onConnect((_) {
    socket.emit('msg', 'test');
    logger.i('socket_connect');
  });
  socket.on('event', (data) => logger.i(data));
  socket.onDisconnect((_) => logger.e('disconnect'));
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Game',
      home: const login.Loginpage(),
      routes: {
        '/home': (context) => const login.Loginpage(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
