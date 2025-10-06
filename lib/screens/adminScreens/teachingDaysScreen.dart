import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeachingDaysScreen extends StatefulWidget {
  const TeachingDaysScreen({super.key});

  @override
  State<TeachingDaysScreen> createState() => _TeachingDaysScreenState();
}

class _TeachingDaysScreenState extends State<TeachingDaysScreen> {
  int? selectedYearId;
  List<dynamic> years = [];
  Map<int, List<dynamic>> schoolDaysPerYear = {};
  String? token;

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
    final response = await http.get(Uri.parse('http://localhost:3000/api/schoolDays/byYear/$yearId'));
    if (response.statusCode == 200) {
      final dias = jsonDecode(response.body);
      setState(() {
        schoolDaysPerYear[yearId] = dias;
      });
    }
  }

  Future<void> generateSchoolDays() async {
    if (selectedYearId == null) return;

    final bloquesRes = await http.get(Uri.parse('http://localhost:3000/api/teachingBlocks/byYear/$selectedYearId'));
    final feriadosRes = await http.get(Uri.parse('http://localhost:3000/api/holidays/byYear/$selectedYearId'));

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
        Uri.parse('http://localhost:3000/api/schoolDays/bulkCreate'),
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
        title: const Text('Días Lectivos', style: TextStyle(fontSize: 15, color: Colors.white),),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SelectableRegion(
          focusNode: FocusNode(),
          selectionControls: materialTextSelectionControls,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ExpansionTile(
                    title: const Text('Registrar Nuevos Días Lectivos'),
                    subtitle: const Text('Toca para expandir el formulario'),
                    leading: const Icon(Icons.add_box),
                    childrenPadding: const EdgeInsets.all(16.0),
                    children: [
                      Row(
                        children: [
                          Expanded(child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar Año',
                              border: OutlineInputBorder(),
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
                          ),),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: generateSchoolDays,
                            child: const Text("Generar Días Lectivos"),
                          ),
                          ElevatedButton(
                            onPressed: (){},
                            child: const Text("Eliminar Días Lectivos"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20),
                const Text('Días Lectivos Registrados', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                const SizedBox(height: 20),
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