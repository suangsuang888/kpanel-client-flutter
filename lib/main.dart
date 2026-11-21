import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const KPanelClientApp());
}

class KPanelClientApp extends StatelessWidget {
  const KPanelClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KPanel 客户端',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
