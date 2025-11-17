import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customTextFields.dart';

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
      final response =
          await http.get(Uri.parse('${generalUrl}api/teachingBlocks/list'));
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

    if (selectedYears == null ||
        teachingBlock.isEmpty ||
        startDay.isEmpty ||
        endDay.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${generalUrl}api/teachingBlocks/create'),
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
        title: const Text(
          'Bloques Lectivos',
          style: TextStyle(fontSize: 15, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: materialTextSelectionControls,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Card(
                child: ExpansionTile(
                  title: const Text('Registrar/Actualizar Bloque Lectivo'),
                  subtitle: const Text('Toca para expandir el formulario'),
                  leading: const Icon(Icons.add_box),
                  childrenPadding: const EdgeInsets.all(15),
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: DropdownButtonFormField<dynamic>(
                              value: selectedYears,
                              items: yearsList.map((year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year['year'].toString()),
                                );
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => selectedYears = value),
                              decoration: InputDecoration(
                                labelText: "Seleccionar Año",
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(width: 1, color: Colors.black,),
                                ),
                              ),
                            ),
                          )
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            controller: blockController,
                            label: 'Bloque Lectivo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: startDayController,
                            label: 'Fecha de Inicio',
                            readOnly: true,
                            onTap: () => selectDate(startDayController),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            controller: endDayController,
                            readOnly: true,
                            onTap: () => selectDate(endDayController),
                            label: 'Fecha de Fin',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CustomElevatedButtonIcon(
                      label: "Registrar Bloque Lectivo",
                      icon: Icons.save,
                      onPressed: createBlocks,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const CustomTitleWidget(
                child: Text('Bloques Lectivos Registrados',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(height: 15),
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
                      trailing: SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              color: block['status'] ? appColors[3] : Colors.red,
                              icon: Icon(block['status'] ? Icons.check_circle : Icons.cancel),
                              onPressed: () {},
                              tooltip: 'Estado',
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: appColors[3]),
                              onPressed: () {},
                              tooltip: 'Editar Bloque',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {},
                              tooltip: 'Eliminar Bloque',
                            ),
                          ],
                        ),
                      )
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
