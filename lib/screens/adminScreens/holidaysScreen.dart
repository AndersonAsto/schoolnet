import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'dart:convert';

import 'package:schoolnet/utils/customTextFields.dart';

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
    final response = await http.get(Uri.parse('${generalUrl}api/holidays/list'));
    if (response.statusCode == 200) {
      setState(() {
        holidays = json.decode(response.body);
      });
    }
  }

  Future<void> saveHoliday() async {
    if (selectedYearId == null || selectedDate == null) return;

    final response = await http.post(
      Uri.parse('${generalUrl}api/holidays/create'),
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
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Card(
                child: ExpansionTile(
                  title: const Text('Registrar/Actualizar Día Feriado'),
                  subtitle: const Text('Toca para expandir el formulario'),
                  leading: const Icon(Icons.add_box),
                  childrenPadding: const EdgeInsets.all(15),
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: DropdownButtonFormField<int>(
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
                            ),
                          )
                        ),
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
                            child: CustomTextField(
                              label: 'Fecha de Día Feriado',
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
                    CustomElevatedButtonIcon(
                      label: "Guardar Día Feriado",
                      icon: Icons.save,
                      onPressed: saveHoliday,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const CustomTitleWidget(
                child: Text('Días Feriados Registrados', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 15),
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
                      trailing: SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              color: h['status'] ? appColors[3] : Colors.red,
                              icon: Icon(h['status'] ? Icons.check_circle : Icons.cancel),
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
            ],
          ),
        ),
      ),
    );
  }
}