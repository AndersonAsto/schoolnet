import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:schoolnet/utils/customTextFields.dart';

class SchoolDaysByScheduleScreen extends StatefulWidget {
  const SchoolDaysByScheduleScreen({super.key});

  @override
  State<SchoolDaysByScheduleScreen> createState() => _SchoolDaysByScheduleScreenState();
}

class _SchoolDaysByScheduleScreenState extends State<SchoolDaysByScheduleScreen> {
  String? token;
  int? selectedYearId;
  List<dynamic> years = [];
  List<dynamic> schedulesByYear = [];
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

  Future<void> generateTeacherScheduleDaysFn() async {
    if (selectedYearId == null || teacherIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione un año y un docente.")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('${generalUrl}api/scheduleSDs/create-by-techer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'yearId': selectedYearId,
        'teacherId': int.parse(teacherIdController.text),
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Días lectivos generados correctamente.")),
      );
      // Opcional: recargar horarios o detalle según lo que muestres
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al generar días: ${response.body}")),
      );
    }
  }

  Future<void> fetchSchedulesByYear(int yearId) async {
    final response = await http.get(
      Uri.parse('${generalUrl}api/schedules/by-year/$yearId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        schedulesByYear = data; // cada item tiene years, schedules, etc según tu backend
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar horarios: ${response.body}")),
      );
    }
  }

  Future<void> showScheduleDaysModal(BuildContext context, int scheduleId) async {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<http.Response>(
          future: http.get(Uri.parse('${generalUrl}api/scheduleSDs/by-schedule/$scheduleId')),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return AlertDialog(
                title: const Text("Error"),
                content: const Text("Ocurrió un error al cargar los días lectivos."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cerrar"),
                  )
                ],
              );
            }

            final response = snapshot.data!;
            if (response.statusCode != 200) {
              return AlertDialog(
                title: const Text("Sin datos"),
                content: Text("No se encontraron días asociados a este horario.\n\n${response.body}"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cerrar"),
                  )
                ],
              );
            }

            final List<dynamic> days = jsonDecode(response.body);

            return AlertDialog(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checklist, color: appColors[3]),
                      const SizedBox(width: 8),
                      const Text("Días Lectivos del Horario", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
                    ],
                  ),
                  const Divider(),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 400,
                child: days.isEmpty
                    ? const Center(child: Text("No hay días lectivos generados para este horario."))
                    : ListView.builder(
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final schoolDay = day['schoolDays'];
                    final teachingBlock = day['teachingBlocks'];
                    final years = day['years'];
                    final schedule = day['schedules'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          "Fecha: ${schoolDay['teachingDay']} (${schoolDay['weekday']})",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Año: ${years['year']} | Bloque: ${teachingBlock['teachingBlock']}\n"
                              "Horario: ${schedule['startTime']} - ${schedule['endTime']}",
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inicializa el source con los datos y la función del modal
    final scheduleDataSource = ScheduleDataSource(
      schedulesByYear,
      context,
      showScheduleDaysModal, // La función que ya tenías
    );

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
              //Crear y eliminar días lectivos por horario
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
                              onChanged: (value) async {
                                setState(() {
                                  selectedYearId = value;
                                });
                                if (value != null) {
                                  await fetchSchedulesByYear(value);
                                }
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
                          onPressed: generateTeacherScheduleDaysFn,
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
              CustomTitleWidget(
                child: Text(selectedYearId == null ? 'Días Lectivos por Horario Registrados': 'Horarios del Año Seleccionado', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 15),
              if (selectedYearId != null) ...[
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                    child: PaginatedDataTable(
                      rowsPerPage: 10,
                      columns: const <DataColumn>[
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Docente')),
                        DataColumn(label: Text('Curso')),
                        DataColumn(label: Text('Grado')),
                        DataColumn(label: Text('Sección')),
                        DataColumn(label: Text('Día')),
                        DataColumn(label: Text('Horas')),
                        DataColumn(label: Text('Días Lectivos')),
                      ],
                      source: scheduleDataSource,
                      columnSpacing: 10,
                      horizontalMargin: 10,
                    ),
                  )
                ),
              ] else if (years.isNotEmpty && selectedYearId == null) ...[
                const Center(child: Text('Por favor, seleccione un año para ver los horarios.'))
              ] else if (selectedYearId != null && schedulesByYear.isEmpty) ...[
                const Center(child: Text('No hay horarios registrados para el año seleccionado.'))
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ScheduleDataSource extends DataTableSource {
  final List<dynamic> schedules;
  final BuildContext context;
  final Function(BuildContext, int) showDaysModal; // Función para mostrar el modal

  ScheduleDataSource(this.schedules, this.context, this.showDaysModal);

  @override
  DataRow? getRow(int index) {
    if (index >= schedules.length) {
      return null;
    }
    final schedule = schedules[index];
    final teacher = schedule['teachers'];
    final person = teacher['persons'];

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(schedule['id'].toString(), style: const TextStyle(fontSize: 11))),
        DataCell(Text("${person['names']} ${person['lastNames']}", style: const TextStyle(fontSize: 11))),
        DataCell(Text(schedule['courses']?['course'] ?? 'N/A', style: const TextStyle(fontSize: 11))),
        DataCell(Text(schedule['grades']?['grade'] ?? 'N/A', style: const TextStyle(fontSize: 11))),
        DataCell(Text(schedule['sections']?['seccion'] ?? 'N/A', style: const TextStyle(fontSize: 11))),
        DataCell(Text(schedule['weekday'] ?? '', style: const TextStyle(fontSize: 11))),
        DataCell(Text("${schedule['startTime']} - ${schedule['endTime']}", style: const TextStyle(fontSize: 11))),
        DataCell(
          IconButton(
            icon: Icon(Icons.calendar_month, color: appColors[3], size: 18),
            tooltip: "Ver Días Lectivos",
            onPressed: () => showDaysModal(context, schedule['id']),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => schedules.length;

  @override
  int get selectedRowCount => 0;
}