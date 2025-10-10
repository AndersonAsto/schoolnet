import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';

class TeachingBlockAveragesScreen extends StatefulWidget {
  final int teacherId;
  final String token;

  const TeachingBlockAveragesScreen({
    super.key,
    required this.teacherId,
    required this.token
  });

  @override
  State<TeachingBlockAveragesScreen> createState() => _TeachingBlockAveragesScreenState();
}

class _TeachingBlockAveragesScreenState extends State<TeachingBlockAveragesScreen> {
  TextEditingController yearIdController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();
  TextEditingController gradeAverageController = TextEditingController();
  TextEditingController examAverageController = TextEditingController();
  TextEditingController teachingBlockAverage = TextEditingController();

  String? selectedExamType;
  String? selectedStudentId;

  String? token;
  List schedules = [];
  List schoolDays = [];
  List studentExams = [];
  bool loadingExams = false;
  String? selectedScheduleId;
  String? selectedSchoolDayId;

  bool loadingSchedules = false;
  bool loadingDays = false;
  List teachingBlocks = [];
  List students = [];

  String? selectedTeachingBlockId;
  bool loadingBlocks = false;
  bool loadingStudents = false;

  bool loadingTeachingBlocks = false;

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

  Future<void> _loadYearData() async {
    final selectedYearId = yearIdController.text.trim();
    if (selectedYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione primero un año")),
      );
      return;
    }

    setState(() {
      loadingSchedules = true;
      loadingTeachingBlocks = true;
      schedules = [];
      teachingBlocks = [];
      selectedScheduleId = null;
      selectedTeachingBlockId = null;
    });

    try {
      // Peticiones en paralelo (más eficiente que hacerlas por separado)
      final responses = await Future.wait([
        http.get(
          Uri.parse("http://localhost:3000/api/schedules/by-user/${widget.teacherId}/year/$selectedYearId"),
          headers: {
            "Authorization": "Bearer ${token ?? widget.token}",
            "Content-Type": "application/json",
          },
        ),
        http.get(
          Uri.parse("http://localhost:3000/api/teachingBlocks/byYear/$selectedYearId"),
          headers: {
            "Authorization": "Bearer ${token ?? widget.token}",
            "Content-Type": "application/json",
          },
        ),
      ]);

      final resSchedules = responses[0];
      final resBlocks = responses[1];

      if (resSchedules.statusCode == 200 && resBlocks.statusCode == 200) {
        final dataSchedules = json.decode(resSchedules.body);
        final dataBlocks = json.decode(resBlocks.body);

        setState(() {
          schedules = dataSchedules;
          teachingBlocks = dataBlocks;
        });

        if (dataSchedules.isEmpty && dataBlocks.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No se encontraron datos para este año.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Horarios y bloques cargados correctamente.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar datos: ${resSchedules.body} / ${resBlocks.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con el servidor: $e")),
      );
    } finally {
      setState(() {
        loadingSchedules = false;
        loadingTeachingBlocks = false;
      });
    }
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
    });

