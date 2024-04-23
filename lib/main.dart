import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SharedPreferences Demo',
      home: SharedPreferencesDemo(),
    );
  }
}

// SatefulWidget
class SharedPreferencesDemo extends StatefulWidget {
  const SharedPreferencesDemo({super.key});

  @override
  SharedPreferencesDemoState createState() => SharedPreferencesDemoState();
}

class SharedPreferencesDemoState extends State<SharedPreferencesDemo> {
  // shared preference 인스턴스 생성
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<int> _counter;

  // 플로팅 액션 버튼 클릭 이벤트
  Future<void> _incrementCounter() async {
    final SharedPreferences prefs = await _prefs;
    // counter 값이 존재하지 않으면 0으로 저장
    final int counter = (prefs.getInt('counter') ?? 0) + 1;

    // 앱의 상태 변경, 클릭시 카운트 +1
    setState(() {
      _counter = prefs.setInt('counter', counter).then((bool success) {
        return counter;
      });
    });
  }

  // 상태 위젯 초기화
  @override
  void initState() {
    super.initState();
    _counter =
        _prefs.then((SharedPreferences prefs) => prefs.getInt('counter') ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SharedPreferences Demo'),
      ),
      body: Center(
        // FutureBuilder : 비동기 위젯 빌드
        child: FutureBuilder<int>(
          future: _counter,
          // AsyncSnapshot : 완료, 오류, 결과 등의 상태 정보 포함
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            // 값을 받아오지 못할 경우
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            // 에러 발생할 경우
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            // 값을 정상적으로 받아올 경우
            else {
              return Text(
                'Button tapped ${snapshot.data} time${snapshot.data == 1 ? '' : 's'}.\n\n'
                'This should persist across restarts.',
              );
            }
          },
        ),
      ),
      // 플로팅 액션 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
