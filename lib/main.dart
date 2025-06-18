import 'package:flutter/material.dart';
import 'package:selfix/screens/home_screen.dart';
import 'package:selfix/providers/photo_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(SelfiePhotoBoothApp());
}

class SelfiePhotoBoothApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
      ],
      child: MaterialApp(
        title: 'Selfix',
        theme: ThemeData(
          primarySwatch: Colors.pink,
        ),
        home: HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}