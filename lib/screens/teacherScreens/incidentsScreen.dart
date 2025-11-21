import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/screens/teacherScreens/assistancesScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:schoolnet/utils/customTextFields.dart';

class IncidentsScreen extends StatefulWidget {
  final int teacherId;
  final String token;

  const IncidentsScreen({
    super.key,
    required this.teacherId,
    required this.token
  });

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  TextEditingController yearIdController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();
  TextEditingController selectedDayController = TextEditingController();
  TextEditingController incidentDetailController = TextEditingController();
  TextEditingController selectedDateController = TextEditingController();

  List incidents = [];
  List schedules = [];
  List schoolDays = [];
  List students = [];

  String? selectedScheduleId;
  String? selectedStudentId;
  String? selectedSchoolDayId;
  String? token;

  bool loadingIncidents = false;
  bool loadingSchedules = false;
  bool loadingDays = false;
  bool loadingStudents = false;
  bool registering = false;

  @override
  void initState() {
    super.initState();
    loadTokenAndData();
  }

  Future<void> loadTokenAndData() async {
    final savedToken = await storage.read(key: "auth_token");
    setState(() => token = savedToken ?? widget.token);
  }

  Future<void> _loadSchedulesByYear() async {
    final selectedYearId = yearIdController.text.trim();
    if (selectedYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione primero un año")),
      );
      return;
    }

    setState(() {
      loadingSchedules = true;
      schedules = [];
      selectedScheduleId = null;
    });

    final url = Uri.parse(
      "http://localhost:3000/api/schedules/by-user/${widget.teacherId}/year/$selectedYearId",
    );

    final res = await http.get(
      url,
      headers: {
        "Authorization": "Bearer ${token ?? widget.token}",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() => schedules = data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando horarios: ${res.body}")),
      );
    }

