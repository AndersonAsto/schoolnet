import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'dart:convert';

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  List<dynamic> years = [];
  int? selectedYearId;
  DateTime? selectedDate;
  List<dynamic> holidays = [];

  String? token;

  Future<void> loadTokenAndData() async {
    final savedToken = await storage.read(key: "auth_token");
    if (savedToken != null) {
      setState(() => token = savedToken);
      await fetchYears();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchYears();
    fetchHolidays();
    loadTokenAndData();
  }

  Future<void> fetchYears() async {
    final response = await ApiService.request("api/years/list");
    if (response.statusCode == 200) {
      setState(() {
        years = json.decode(response.body);
      });
    }
  }

  Future<void> fetchHolidays() async {
    final response = await http.get(Uri.parse('${apiUrl}api/holidays/list'));
    if (response.statusCode == 200) {
      setState(() {
        holidays = json.decode(response.body);
      });
    }
  }

  Future<void> saveHoliday() async {
    if (selectedYearId == null || selectedDate == null) return;

    final response = await http.post(
      Uri.parse('${apiUrl}api/holidays/create'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'yearId': selectedYearId,
        'holiday': selectedDate!.toIso8601String().split('T')[0],
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feriado registrado')),
      );
      setState(() {
      });
      fetchHolidays();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar feriado')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Días Feriados', style: TextStyle(fontSize: 15, color: Colors.white),),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SelectableRegion(
          focusNode: FocusNode(),
          selectionControls: materialTextSelectionControls,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ExpansionTile(
                    title: const Text('Registrar Nuevo Día Feriado'),
                    subtitle: const Text('Toca para expandir el formulario'),
                    leading: const Icon(Icons.add_box),
                    childrenPadding: const EdgeInsets.all(16.0),
                    children: <Widget>[
                      Row(
                        children: [
                          Expanded(child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar Año',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedYearId,
                            items: years.map<DropdownMenuItem<int>>((year) {
                              return DropdownMenuItem<int>(
                                value: year['id'],
                                child: Text('${year['year']}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedYearId = value;
                              });
                            },
                          ),),
                          const SizedBox(width: 10),
                          Expanded(child: GestureDetector(
                            onTap: () async {
                              DateTime now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: now,
                                firstDate: DateTime(now.year - 5),
                                lastDate: DateTime(now.year + 5),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Selecciona la Fecha del Feriado',
                                  hintText: 'yyyy-mm-dd',
                                ),
                                controller: TextEditingController(
                                  text: selectedDate == null
                                      ? ''
                                      : selectedDate!.toIso8601String().split('T')[0],
                                ),
                              ),
                            ),
                          ),),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: saveHoliday,
                        child: const Text('Guardar Feriado'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 20),
                const Text('Días Feriados Registrados', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: holidays.length,
                  itemBuilder: (context, index) {
                    final h = holidays[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: appColors[3]),
                        title: Text('Feriado: ${h['holiday']}'),
                        subtitle: Text('Año: ${h['years']['year']}'),
                        trailing: Icon(
                          h['status'] ? Icons.check_circle : Icons.cancel,
                          color: h['status'] ? Colors.green : Colors.red,
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