import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'dart:convert';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:table_calendar/table_calendar.dart';

class QualificationsScreen extends StatefulWidget {
  final int teacherId;
  final String token;

  const QualificationsScreen({
    super.key,
    required this.teacherId,
    required this.token,
  });

  @override
  State<QualificationsScreen> createState() => _QualificationsScreenState();
}

class _QualificationsScreenState extends State<QualificationsScreen> {
  TextEditingController yearIdController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();

  List schedules = [];
  List schoolDays = [];

  String? selectedScheduleId;
  String? selectedSchoolDayId;
  String? token;

  bool loadingSchedules = false;
  bool loadingDays = false;

  @override
  void initState() {
    super.initState();
    loadTokenAndData();
  }

  Future<void> loadTokenAndData() async {
    final savedToken = await storage.read(key: "auth_token");
    if (savedToken != null) {
      setState(() => token = savedToken);
    } else {
      token = widget.token;
    }
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
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se encontraron horarios para este año.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando horarios: ${res.body}")),
      );
    }

    setState(() => loadingSchedules = false);
  }

  Future<void> _openQualificationsDialog() async {
    if (selectedScheduleId == null || selectedSchoolDayId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione horario y día lectivo")),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return QualificationsDialog(
          scheduleId: selectedScheduleId!,
          schoolDayId: selectedSchoolDayId!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificaciones', style: TextStyle(fontSize: 15, color: Colors.white)),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Selección de Año Escolar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectionField(
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
            ),

            // 🔹 Botón para cargar horarios
            ElevatedButton.icon(
              onPressed: _loadSchedulesByYear,
              icon: const Icon(Icons.schedule),
              label: const Text("Cargar Horarios del Año"),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors[3],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            // 🔹 Dropdown de horarios
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: loadingSchedules
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Horario"),
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
                onChanged: (val) => setState(() => selectedScheduleId = val),
              ),
            ),
            const SizedBox(height: 15),

            // 🔹 Botón para cargar días lectivos
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors[3],
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final selectedYearId = yearIdController.text.trim();

                  if (selectedYearId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Seleccione primero un año")),
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
                      "http://localhost:3000/api/schoolDays/byYear/$selectedYearId",
                    );
                    final res = await http.get(url, headers: {
                      "Content-Type": "application/json",
                    });

                    if (res.statusCode == 200) {
                      final data = json.decode(res.body);
                      setState(() => schoolDays = data);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error al conectar: $e")),
                    );
                  } finally {
                    setState(() => loadingDays = false);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text("Cargar Días Lectivos del Año"),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Calendario
            if (loadingDays)
              const CircularProgressIndicator()
            else if (schoolDays.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Builder(
                  builder: (context) {
                    final year = int.parse(
                      schoolDays.first["teachingDay"].toString().substring(0, 4),
                    );
                    final firstDay = DateTime(year, 1, 1);
                    final lastDay = DateTime(year, 12, 31);
                    final focusedDay = DateTime.parse(schoolDays.first["teachingDay"]);

                    return TableCalendar(
                      firstDay: firstDay,
                      lastDay: lastDay,
                      focusedDay: focusedDay.isBefore(lastDay) ? focusedDay : lastDay,
                      calendarFormat: CalendarFormat.month,
                      availableGestures: AvailableGestures.horizontalSwipe,
                      onFormatChanged: (_) {},
                      enabledDayPredicate: (day) {
                        final formatted = DateFormat('yyyy-MM-dd').format(day);
                        return schoolDays.any(
                              (d) => d["teachingDay"].toString().startsWith(formatted),
                        );
                      },
                      onDaySelected: (selectedDay, _) {
                        final formatted = DateFormat('yyyy-MM-dd').format(selectedDay);
                        final found = schoolDays.firstWhere(
                              (d) => d["teachingDay"].toString().startsWith(formatted),
                          orElse: () => {},
                        );

                        if (found.isNotEmpty) {
                          setState(() => selectedSchoolDayId = found["id"].toString());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Día seleccionado: ${found["teachingDay"]}")),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            // 🔹 Botón para abrir diálogo de calificaciones
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appColors[3]),
              onPressed: _openQualificationsDialog,
              child: const Text("Cargar Calificaciones",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class QualificationsDialog extends StatefulWidget {
  final String scheduleId;
  final String schoolDayId;

  const QualificationsDialog({
    super.key,
    required this.scheduleId,
    required this.schoolDayId,
  });

  @override
  State<QualificationsDialog> createState() => _QualificationsDialogState();
}

class _QualificationsDialogState extends State<QualificationsDialog> {
  List<Map<String, dynamic>> students = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadStudentsAndQualifications();
  }

  Future<void> _loadStudentsAndQualifications() async {
    setState(() => loading = true);

    try {
      // 1️⃣ Obtener alumnos inscritos para el horario
      final studentsRes = await http.get(
        Uri.parse("http://localhost:3000/api/studentEnrollments/bySchedule/${widget.scheduleId}"),
      );

      // 2️⃣ Obtener asistencias del día para mostrar estado
      final assistancesRes = await http.get(
        Uri.parse(
          "http://localhost:3000/api/assistances/byScheduleAndDay?scheduleId=${widget.scheduleId}&schoolDayId=${widget.schoolDayId}",
        ),
      );

      // 3️⃣ Obtener calificaciones existentes
      final qualificationsRes = await http.get(
        Uri.parse(
          "http://localhost:3000/api/qualifications/byScheduleAndDay?scheduleId=${widget.scheduleId}&schoolDayId=${widget.schoolDayId}",
        ),
      );

      if (studentsRes.statusCode == 200 &&
          assistancesRes.statusCode == 200 &&
          qualificationsRes.statusCode == 200) {
        final enrollments = json.decode(studentsRes.body);
        final assistances = json.decode(assistancesRes.body) as List;
        final qualifications = json.decode(qualificationsRes.body) as List;

        students = enrollments.map<Map<String, dynamic>>((e) {
          final attendance = assistances.firstWhere(
                (a) => a["studentId"] == e["id"],
            orElse: () => null,
          );
          final qualification = qualifications.firstWhere(
                (q) => q["studentId"] == e["id"],
            orElse: () => null,
          );

          return {
            "id": qualification?["id"], // null si no existe
            "studentId": e["id"],
            "name": "${e["persons"]["names"]} ${e["persons"]["lastNames"]}",
            "assistance": attendance?["assistance"] ?? "P",
            "rating": qualification?["rating"]?.toString() ?? "", // String para TextField
            "ratingDetail": qualification?["ratingDetail"] ?? "",
          };
        }).toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: $e")),
      );
    }

    setState(() => loading = false);
  }

  void _setRating(int index, String value) {
    setState(() {
      students[index]["rating"] = value;
    });
  }

  Future<void> _saveQualifications() async {
    final nuevos = students.where((s) => s["id"] == null).map((s) {
      return {
        "studentId": s["studentId"],
        "scheduleId": int.parse(widget.scheduleId),
        "schoolDayId": int.parse(widget.schoolDayId),
        "rating": s["rating"].isEmpty ? 0 : double.parse(s["rating"]),
        "ratingDetail": s["ratingDetail"] ?? "",
        "status": true,
      };
    }).toList();

    final existentes = students.where((s) => s["id"] != null).map((s) {
      return {
        "id": s["id"],
        "studentId": s["studentId"],
        "scheduleId": int.parse(widget.scheduleId),
        "schoolDayId": int.parse(widget.schoolDayId),
        "rating": s["rating"].isEmpty ? 0 : double.parse(s["rating"]),
        "ratingDetail": s["ratingDetail"] ?? "",
      };
    }).toList();

    try {
      if (nuevos.isNotEmpty) {
        final resCreate = await http.post(
          Uri.parse("http://localhost:3000/api/qualifications/bulkCreate"),
          headers: {"Content-Type": "application/json"},
          body: json.encode(nuevos),
        );
        if (resCreate.statusCode != 200 && resCreate.statusCode != 201) {
          throw Exception("Error en creación: ${resCreate.body}");
        }
      }

      if (existentes.isNotEmpty) {
        final resUpdate = await http.put(
          Uri.parse("http://localhost:3000/api/qualifications/bulkUpdate"),
          headers: {"Content-Type": "application/json"},
          body: json.encode(existentes),
        );
        if (resUpdate.statusCode != 200) {
          throw Exception("Error en actualización: ${resUpdate.body}");
        }
      }

      Navigator.pop(context); // Cerrar diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Calificaciones guardadas/actualizadas correctamente")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: const Text("Registrar Calificaciones"),
      content: SizedBox(
        width: screenWidth * 0.6,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          shrinkWrap: true,
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return ListTile(
              title: Text(student["name"]),
              subtitle: Row(
                children: [
                  // Estado de asistencia (solo lectura)
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(student["assistance"]),
                  ),
                  const SizedBox(width: 10),
                  // Campo de calificación editable
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "Nota",
                      ),
                      controller: TextEditingController(text: student["rating"]),
                      onChanged: (val) => _setRating(index, val),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _saveQualifications,
          style: ElevatedButton.styleFrom(backgroundColor: appColors[3]),
          child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
