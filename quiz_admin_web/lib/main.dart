import 'package:flutter/material.dart';
import 'package:quiz_admin_web/screens/admin_dashboard.dart';
import 'package:quiz_admin_web/screens/signin_screen.dart';
import 'package:quiz_admin_web/services/api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const QuizAdminApp());
}

class QuizAdminApp extends StatelessWidget {
  const QuizAdminApp({super.key});

  Future<bool> _isAuthenticated() async {
    final token = await ApiService.getToken();
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz Admin Web',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: FutureBuilder<bool>(
        future: _isAuthenticated(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return snapshot.data == true
              ? const AdminDashboard()
              : const SignInScreen();
        },
      ),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}
