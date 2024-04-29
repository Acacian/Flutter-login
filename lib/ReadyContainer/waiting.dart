import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:firebase_database/firebase_database.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart' as shelf_web_socket;
// import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> running() async {
  final logger = Logger();
  final webSocketHandler = shelf_web_socket.webSocketHandler((channel) {
    channel.stream.listen(
      (message) {
        logger.i('Received message: $message');
      },
      onError: (error) {
        logger.e('WebSocket error: $error');
      },
    );
  });

  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

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
    logger.i('socket_connect');
    if (socket.connected) {
      logger.i('WebSocket connection established');
    } else {
      logger.e('WebSocket connection failed');
    }
    socket.emit('msg', 'test');
  });
  socket.on('event', (data) => logger.i(data));
  socket.onDisconnect((_) => logger.e('disconnect'));
}

class Waiting extends StatefulWidget {
  const Waiting({super.key});

  @override
  State<Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<Waiting> {
  final logger = Logger();
  late io.Socket socket;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket.IO Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            socket.emit('msg', 'test');
          },
          child: const Text('Send Message'),
        ),
      ),
    );
  }
}
