import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// flame 쓰니까 가로로 고정
import 'package:flutter/services.dart';

// 대기페이지 가져오기
import 'Container/auth.dart' as login;

// realtime sync imports
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setPreferredOrientations();
  await initializeSupabase();
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
  @override
  void initState() {
    super.initState();
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

Future<void> initializeSupabase() async {
  // HW
  // await Supabase.initialize(
  //   url: 'https://djeovzmiajfslovjeafy.supabase.co',
  //   anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqZW92em1pYWpmc2xvdmplYWZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTM3NzMxOTcsImV4cCI6MjAyOTM0OTE5N30.qUak0tbzXZIep0rfSbIp3Tznxowg0uiiMgeSGiD3znY',
  //   realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 40),
  // );

  // JW
  // await Supabase.initialize(
  //   url: 'https://pqyrqglvljqrdvogvfdk.supabase.co',
  //   anonKey:
  //       'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxeXJxZ2x2bGpxcmR2b2d2ZmRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTM2Mjc2NjIsImV4cCI6MjAyOTIwMzY2Mn0.bo5bfyE9CB0dHUhqKkk7THhD7xE_RBiSfs52SY-ifxI',
  //   realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 40),
  // );

  // DH
  await Supabase.initialize(
    url: 'https://peatgpjkmvgnkfwrsghz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBlYXRncGprbXZnbmtmd3JzZ2h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTQ1NDI1NzIsImV4cCI6MjAzMDExODU3Mn0.bOsb4cgZLoPbrO_pwt8QsTHcC584axvNz5ECFuRpibQ',
    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 40),
  );
}

final supabase = Supabase.instance.client;

Future<void> setPreferredOrientations() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
}
