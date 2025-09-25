import 'package:flutter/material.dart';
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
const apiUrl = "http://localhost:3000/";

class YearsScreen extends StatefulWidget {
  const YearsScreen({super.key});

  @override
  State<YearsScreen> createState() => _YearsScreenState();
}

class _YearsScreenState extends State<YearsScreen> {
  String? token;
  final TextEditingController yearController = TextEditingController();
  List<dynamic> years = [];

  @override
  void initState() {
    super.initState();
    loadTokenAndData();
  }

  Future<void> loadTokenAndData() async {
    final savedToken = await storage.read(key: "auth_token");
    if (savedToken != null) {
      setState(() => token = savedToken);
      await fetchYears();
    }
  }

  Future<void> fetchYears() async {
    try {
      final response = await ApiService.request("api/years/list");

      if (response.statusCode == 200) {
        setState(() {
          years = json.decode(response.body);
        });
      } else {
        print("Error al obtener años: ${response.body}");
      }
    } catch (e) {
      print("Error al conectar: $e");
    }
  }

  Future<void> createYear() async {
    final input = yearController.text.trim();
    if (input.isEmpty) return;

    final year = int.tryParse(input);
    if (year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa un año válido")),
      );
      return;
    }

    try {
      final response = await ApiService.request(
        "api/years/create",
        method: "POST",
        body: {"year": year},
      );

      if (response.statusCode == 201) {
        yearController.clear();
        await fetchYears();
      } else {
        print("Error al crear año: ${response.body}");
      }
    } catch (e) {
      print("Error al conectar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Años",
            style: TextStyle(fontSize: 15, color: Colors.white)),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Ingresar Año",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: createYear,
                  child: const Text("Guardar"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text("Años Registrados",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (context, index) {
                  final item = years[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: Icon(Icons.calendar_today, color: appColors[3]),
                      title: Text("${item['year']}"),
                      subtitle: Text(
                          "ID: ${item['id']} - Estado: ${item['status'] ? "Activo" : "Inactivo"}"),
                      trailing: Icon(
                        item['status'] ? Icons.check_circle : Icons.cancel,
                        color: item['status'] ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}