    setState(() => loadingSchedules = false);
  }

  Future<void> _loadStudentsBySchedule() async {
    if (selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione primero un horario.")),
      );
      return;
    }

    setState(() {
      loadingStudents = true;
      students = [];
      selectedStudentId = null;
    });

    final url = Uri.parse("http://localhost:3000/api/studentEnrollments/bySchedule/$selectedScheduleId");

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => students = data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error cargando estudiantes: ${res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar: $e")),
      );
    } finally {
      setState(() => loadingStudents = false);
    }
  }

  Future<void> _registerIncident() async {
    if (selectedScheduleId == null || selectedStudentId == null || selectedSchoolDayId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete todos los campos antes de registrar.")),
      );
      return;
    }

    final url = Uri.parse("http://localhost:3000/api/incidents/create");
    final body = json.encode({
      "studentId": int.parse(selectedStudentId!),
      "scheduleId": int.parse(selectedScheduleId!),
      "schoolDayId": int.parse(selectedSchoolDayId!),
      "incidentDetail": incidentDetailController.text.trim(),
    });

    setState(() => registering = true);

    final res = await http.post(
      url,
      headers: {
        "Authorization": "Bearer ${token ?? widget.token}",
        "Content-Type": "application/json",
      },
      body: body,
    );

    setState(() => registering = false);

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incidencia registrada correctamente.")),
      );

      await _fetchIncidents();

      incidentDetailController.clear();
      selectedDayController.clear();
      selectedSchoolDayId = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar: ${res.body}")),
      );
    }
  }

  Future<void> _fetchIncidents() async {
    if (selectedStudentId == null || selectedScheduleId == null) {
      setState(() => incidents = []);
      return;
    }

    setState(() => loadingIncidents = true);

    final url = Uri.parse(
        "http://localhost:3000/api/incidents/byStudentAndSchedule/$selectedStudentId/$selectedScheduleId");

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => incidents = data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error cargando incidencias: ${res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con el servidor: $e")),
      );
    } finally {
      setState(() => loadingIncidents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadyToRegister = selectedScheduleId != null &&
        selectedStudentId != null &&
        selectedSchoolDayId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text("Incidencias - Docente ${widget.teacherId}", style: const TextStyle(fontSize: 15, color: Colors.white),),
        backgroundColor: appColors[3],
      ),
      body: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: materialTextSelectionControls,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SelectionField(
                      labelText: "Seleccionar Año Escolar",
                      displayController: yearDisplayController,
                      idController: yearIdController,
                      token: token,
                      onTap: () async {
                        await showYearsSelection(
                          context,
                          yearIdController,
                          yearDisplayController,
                          token: token,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _loadSchedulesByYear,
                    icon: const Icon(Icons.schedule, color: Colors.white,),
                    label: const Text("Cargar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors[3],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Horarios
              CustomInputContainer(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Horario",
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: const Icon(Icons.schedule),
                  ),
                  value: selectedScheduleId,
                  items: schedules.map<DropdownMenuItem<String>>((item) {
                    return DropdownMenuItem<String>(
                      value: item["id"].toString(),
                      child: Text(
                        "${item["weekday"]} - ${item["courses"]['course']} "
                            "(${item["startTime"]} - ${item["endTime"]}) / "
                            "${item["grades"]["grade"]} ${item["sections"]["seccion"]}",
                      ),
                    );
                  }).toList(),
                  onChanged: (val) async {
                    setState(() {
                      selectedScheduleId = val;
                    });
                    await _loadStudentsBySchedule();
                  },
                ),
              ),
              const SizedBox(height: 15),
              // Recargar días lectivos
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors[3],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                ),
                onPressed: () async {
                  if (selectedScheduleId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Seleccione primero un horario")),
                    );
                    return;
                  }
                  setState(() {
                    loadingDays = true;
                    schoolDays = [];
                    selectedSchoolDayId = null;
                  });
                  try {
                    final url = Uri.parse(
                        "http://localhost:3000/api/scheduleSDs/by-schedule/$selectedScheduleId");
                    final res = await http.get(url, headers: {
                      "Content-Type": "application/json",
                    });
                    if (res.statusCode == 200) {
                      final data = json.decode(res.body);
                      final days = data.map((d) => {
                        "scheduleSchoolDayId": d["id"],
                        "schoolDayId": d["schoolDays"]["id"],
                        "teachingDay": d["schoolDays"]["teachingDay"],
                        "weekday": d["schoolDays"]["weekday"],
                      }).toList();
                      setState(() {
                        schoolDays = days;
                        loadingDays = false;
                      });
                      if (schoolDays.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No se encontraron días lectivos.")),
                        );
                      } else {
                        // Seleccionar automáticamente el primer día lectivo
                        selectedSchoolDayId = schoolDays.first["schoolDayId"].toString();
                        selectedDateController.text =
                        "${schoolDays.first["teachingDay"]} (${schoolDays.first["weekday"]})";

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                              Text("Días lectivos cargados y primer día seleccionado.")),
                        );
                      }
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error al conectar: $e")),
                    );
                  } finally {
                    setState(() => loadingDays = false);
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("Recargar Días Lectivos del Año"),
              ),
              const SizedBox(height: 15),
              // Campo de día lectivo y calendario
              if (selectedDateController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: selectedDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: "Día Lectivo Seleccionado",
                            prefixIcon: Icon(Icons.date_range),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_calendar, color: Colors.teal),
                        onPressed: () async {
                          if (schoolDays.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Primero recargue los días lectivos del año.")),
                            );
                            return;
                          }
                          final selectedDay = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => SchoolDaysDialog(schoolDays: schoolDays),
                          );
                          if (selectedDay != null && selectedDay.isNotEmpty) {
                            setState(() {
                              selectedSchoolDayId = selectedDay["schoolDayId"].toString();
                              selectedDateController.text =
                              "${selectedDay["teachingDay"]} (${selectedDay["weekday"]})";
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              if (schoolDays.isNotEmpty)...[
                const SizedBox(width: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: appColors[3],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        height: 40,
                        alignment: Alignment.center,
                        child: const Text("Registrar Incidencia", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 15,),
                      CustomInputContainer(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Seleccionar Estudiante",
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: const Icon(Icons.person_search_outlined),
                          ),
                          value: selectedStudentId,
                          items: students.map<DropdownMenuItem<String>>((student) {
                            final person = student["persons"];
                            return DropdownMenuItem<String>(
                              value: student["id"].toString(),
                              child: Text("${person["names"]} ${person["lastNames"]}"),
                            );
                          }).toList(),
                          onChanged: (val) async {
                            setState(() => selectedStudentId = val);
                            await _fetchIncidents();
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      CustomInputContainer(
                        child: TextField(
                          controller: incidentDetailController,
                          decoration: const InputDecoration(
                            labelText: "Detalle de Incidencia",
                            prefixIcon: Icon(Icons.list),
                            border: InputBorder.none,
                          ),
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text("Guardar Incidencia", style: TextStyle(color: Colors.white, fontSize: 12),),
                          onPressed: () {
                            if (isReadyToRegister && !registering) {
                              _registerIncident();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Debe seleccionar el horario, estudiante y día lectivo antes de guardar."),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors[3],
                            foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 15),
              if (selectedStudentId != null)
                if (selectedStudentId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: loadingIncidents
                        ? const Center(child: CircularProgressIndicator())
                        : incidents.isEmpty
                        ? const Text("No hay incidencias registradas para este estudiante.")
                        : IncidentsTable(incidents: incidents),
                  ),
            ],
          ),
        ),
      )
    );
  }
}

class IncidentsTable extends StatelessWidget {
  final List incidents;

  const IncidentsTable({
    super.key,
    required this.incidents,
  });

  @override
  Widget build(BuildContext context) {
    final dataSource = _IncidentsDataSource(incidents: incidents);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomTitleWidget(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text("Incidencias Registradas", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white,),),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: PaginatedDataTable(
            columns: const [
              DataColumn(
                  label: Text("Estudiante",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text("Detalle",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text("Fecha",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text("Acción",
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            source: dataSource,
            rowsPerPage: 5,
            availableRowsPerPage: const [5],
            showCheckboxColumn: false,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('incidents', incidents));
  }
}

class _IncidentsDataSource extends DataTableSource {
  final List incidents;

  _IncidentsDataSource({required this.incidents});

  @override
  DataRow? getRow(int index) {
    if (index >= incidents.length) return null;

    final inc = incidents[index];
    final student = inc["students"]?["persons"];
    final fullName = student != null
        ? "${student["names"]} ${student["lastNames"]}"
        : "Desconocido";
    final date = inc["schooldays"]?["teachingDay"] ?? "—";
    final detail = inc["incidentDetail"] ?? "(Sin detalle)";

    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.all(
          index.isEven ? Colors.grey.shade50 : Colors.white),
      cells: [
        DataCell(Text(fullName)),
        DataCell(Text(detail)),
        DataCell(Text(date)),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.teal),
                tooltip: "Editar incidencia",
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                tooltip: "Eliminar incidencia",
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => incidents.length;

  @override
  int get selectedRowCount => 0;
}
