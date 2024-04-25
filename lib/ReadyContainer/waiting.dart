import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class Waiting extends StatefulWidget {
  const Waiting({super.key});

  @override
  State<Waiting> createState() => _Waiting();
}

class _Waiting extends State<Waiting> {
  // 실시간 채팅
  final _chatController = TextEditingController();
  Logger logger = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Game Waiting Room'),
      ),
    );
  }
}


//TODO : 나가면 realtimedata에서 방 삭제