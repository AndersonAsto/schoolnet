import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:schoolnet/utils/customTextFields.dart';

class SchoolDaysBySchedules extends StatefulWidget {
  const SchoolDaysBySchedules({super.key});

  @override
  State<SchoolDaysBySchedules> createState() => _SchoolDaysBySchedulesState();
}

class _SchoolDaysBySchedulesState extends State<SchoolDaysBySchedules> {
  String? token;
  int? selectedYearId;
  List<dynamic> years = [];
  Map<int, List<dynamic>> schoolDaysPerYear = {};
  TextEditingController teacherIdController = TextEditingController();
  TextEditingController teacherDisplayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchYears();
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
    final response = await ApiService.request("api/years/list");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        years = data;
      });
      // Cargar los días lectivos por cada año
      for (var year in data) {
        await fetchSchoolDaysByYear(year['id']);
      }
    }
  }

  Future<void> fetchSchoolDaysByYear(int yearId) async {
    final response = await http.get(Uri.parse('${generalUrl}api/schoolDays/byYear/$yearId'));
    if (response.statusCode == 200) {
      final dias = jsonDecode(response.body);
      setState(() {
        schoolDaysPerYear[yearId] = dias;
      });
    }
  }

  Future<void> generateSchoolDays() async {
    if (selectedYearId == null) return;

    final bloquesRes = await http.get(Uri.parse('${generalUrl}api/teachingBlocks/byYear/$selectedYearId'));
    final feriadosRes = await http.get(Uri.parse('${generalUrl}api/holidays/byYear/$selectedYearId'));

    if (bloquesRes.statusCode == 200 && feriadosRes.statusCode == 200) {
      final bloques = jsonDecode(bloquesRes.body);
      final feriados = (jsonDecode(feriadosRes.body) as List).map((f) => f['holiday']).toSet();

      final fechasLectivas = <String>{};

      for (var bloque in bloques) {
        final inicio = DateTime.parse(bloque['startDay']);
        final fin = DateTime.parse(bloque['endDay']);

        for (var d = inicio; !d.isAfter(fin); d = d.add(Duration(days: 1))) {
          if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
            final formato = d.toIso8601String().split('T')[0];
            if (!feriados.contains(formato)) {
              fechasLectivas.add(formato);
            }
          }
        }
      }

      final response = await http.post(
        Uri.parse('${generalUrl}api/schoolDays/bulkCreate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'yearId': selectedYearId,
          'teachingDay': fechasLectivas.toList()
        }),
      );

      if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ya existen días lectivos para este año."))
        );
        return;
      }

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Días lectivos generados correctamente.")));
        await fetchSchoolDaysByYear(selectedYearId!); // Actualizar la vista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al generar días.")));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Días Lectivos por Horario', style: TextStyle(fontSize: 15, color: Colors.white),),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: materialTextSelectionControls,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: <Widget>[
              Card(
                child: ExpansionTile(
                  title: const Text('Registrar/Eliminar Días Lectivos por Horario'),
                  subtitle: const Text('Toca para expandir el formulario'),
                  leading: const Icon(Icons.add_box),
                  childrenPadding: const EdgeInsets.all(15),
                  children: [
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
                              items: years.map((year) {
                                return DropdownMenuItem<int>(
                                  value: year['id'],
                                  child: Text(year['year'].toString()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedYearId = value;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: SelectionField(
                            labelText: "Seleccionar Docente",
                            displayController: teacherDisplayController,
                            idController: teacherIdController,
                            onTap: () async => await showTeacherSelection(context, teacherIdController, teacherDisplayController),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomElevatedButtonIcon(
                          label: "Generar Días Lectivos",
                          icon: Icons.save,
                          onPressed: generateSchoolDays,
                        ),
                        CustomElevatedButtonIcon(
                          label: "Eliminar Días Lectivos",
                          icon: Icons.delete_outline_outlined,
                          onPressed: (){},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const CustomTitleWidget(
                child: Text('Días Lectivos por Horario', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: years.length,
                itemBuilder: (context, index) {
                  final year = years[index];
                  final dias = schoolDaysPerYear[year['id']] ?? [];
                  return ExpansionTile(
                    title: Text('Año ${year['year']}'),
                    children: dias.isEmpty
                        ? [ListTile(title: Text("Sin días lectivos generados"))]
                        : dias.map<Widget>((dia) {
                      return ListTile(
                        title: Text("ID: ${dia['id']}"),
                        subtitle: Text("Fecha: ${dia['teachingDay']} | Día: ${dia['weekday']} | Semana: ${dia['weekNumber']}"),
                      );
                    }).toList(),
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