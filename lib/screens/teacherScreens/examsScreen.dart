import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';

class ExamsScreen extends StatefulWidget {
  final int teacherId;
  final String token;

  const ExamsScreen({
    super.key,
    required this.teacherId,
    required this.token
  });

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  TextEditingController yearIdController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();
  TextEditingController scoreController = TextEditingController();

  List schedules = [];
  List schoolDays = [];
  List studentExams = [];
  List teachingBlocks = [];
  List students = [];

  String? selectedScheduleId;
  String? selectedSchoolDayId;
  String? selectedExamType;
  String? selectedStudentId;
  String? selectedTeachingBlockId;
  String? token;

  bool loadingSchedules = false;
  bool loadingDays = false;
  bool loadingExams = false;
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

    final url = Uri.parse("http://localhost:3000/api/studentEnrollments/by-group/$selectedScheduleId");

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

  Future<void> _createExam() async {
    if (selectedStudentId == null ||
        selectedScheduleId == null ||
        selectedTeachingBlockId == null ||
        scoreController.text.isEmpty ||
        selectedExamType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todos los campos son obligatorios.")),
      );
      return;
    }

    final url = Uri.parse("http://localhost:3000/api/exams/create");

    final body = {
      "studentId": int.parse(selectedStudentId!),
      "assigmentId": int.parse(selectedScheduleId!),
      "teachingBlockId": int.parse(selectedTeachingBlockId!),
      "score": double.parse(scoreController.text),
      "type": selectedExamType,
    };

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Examen registrado correctamente.")),
        );

        await _loadExamsByStudent();

        setState(() {
          scoreController.clear();
          selectedExamType = null;
        });
      } else {
        final error = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${error["message"] ?? "No se pudo registrar el examen."}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con el servidor: $e")),
      );
    }
  }

  Future<void> _loadExamsByStudent() async {
    if (selectedStudentId == null || selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione un estudiante y un grupo docente.")),
      );
      return;
    }

    setState(() {
      loadingExams = true;
      studentExams = [];
    });

    final url = Uri.parse("http://localhost:3000/api/exams/student/$selectedStudentId/group/$selectedScheduleId");

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Calificación de Exámenes - Docente ${widget.teacherId}",
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seleccionar año lectivo, cargar grupos y bloque lectivos
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
                    onPressed: _loadYearData,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("Cargar Horarios y Bloques del Año"),
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
                    : DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Grupo Docente",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  value: selectedScheduleId,
                  items: schedules.map<DropdownMenuItem<String>>((item) {
                    final course = item["courses"]?["course"] ?? "Sin curso";
                    final grade = item["grades"]?["grade"] ?? "—";
                    final section = item["sections"]?["seccion"] ?? "—";
                    return DropdownMenuItem<String>(
                      value: item["id"].toString(),
                      child: Text("$course - $grade $section"),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedScheduleId = val),
                ),
              ),
              const SizedBox(height: 15),
              // Seleccionar bloque lectivo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: loadingBlocks
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Bloque Lectivo",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
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
              // Registrar calificación
              if (selectedTeachingBlockId != null && students.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Registrar Calificación de Práctica o Examen",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      // Seleccionar estudiante
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Seleccionar Estudiante",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
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
                      const SizedBox(height: 15),
                      // Tipo de evaluación
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Tipo de Evaluación",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        value: selectedExamType,
                        items: const [
                          DropdownMenuItem(value: "Práctica", child: Text("Práctica")),
                          DropdownMenuItem(value: "Examen", child: Text("Examen")),
                        ],
                        onChanged: (val) => setState(() => selectedExamType = val),
                      ),
                      const SizedBox(height: 15),
                      // Calificación obtenida
                      TextField(
                        controller: scoreController,
                        decoration: InputDecoration(
                          labelText: 'Calificación Obtenida',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              width: 1,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 15),
                      // Guardar evaluaciones
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _createExam,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text("Guardar Evaluación", style: TextStyle(color: Colors.white, fontSize: 12),),
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
                      // Ver evaluaciones
                      const Text(
                        "Evaluaciones del Estudiante",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      if (loadingExams)
                        const Center(child: CircularProgressIndicator())
                      else if (studentExams.isEmpty)
                        const Text("Sin registros de evaluaciones.")
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text("Bloque")),
                              DataColumn(label: Text("Tipo")),
                              DataColumn(label: Text("Puntaje")),
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
                              ]);
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        )
      ),
    );
  }
}