import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/screens/teacherScreens/assistancesScreen.dart';
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
  TextEditingController selectedDateController = TextEditingController();

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
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selección y carga de año escolar
              Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _loadSchedulesByYear,
                    icon: const Icon(Icons.schedule, color: Colors.white),
                    label: const Text("Cargar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors[3],
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Selección de horarios
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: loadingSchedules
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Horario",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
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
                  onChanged: (val) => setState(() => selectedScheduleId = val),
                ),
              ),
              const SizedBox(height: 15),
              // Recargar días lectivos
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors[3],
                  foregroundColor: Colors.white,
                  shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      setState(() {
                        schoolDays = data
                            .map((d) => {
                          "scheduleSchoolDayId": d["id"],
                          "schoolDayId": d["schoolDays"]["id"],
                          "teachingDay": d["schoolDays"]["teachingDay"],
                          "weekday": d["schoolDays"]["weekday"],
                        })
                            .toList();
                      });
                      if (schoolDays.isNotEmpty) {
                        selectedSchoolDayId =
                            schoolDays.first["schoolDayId"].toString();
                        selectedDateController.text =
                        "${schoolDays.first["teachingDay"]} (${schoolDays.first["weekday"]})";
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("No se encontraron días lectivos.")),
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
              const SizedBox(height: 15),
              // Abrir registro de calificaciones
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors[3],
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _openQualificationsDialog,
                  icon: const Icon(Icons.checklist, color: Colors.white),
                  label: const Text(
                    "Cargar Calificaciones",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
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
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: appColors[3]),
              const SizedBox(width: 8),
              const Text(
                "Registro de Calificaciones",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ]
          ),
          const Divider(),
        ],
      ),
      content: SizedBox(
        width: screenWidth * 0.6,
        height: 420,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.indigo.shade50),
            dataRowHeight: 48,
            horizontalMargin: 12,
            columnSpacing: 10,
            columns: const [
              DataColumn(label: Text("N°", textAlign: TextAlign.center)),
              DataColumn(label: Text("Estudiante", textAlign: TextAlign.center)),
              DataColumn(label: Text("Asistencia", textAlign: TextAlign.center)),
              DataColumn(label: Text("Nota", textAlign: TextAlign.center)),
            ],
            rows: List.generate(students.length, (index) {
              final student = students[index];

              return DataRow(
                cells: [
                  DataCell(Text("${index + 1}")),
                  DataCell(Text(student["name"])),
                  DataCell(Text(student["assistance"] ?? "P")),
                  DataCell(
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: student["rating"] ?? "",
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                          EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          hintText: "0–20",
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            _setRating(index, "");
                            return;
                          }

                          final number = int.tryParse(value);
                          if (number != null && number >= 0 && number <= 20) {
                            _setRating(index, number.toString());
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly, // ✅ solo enteros
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancelar", style: TextStyle(color: appColors[3])),
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
