import 'package:flutter/material.dart';

void main() {
  runApp(const ShopLensApp());
}

class ShopLensApp extends StatelessWidget {
  const ShopLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('ShopLens')),
      ),
    );
  }
}
