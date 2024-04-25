import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// 로그인페이지 가져오기(디폴트페이지)
import 'Container/auth.dart';
// 대기페이지 가져오기
import 'ReadyContainer/waiting.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Game',
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // 경로 이름 분석
        final Uri uri = Uri.parse(settings.name!);
        final String gameRoute = uri.path.replaceFirst('/', '');
        // 경로에 따라 적절한 위젯 반환
        if (gameRoute == '') {
          return MaterialPageRoute(builder: (context) => const Loginpage());
        } else if (gameRoute == 'waiting/${uri.query}') {
          return MaterialPageRoute(builder: (context) => const Waiting());
        } else {
          // 경로매칭실패
          return null;
        }
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
