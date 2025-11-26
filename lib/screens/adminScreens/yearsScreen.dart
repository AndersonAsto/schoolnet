import 'package:flutter/material.dart';
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/customTextFields.dart';

final storage = FlutterSecureStorage();

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
      
      final Map<String, dynamic> errorData = json.decode(response.body);
      final backendMessage = errorData['message'] ?? "Mensaje de error desconocido";
      final formattedMessage = "Error ${response.statusCode}: ${backendMessage}";

      if (response.statusCode == 200) {
        setState(() {
          years = json.decode(response.body);
        });
      } else {
        CustomNotifications.showNotification(context, formattedMessage, color: Colors.red);
        print("Error al eliminar usuario (HTTP ${response.statusCode}): ${backendMessage}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de servidor inesperado.", color: Colors.red);
      print("Fallo al parsear JSON. Body: $e");
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
        title: const Text("Años", style: TextStyle(fontSize: 15, color: Colors.white)),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: materialTextSelectionControls,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Card(
                child: ExpansionTile(
                  title: const Text('Registrar/Actualizar Año'),
                  subtitle: const Text('Toca para expandir el formulario'),
                  leading: const Icon(Icons.add_box),
                  childrenPadding: const EdgeInsets.all(15),
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: yearController,
                            keyboardType: TextInputType.number,
                            label: 'Año',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CustomElevatedButtonIcon(
                      label: "Guardar",
                      icon: Icons.save,
                      onPressed: createYear,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const CustomTitleWidget(
                child: Text("Años Registrados",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white,),
                ),
              ),
              const SizedBox(height: 15),
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
                        trailing: SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                color: item['status'] ? appColors[3] : Colors.red,
                                icon: Icon(item['status'] ? Icons.check_circle : Icons.cancel),
                                onPressed: () {},
                                tooltip: 'Estado',
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: appColors[3]),
                                onPressed: () {},
                                tooltip: 'Editar Año',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {},
                                tooltip: 'Eliminar Año',
                              ),
                            ],
                          ),
                        )
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
