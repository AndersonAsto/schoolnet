import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:schoolnet/navigation/adminNavigation.dart';
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
      // 🔹 Aquí podrías decodificar el token JWT para saber el rol
      // pero por simplicidad vamos a cargar Admin directamente
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminNavigationRail()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
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
