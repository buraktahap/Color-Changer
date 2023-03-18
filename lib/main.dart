import 'package:color_changer/home_page3.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';
import 'home_page2.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Palette-based Photo Recoloring')),
        body: const MyHomePage3(),
      ),
    );
  }
}
