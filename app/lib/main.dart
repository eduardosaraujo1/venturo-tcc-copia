// Server: http://92.246.130.43:8080

import 'package:flutter/material.dart';
import 'package:algumacoisa/cuidador/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginUnificadoScreen(),
    );
  }
}
