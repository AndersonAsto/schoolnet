import 'package:flutter/material.dart';
import 'package:schoolnet/navigation/adminNavigation.dart';
import 'package:schoolnet/navigation/parentNavigation.dart';
import 'package:schoolnet/navigation/teacherNavigation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:schoolnet/utils/colors.dart';

final storage = FlutterSecureStorage();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse("${generalUrl}api/auth/login"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "username": _userController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar token, rol y usuario en Storage()
        await storage.write(key: "auth_token", value: data["token"]);
        await storage.write(key: "refresh_token", value: data["refreshToken"]);
        await storage.write(key: "role", value: data["role"]);
        await storage.write(key: "user", value: jsonEncode(data["user"]));

        final role = (data["role"] as String).toLowerCase();

        // Apoderado
        if (role == "apoderado") {
          final user = data["user"];
          final userId = user["id"];

          final parentRes = await http.get(
            Uri.parse(
              "${generalUrl}api/parentAssignments/by-user/$userId",
            ),
          );

          if (parentRes.statusCode == 200) {
            final decoded = jsonDecode(parentRes.body);

            if (decoded is List && decoded.isNotEmpty) {
              // Decodificar la lista de estudiante en base a el apoderado
              final List assignments = decoded;

              // Tomar el primer año
              final first = assignments.first;
              final parentPersonId = first["persons"]["id"];
              final yearId = first["years"]["id"];

              // Lista plana de estudiantes
              final List<Map<String, dynamic>> students = assignments.map<Map<String, dynamic>>((item) {
                final student = item["students"];
                final person = student["persons"];
                return {
                  "id": student["id"],
                  "personId": person["id"],
                  "names": person["names"],
                  "lastNames": person["lastNames"],
                  "yearId": item["years"]["id"],
                };
              }).toList();

              // Guardar los datos necesarios en Storage()
              await storage.write(
                key: "parent_assignments",
                value: jsonEncode(assignments),
              );
              await storage.write(
                key: "parent_user_id",
                value: userId.toString(),
              );
              await storage.write(
                key: "parent_person_id",
                value: parentPersonId.toString(),
              );
              await storage.write(
                key: "parent_year_id",
                value: yearId.toString(),
              );
              await storage.write(
                key: "parent_students",
                value: jsonEncode(students),
              );

              // Navegación envíando usuario y lista de estudiantes
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ParentsNavigationRail(
                    parent: {
                      ...user,
                      "userId": userId,
                      "parentPersonId": parentPersonId,
                      "yearId": yearId,
                      "students": students,
                    },
                    token: data["token"],
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No se encontraron asignaciones de apoderado."),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "No se pudo cargar datos de apoderado: ${parentRes.body}",
                ),
              ),
            );
          }

          return; // importante
        }

        // Administrador y docente
        Widget nextPage = const LoginScreen();

        if (role == "administrador") {
          nextPage = const AdminNavigationRail();
        } else if (role == "docente") {
          nextPage = TeacherNavigationRail(
            teacher: data["user"],
            token: data["token"],
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Rol no autorizado.")),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextPage),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff204760),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            color: const Color(0xff3b7861),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "SchoolNet",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _userController,
                      decoration: InputDecoration(
                        labelText: "Usuario",
                        labelStyle: const TextStyle(color: Colors.white),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                        filled: true,
                        fillColor: const Color(0xff256d7b),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) =>
                      value!.isEmpty ? "Ingrese su usuario" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        labelStyle: const TextStyle(color: Colors.white),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.white,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xff256d7b),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) =>
                      value!.isEmpty ? "Ingrese su contraseña" : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff204760),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          "Ingresar",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
