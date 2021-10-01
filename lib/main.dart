import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/error_screen.dart';
import 'screens/home_screen.dart';
import 'screens/loading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ConfApp());
}

class ConfApp extends StatefulWidget {
  const ConfApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ConfAppState();
}

class ConfAppState extends State<ConfApp> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return MaterialApp(
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                ),
                home: const ErrorScreen());
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return MaterialApp(
              title: 'Free Sagiton Conf',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              home: const HomeScreen(title: 'Salki Sagitonu'),
            );
          }

          return MaterialApp(
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              home: const LoadingScreen());
        });
  }
}
