// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:student_activity_apps/Screen/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [Color(0xFF081229), Color(0xFF143A7B), Color(0xFF1EA7FF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔹 LOGO
              Image.asset(
                'assets/logo.png', // put your logo here
                scale: 1,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.home_outlined, size: 120, color: Colors.white70),
              ),

              const SizedBox(height: 20),

              // 🔹 APP NAME
              const Text(
                "Student Activity Registration Apps",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 TAGLINE (optional)
              const Text(
                "- Register - Participate - Connect -",
                style: TextStyle(fontSize: 20, color: Colors.white70),
              ),

              const SizedBox(height: 40),

              // 🔹 LOADING
              const CircularProgressIndicator(
                color: Color(0xFFFFC107), // brighter amber
              ),
            ],
          ),
        ),
      ),
    );
  }
}
