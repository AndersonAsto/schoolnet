import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/navigation/adminNavigation.dart';
import 'package:schoolnet/navigation/teacherNavigation.dart';
import 'package:schoolnet/screens/loginScreens/loginScreen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await storage.read(key: "auth_token");

    if (token != null) {
      try {
        // 🔹 Consultamos al backend quién es el usuario
        final res = await http.get(
          Uri.parse("http://localhost:3000/api/auth/profile"),
          headers: {
            "Authorization": "Bearer $token",
          },
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);

          Widget nextPage;
          if (data["role"] == "Administrador") {
            nextPage = const AdminNavigationRail();
          } else if (data["role"] == "Docente") {
            nextPage = TeacherNavigationRail(
              teacher: data["user"], // aquí asegúrate que tu API devuelva user
              token: token,
            );
          } else {
            nextPage = const LoginScreen();
          }

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => nextPage),
          );
        } else {
          // Token inválido → mandamos a login
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      // No hay sesión → login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
