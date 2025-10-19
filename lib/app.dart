import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kakiso Splash App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),

      home: const SplashScreen(),
    );
  }
}
