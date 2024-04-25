import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class Waiting extends StatefulWidget {
  const Waiting({super.key});

  @override
  State<Waiting> createState() => _Waiting();
}

class _Waiting extends State<Waiting> {
  late TextEditingController _nameController;
  late TextEditingController _publicController;
  late TextEditingController _maxController;
  // 검색어 입력을 위한 컨트롤러
  final _searchController = TextEditingController();

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