    final url = Uri.parse("http://localhost:3000/api/studentEnrollments/bySchedule/$selectedScheduleId");

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
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No hay estudiantes en este horario.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando estudiantes: ${res.body}")),
      );
    }

    setState(() => loadingStudents = false);
  }

  Future<void> _loadExamsByStudent() async {
    if (selectedStudentId == null) return;

    setState(() {
      loadingExams = true;
      studentExams = [];
    });

    final url = Uri.parse("http://localhost:3000/api/exams/student/$selectedStudentId");

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data.containsKey('exams')) {
          setState(() => studentExams = data['exams']);
        } else {
          setState(() => studentExams = data);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al obtener exámenes: ${res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    }

    setState(() => loadingExams = false);
  }

  Future<void> _showStudentDailyRecordsModal() async {
    if (selectedStudentId == null || selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione un estudiante y un horario.")),
      );
      return;
    }

    // 🔹 Primero: cargar datos antes de abrir el modal
    List qualifications = [];
    List assistances = [];
    List<Map<String, dynamic>> combinedRecords = [];

    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse("http://localhost:3000/api/qualifications/byStudent/$selectedStudentId/schedule/$selectedScheduleId"),
          headers: {
            "Authorization": "Bearer ${token ?? widget.token}",
            "Content-Type": "application/json",
          },
        ),
        http.get(
          Uri.parse("http://localhost:3000/api/assistances/byStudent/$selectedStudentId/schedule/$selectedScheduleId"),
          headers: {
            "Authorization": "Bearer ${token ?? widget.token}",
            "Content-Type": "application/json",
          },
        ),
      ]);

      if (responses[0].statusCode == 200) {
        qualifications = jsonDecode(responses[0].body);
      }
      if (responses[1].statusCode == 200) {
        assistances = jsonDecode(responses[1].body);
      }

      final allDays = {
        ...qualifications.map((q) => q["schoolDayId"]),
        ...assistances.map((a) => a["schoolDayId"]),
      };

      combinedRecords = allDays.map((dayId) {
        final qual = qualifications.firstWhere(
              (q) => q["schoolDayId"] == dayId,
          orElse: () => {},
        );
        final asis = assistances.firstWhere(
              (a) => a["schoolDayId"] == dayId,
          orElse: () => {},
        );

        return {
          "fecha": asis["schooldays"]?["teachingDay"] ??
              qual["schooldays"]?["teachingDay"] ??
              "—",
          "asistencia": asis["assistance"] ?? "—",
          // 🔹 CAMBIO AQUÍ: usamos 'rating' en lugar de 'score'
          "calificacion": qual["rating"]?.toString() ?? "—",
        };
      }).toList();

      combinedRecords.sort((a, b) => a["fecha"].compareTo(b["fecha"]));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al obtener registros: $e")),
      );
      return;
    }

    // 🔹 Luego: abrir el modal (ya con datos cargados)
    showDialog(
      context: context,
      builder: (ctx) {
        int currentPage = 0;
        const int rowsPerPage = 25;

        return AlertDialog(
          title: const Text("Registros diarios del estudiante"),
          content: SizedBox(
            width: double.maxFinite,
            child: combinedRecords.isEmpty
                ? const Text("No se encontraron registros.")
                : StatefulBuilder(
              builder: (ctx, setState) {
                final start = currentPage * rowsPerPage;
                final end = (start + rowsPerPage > combinedRecords.length)
                    ? combinedRecords.length
                    : start + rowsPerPage;
                final pageData = combinedRecords.sublist(start, end);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text("Fecha")),
                            DataColumn(label: Text("Asistencia")),
                            DataColumn(label: Text("Calificación")),
                          ],
                          rows: pageData.map((record) {
                            return DataRow(cells: [
                              DataCell(Text(record["fecha"].toString())),
                              DataCell(Text(record["asistencia"].toString())),
                              DataCell(Text(record["calificacion"].toString())),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: currentPage > 0
                              ? () => setState(() => currentPage--)
                              : null,
                        ),
                        Text(
                          "Página ${currentPage + 1} de ${(combinedRecords.length / rowsPerPage).ceil()}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: end < combinedRecords.length
                              ? () => setState(() => currentPage++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateTeachingBlockAverage() async {
    if (selectedStudentId == null || selectedScheduleId == null || selectedTeachingBlockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione estudiante, horario y bloque lectivo.")),
      );
      return;
    }

    final url = Uri.parse("http://localhost:3000/api/teachingblockaverage/calculate");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "studentId": int.parse(selectedStudentId!),
          "scheduleId": int.parse(selectedScheduleId!),
          "teachingBlockId": int.parse(selectedTeachingBlockId!),
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final record = data["data"];

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("✅ Promedio generado"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Mensaje: ${data["message"]}"),
                const SizedBox(height: 10),
                Text("Promedio de prácticas: ${record["gradeAvarage"] ?? "—"}"),
                Text("Promedio de exámenes: ${record["examAvarage"] ?? "—"}"),
                Text("Promedio final de bloque: ${record["teachingblockavarage"] ?? "—"}"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        );
      } else {
        final error = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${error["message"] ?? res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Calificación de Bloque Lectivo - Docente ${widget.teacherId}",
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
            ElevatedButton.icon(
              onPressed: _loadYearData,
              icon: const Icon(Icons.refresh),
              label: const Text("Cargar Horarios y Bloques del Año"),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors[3],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: loadingBlocks
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Bloque lectivo"),
                value: selectedTeachingBlockId,
                items: teachingBlocks.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item["id"].toString(),
                    child: Text(item["blockName"] ?? "Bloque ${item["id"]}"),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedTeachingBlockId = val),
              ),
            ),
            const SizedBox(height: 10,),

            ElevatedButton.icon(
              onPressed: _loadStudentsBySchedule,
              icon: const Icon(Icons.people),
              label: const Text("Cargar Estudiantes"),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors[3],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10,),
            if (selectedTeachingBlockId != null && students.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text(
                      "Registrar Calificación de Examen o Práctica",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Seleccionar estudiante
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
                      onChanged: (val) {
                        setState(() => selectedStudentId = val);
                        _loadExamsByStudent();
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _generateTeachingBlockAverage,
                      icon: const Icon(Icons.calculate),
                      label: const Text("Generar promedio"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),

                    Divider(),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (selectedScheduleId != null && selectedStudentId != null) {
                          _showStudentDailyRecordsModal();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Seleccione horario, día escolar y estudiante.")),
                          );
                        }
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text("Ver calificación diaria"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const Text(
                      "Registros del Alumno",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (loadingExams)
                      const Center(child: CircularProgressIndicator())
                    else if (studentExams.isEmpty)
                      const Text("Sin registros de exámenes.")
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text("Bloque")),
                            DataColumn(label: Text("Tipo")),
                            DataColumn(label: Text("Puntaje")),
                            DataColumn(label: Text("Máximo")),
                          ],
                          rows: studentExams.map<DataRow>((exam) {
                            final block = exam["teachingblocks"]?["teachingBlock"] ?? "—";
                            final type = exam["type"] ?? "—";
                            final score = exam["score"].toString();
                            final maxScore = exam["maxScore"].toString();
                            return DataRow(cells: [
                              DataCell(Text(block)),
                              DataCell(Text(type)),
                              DataCell(Text(score)),
                              DataCell(Text(maxScore)),
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
