import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';

class TeachingBlocksScreen extends StatefulWidget {
  const TeachingBlocksScreen({super.key});

  @override
  State<TeachingBlocksScreen> createState() => _TeachingBlocksScreenState();
}

class _TeachingBlocksScreenState extends State<TeachingBlocksScreen> {
  final TextEditingController blockController = TextEditingController();
  final TextEditingController startDayController = TextEditingController();
  final TextEditingController endDayController = TextEditingController();

  List<dynamic> yearsList = [];
  List<dynamic> teachingBlocks = [];
  String? token;
  dynamic selectedYears;

  final String apiUrl = 'http://localhost:3000/api';

  @override
  void initState() {
    super.initState();
    fetchYears();
    _fetchBloques();
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
          yearsList = json.decode(response.body);
        });
      } else {
        print("Error al cargar años: ${response.body}");
      }
    } catch (e) {
      print('Error cargando años: $e');
    }
  }


  Future<void> _fetchBloques() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/teachingBlocks/list'));
      if (response.statusCode == 200) {
        setState(() {
          teachingBlocks = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error cargando bloques: $e');
    }
  }

  Future<void> createBlocks() async {
    final teachingBlock = blockController.text.trim();
    final startDay = startDayController.text.trim();
    final endDay = endDayController.text.trim();

    if (selectedYears == null || teachingBlock.isEmpty || startDay.isEmpty || endDay.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/teachingBlocks/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'yearId': selectedYears['id'],
          'teachingBlock': teachingBlock,
          'startDay': startDay,
          'endDay': endDay,
        }),
      );

      if (response.statusCode == 201) {
        startDayController.clear();
        endDayController.clear();
        await _fetchBloques();
      } else {
        print('Error al registrar bloque: ${response.body}');
      }
    } catch (e) {
      print('Error en conexión: $e');
    }
  }

  Future<void> selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
    );

    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bloques Lectivos', style: TextStyle(fontSize: 15, color: Colors.white),),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SelectableRegion(
          focusNode: FocusNode(),
          selectionControls: materialTextSelectionControls,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ExpansionTile(
                    title: const Text('Registrar Nuevo Bloque Lectivo'),
                    subtitle: const Text('Toca para expandir el formulario'),
                    leading: const Icon(Icons.add_box),
                    childrenPadding: const EdgeInsets.all(16.0),
                    children: <Widget>[
                      Row(
                        children: [
                          Expanded(child: DropdownButtonFormField<dynamic>(
                            value: selectedYears,
                            items: yearsList.map((year) {
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year['year'].toString()),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => selectedYears = value),
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar Año',
                              border: OutlineInputBorder(),
                            ),
                          ),),
                          const SizedBox(width: 10),
                          Expanded(child: TextField(
                            controller: blockController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del Bloque Lectivo',
                              border: OutlineInputBorder(),
                            ),
                          ),),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: TextField(
                            controller: startDayController,
                            readOnly: true,
                            onTap: () => selectDate(startDayController),
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Inicio',
                              border: OutlineInputBorder(),
                            ),
                          ),),
                          const SizedBox(width: 10),
                          Expanded(child: TextField(
                            controller: endDayController,
                            readOnly: true,
                            onTap: () => selectDate(endDayController),
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Fin',
                              border: OutlineInputBorder(),
                            ),
                          ),),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: createBlocks,
                            icon: const Icon(Icons.save),
                            label: const Text("Registrar Bloque Lectivo"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const Divider(height: 20),
                const Text('Bloques Lectivos Registrados', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teachingBlocks.length,
                  itemBuilder: (context, index) {
                    final block = teachingBlocks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: appColors[3]),
                        title: Text(block['teachingBlock']),
                        subtitle: Text(
                          'Año: ${block['years']['year']}, '
                              'Inicio: ${block['startDay']}, '
                              'Fin: ${block['endDay']}',
                        ),
                        trailing: Icon(
                          block['status'] ? Icons.check_circle : Icons.cancel,
                          color: block['status'] ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ),
    );
  }
}