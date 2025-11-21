import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/screens/teacherScreens/overallCourseAverageScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/customTextFields.dart';

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
  String? assignmentId;
  String? selectedSchoolDayId;
  String? selectedTeachingBlockId;

  List teachingBlocks = [];
  List students = [];
  List schedules = [];
  List schoolDays = [];
  List studentExams = [];

  bool loadingExams = false;
  bool loadingSchedules = false;
  bool loadingDays = false;
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
      assignmentId = null;
      selectedTeachingBlockId = null;
    });

    try {
      // Peticiones en paralelo (más eficiente que hacerlas por separado)
      final responses = await Future.wait([
        http.get(
          Uri.parse("http://localhost:3000/api/teacherGroups/by-user/${widget.teacherId}/by-year/$selectedYearId"),
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
    if (assignmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione primero un horario.")),
      );
      return;
    }

    setState(() {
      loadingStudents = true;
      students = [];
    });

    final url = Uri.parse("http://localhost:3000/api/studentEnrollments/by-group/$assignmentId");

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

    final url = Uri.parse("http://localhost:3000/api/exams/student/$selectedStudentId/group/$assignmentId");

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

  Future<void> _generateTeachingBlockAverage() async {
    if (selectedStudentId == null || assignmentId == null || selectedTeachingBlockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione estudiante, horario y bloque lectivo.")),
      );
      return;
    }

    final previewUrl = Uri.parse("http://localhost:3000/api/teachingblockaverage/preview");

    try {
      final res = await http.post(
        previewUrl,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "studentId": int.parse(selectedStudentId!),
          "assignmentId": int.parse(assignmentId!),
          "teachingBlockId": int.parse(selectedTeachingBlockId!),
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final record = data["data"];

        // Mostrar el modal de confirmación con los resultados calculados
        showDialog(
          context: context,
          builder: (ctx) => TeachingBlockConfirmDialog(
            record: record,
            onConfirm: () async {
              await _saveTeachingBlockAverage(record);
            },
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

  Future<void> _saveTeachingBlockAverage(Map<String, dynamic> record) async {
    final saveUrl = Uri.parse("http://localhost:3000/api/teachingblockaverage/calculate");

    try {
      final res = await http.post(
        saveUrl,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "studentId": int.parse(selectedStudentId!),
          "assignmentId": int.parse(assignmentId!),
          "teachingBlockId": int.parse(selectedTeachingBlockId!),
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Promedio guardado correctamente.")),
        );
      } else {
        final error = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: ${error["message"] ?? res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con el servidor: $e")),
      );
    }
  }

  Future<void> _showStudentDailyRecordsModal() async {
    if (selectedStudentId == null || assignmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione un estudiante y un horario.")),
      );
      return;
    }

    List qualifications = [];
    List assistances = [];
    List<Map<String, dynamic>> combinedRecords = [];

    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse(
              "http://localhost:3000/api/qualifications/by-group/$assignmentId/student/$selectedStudentId"),
          headers: {
            "Authorization": "Bearer ${token ?? widget.token}",
            "Content-Type": "application/json",
          },
        ),
        http.get(
          Uri.parse(
              "http://localhost:3000/api/assistances/by-group/$assignmentId/student/$selectedStudentId"),
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

    showDialog(
      context: context,
      builder: (_) => StudentDailyRecordsDialog(records: combinedRecords),
    );
  }

  Future<void> _showStudentExamsModal() async {
    if (studentExams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay registros de evaluaciones para este estudiante.")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => StudentExamsDialog(exams: studentExams.cast<Map<String, dynamic>>()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Promedios de Bloque Lectivo - Docente ${widget.teacherId}", style: const TextStyle(fontSize: 15, color: Colors.white),),
        automaticallyImplyLeading: false,
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
              // Seleccionar año lectivo, cargar grupos y bloque lectivos
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
                    onPressed: _loadYearData,
                    icon: const Icon(Icons.refresh, color: Colors.white,),
                    label: const Text("Cargar Grupos y Bloques del Año"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors[3],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Seleccionar grupo docente
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: loadingSchedules
                    ? const CircularProgressIndicator()
                    : CustomInputContainer(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Grupo Docente",
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.groups),
                      ),
                      value: assignmentId,
                      items: schedules.map<DropdownMenuItem<String>>((item) {
                        final course = item["courses"]?["course"] ?? "Sin curso";
                        final grade = item["grades"]?["grade"] ?? "—";
                        final section = item["sections"]?["seccion"] ?? "—";
                        return DropdownMenuItem<String>(
                          value: item["id"].toString(),
                          child: Text("$course - $grade $section"),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => assignmentId = val),
                    ),
                ),
              ),
              const SizedBox(height: 15),
              // Seleccionar bloque lectivo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: loadingBlocks
                    ? const CircularProgressIndicator()
                    : CustomInputContainer(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Bloque Lectivo",
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.schedule),
                      ),
                      value: selectedTeachingBlockId,
                      items: teachingBlocks.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item["id"].toString(),
                          child: Text(item["teachingBlock"] ?? "Bloque ${item["id"]}"),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedTeachingBlockId = val),
                    ),
                ),
              ),
              const SizedBox(height: 15),
              // Cargar estudiantes
              ElevatedButton.icon(
                onPressed: _loadStudentsBySchedule,
                icon: const Icon(Icons.people, color: Colors.white,),
                label: const Text("Cargar Estudiantes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors[3],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Seleccionar estudiante, generar promedios y ver calificaciones
              if (selectedTeachingBlockId != null && students.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seleccionar estudiante
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
                          onChanged: (val) {
                            setState(() => selectedStudentId = val);
                            _loadExamsByStudent();
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Generar/actualizar promedio
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _generateTeachingBlockAverage,
                          icon: const Icon(Icons.calculate, color: Colors.white,),
                          label: const Text("Generar Promedio", style: TextStyle(color: Colors.white, fontSize: 12),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors[3],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Ver calificación diaria
                      ElevatedButton.icon(
                        onPressed: () {
                          if (assignmentId != null && selectedStudentId != null) {
                            _showStudentDailyRecordsModal();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Seleccione horario, día escolar y estudiante.")),
                            );
                          }
                        },
                        icon: const Icon(Icons.visibility, color: Colors.white,),
                        label: const Text("Ver Calificación Diaria", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors[9],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Ver calificación de evaluciones
                      ElevatedButton.icon(
                        onPressed: () {
                          if (selectedStudentId != null) {
                            _showStudentExamsModal();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Seleccione un estudiante para ver sus evaluaciones.")),
                            );
                          }
                        },
                        icon: const Icon(Icons.visibility, color: Colors.white),
                        label: const Text("Ver Calificación de Evaluaciones", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors[9],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Ver promedios por bloques lectivos del curso
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (selectedStudentId == null || assignmentId == null || yearIdController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Debe seleccionar año, horario y estudiante.")),
                            );
                            return;
                          }

                          final url = Uri.parse(
                              "http://localhost:3000/api/teachingblockaverage/byStudent/$selectedStudentId/year/${yearIdController.text}/assignment/$assignmentId"
                          );
                          final res = await http.get(url, headers: {
                            "Authorization": "Bearer ${token ?? widget.token}",
                            "Content-Type": "application/json",
                          });

                          if (res.statusCode == 200) {
                            final data = json.decode(res.body);
                            showDialog(
                              context: context,
                              builder: (_) => StudentBlockAveragesDialog(
                                blockAverages: List<Map<String, dynamic>>.from(data),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error al obtener promedios: ${res.body}")),
                            );
                          }
                        },
                        icon: const Icon(Icons.bar_chart, color: Colors.white,),
                        label: const Text("Ver Promedios por Bloques Lectivos del Curso"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors[9],
                          foregroundColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeachingBlockConfirmDialog extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onConfirm;

  const TeachingBlockConfirmDialog({
    super.key,
    required this.record,
    required this.onConfirm,
  });

  Color _getNoteColor(double? note) {
    if (note == null) return Colors.black87;
    return note >= 11 ? Colors.green[700]! : Colors.red[700]!;
  }

  Color _getNoteBackground(double? note) {
    if (note == null) return Colors.transparent;
    return note >= 11
        ? Colors.green.withOpacity(0.08)
        : Colors.red.withOpacity(0.08);
  }

  @override
  Widget build(BuildContext context) {
    final daily = double.tryParse(record["dailyAvarage"]?.toString() ?? "");
    final practices = double.tryParse(record["practiceAvarage"]?.toString() ?? "");
    final exams = double.tryParse(record["examAvarage"]?.toString() ?? "");
    final total = double.tryParse(record["teachingBlockAvarage"]?.toString() ?? "");

    return AlertDialog(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: appColors[3]),
              const SizedBox(width: 8),
              const Text(
                "Confirmar Promedio del Bloque",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
      content: Container(
        width: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade50,
        ),
        child: DataTable(
          headingRowColor:
          MaterialStateProperty.all(Colors.green.shade50),
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text("Concepto", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Valor", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: [
            DataRow(cells: [
              const DataCell(Text("Promedio diario")),
              DataCell(Container(
                color: _getNoteBackground(daily),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  daily != null ? daily.toStringAsFixed(2) : "—",
                  style: TextStyle(color: _getNoteColor(daily)),
                ),
              )),
            ]),
            DataRow(cells: [
              const DataCell(Text("Promedio de prácticas")),
              DataCell(Container(
                color: _getNoteBackground(practices),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  practices != null ? practices.toStringAsFixed(2) : "—",
                  style: TextStyle(color: _getNoteColor(practices)),
                ),
              )),
            ]),
            DataRow(cells: [
              const DataCell(Text("Promedio de exámenes")),
              DataCell(Container(
                color: _getNoteBackground(exams),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  exams != null ? exams.toStringAsFixed(2) : "—",
                  style: TextStyle(color: _getNoteColor(exams)),
                ),
              )),
            ]),
            DataRow(cells: [
              const DataCell(Text("Promedio final de bloque")),
              DataCell(Container(
                color: _getNoteBackground(total),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  total != null ? total.toStringAsFixed(2) : "—",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getNoteColor(total),
                  ),
                ),
              )),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          icon: const Icon(Icons.check, color: Colors.white,),
          label: const Text("Confirmar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: appColors[3],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

class StudentDailyRecordsDialog extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const StudentDailyRecordsDialog({super.key, required this.records});

  Color _getNoteColor(double? note) {
    if (note == null) return Colors.black87;
    return note >= 11 ? Colors.green[700]! : Colors.red[700]!;
  }

  Color _getNoteBackground(double? note) {
    if (note == null) return Colors.transparent;
    return note >= 11
        ? Colors.green.withOpacity(0.08)
        : Colors.red.withOpacity(0.08);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: appColors[3]),
              const SizedBox(width: 8),
              const Text(
                "Registros Diarios del Estudiante",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
      content: Container(
        width: 700,
        child: records.isEmpty
            ? const Padding(
          padding: EdgeInsets.all(15),
          child: Text("No se encontraron registros."),
        )
            : SingleChildScrollView(
          child: DataTable(
            headingRowColor:
            MaterialStateProperty.all(Colors.indigo.shade50),
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text("Fecha")),
              DataColumn(label: Text("Asistencia")),
              DataColumn(label: Text("Calificación")),
            ],
            rows: records.map((r) {
              final asistencia = r["asistencia"] ?? "—";
              final calificacionStr = r["calificacion"]?.toString();
              final calificacion = double.tryParse(calificacionStr ?? "");

              return DataRow(cells: [
                DataCell(Text(r["fecha"] ?? "—")),
                DataCell(Text(asistencia)),
                DataCell(Container(
                  color: _getNoteBackground(calificacion),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    calificacion != null
                        ? calificacion.toStringAsFixed(2)
                        : "—",
                    style: TextStyle(
                      color: _getNoteColor(calificacion),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),
      ],
    );
  }
}

class StudentExamsDialog extends StatelessWidget {
  final List<Map<String, dynamic>> exams;

  const StudentExamsDialog({super.key, required this.exams});

  Color _getNoteColor(double? note) {
    if (note == null) return Colors.black87;
    return note >= 11 ? Colors.green[700]! : Colors.red[700]!;
  }

  Color _getNoteBackground(double? note) {
    if (note == null) return Colors.transparent;
    return note >= 11
        ? Colors.green.withOpacity(0.08)
        : Colors.red.withOpacity(0.08);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: appColors[3]),
              const SizedBox(width: 8),
              const Text("Evaluciones del Estudiante", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
            ],
          ),
          const Divider(),
        ],
      ),
      content: Container(
        width: 700,
        child: exams.isEmpty
            ? const Padding(
          padding: EdgeInsets.all(15),
          child: Text("No hay evaluaciones registradas."),
        )
            : SingleChildScrollView(
          child: DataTable(
            headingRowColor:
            MaterialStateProperty.all(Colors.indigo.shade50),
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text("Bloque")),
              DataColumn(label: Text("Tipo")),
              DataColumn(label: Text("Fecha")),
              DataColumn(label: Text("Puntaje")),
            ],
            rows: exams.map((exam) {
              final block = exam["teachingblocks"]?["teachingBlock"] ?? "—";
              final type = exam["type"] ?? "—";
              final date = exam["createdAt"]?.toString().split("T").first ?? "—";
              final score = double.tryParse(exam["score"]?.toString() ?? "");
              return DataRow(cells: [
                DataCell(Text(block)),
                DataCell(Text(type)),
                DataCell(Text(date)),
                DataCell(Container(
                  color: _getNoteBackground(score),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    score != null ? score.toStringAsFixed(2) : "—",
                    style: TextStyle(color: _getNoteColor(score), fontWeight: FontWeight.bold),
                  ),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),
      ],
    );
  }
}
