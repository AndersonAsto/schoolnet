import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:table_calendar/table_calendar.dart';

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

  Future<void> _showDaySelectionModal() async {
    final selectedYearId = yearIdController.text.trim();
    if (selectedYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione primero un año.")),
      );
      return;
    }

    setState(() => loadingDays = true);

    final url = Uri.parse("http://localhost:3000/api/schoolDays/byYear/$selectedYearId");
    final res = await http.get(url, headers: {"Content-Type": "application/json"});

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() => schoolDays = data);
    }

    setState(() => loadingDays = false);

    if (schoolDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay días lectivos para este año.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final firstDay = DateTime.parse(schoolDays.first["teachingDay"]);
        final year = firstDay.year;

        return AlertDialog(
          title: const Text("Seleccionar Día Lectivo"),
          content: SizedBox(
            height: 350,
            width: 350,
            child: TableCalendar(
              firstDay: DateTime(year, 1, 1),
              lastDay: DateTime(year, 12, 31),
              focusedDay: firstDay,
              calendarFormat: CalendarFormat.month,
              availableGestures: AvailableGestures.horizontalSwipe,
              enabledDayPredicate: (day) {
                final formatted = DateFormat('yyyy-MM-dd').format(day);
                return schoolDays.any((d) => d["teachingDay"].startsWith(formatted));
              },
              onDaySelected: (selectedDay, _) {
                final formatted = DateFormat('yyyy-MM-dd').format(selectedDay);
                final found = schoolDays.firstWhere(
                      (d) => d["teachingDay"].startsWith(formatted),
                  orElse: () => {},
                );
                if (found.isNotEmpty) {
                  setState(() {
                    selectedSchoolDayId = found["id"].toString();
                    selectedDayController.text = found["teachingDay"];
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ),
        );
      },
    );
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
        title: Text(
          "Incidencias - Docente ${widget.teacherId}",
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        backgroundColor: appColors[3],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SelectionField(
              hintText: "Seleccionar Año Escolar",
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
            const SizedBox(height: 20,),
            ElevatedButton.icon(
              onPressed: _loadSchedulesByYear,
              icon: const Icon(Icons.schedule),
              label: const Text("Cargar Horarios del Año"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            ),
            const SizedBox(height: 20),
            // Horarios
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Horario"),
              value: selectedScheduleId,
              items: schedules.map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem<String>(
                  value: item["id"].toString(),
                  child: Text("${item["courses"]["course"]} - ${item["grades"]["grade"]}${item["sections"]["seccion"]}"),
                );
              }).toList(),
              onChanged: (val) async {
                setState(() {
                  selectedScheduleId = val;
                });
                await _loadStudentsBySchedule();
              },
            ),
            const SizedBox(height: 20,),
            if (students.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Seleccionar Estudiante"),
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
            const SizedBox(height: 20),
            // Día lectivo
            TextField(
              controller: selectedDayController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Día Lectivo Seleccionado",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _showDaySelectionModal,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Detalle
            TextField(
              controller: incidentDetailController,
              decoration: const InputDecoration(
                labelText: "Detalle de la incidencia",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: registering
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Registrar Incidencia"),
              onPressed: isReadyToRegister && !registering ? _registerIncident : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors[3],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📋 Incidencias Registradas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (loadingIncidents)
                    const Center(child: CircularProgressIndicator())
                  else if (incidents.isEmpty)
                    const Text("No hay incidencias registradas para este estudiante.")
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Alumno")),
                          DataColumn(label: Text("Detalle")),
                          DataColumn(label: Text("Fecha")),
                        ],
                        rows: incidents.map<DataRow>((inc) {
                          final student = inc["students"]?["persons"];
                          final fullName = student != null
                              ? "${student["names"]} ${student["lastNames"]}"
                              : "Desconocido";
                          final date = inc["schooldays"]?["teachingDay"] ?? "—";
                          final detail = inc["incidentDetail"] ?? "(Sin detalle)";
                          return DataRow(cells: [
                            DataCell(Text(fullName)),
                            DataCell(Text(detail)),
                            DataCell(Text(date)),
                          ]);
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
