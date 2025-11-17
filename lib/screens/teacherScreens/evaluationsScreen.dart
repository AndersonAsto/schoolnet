import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:schoolnet/utils/customTextFields.dart';

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

  Future<void> _loadGroupExams() async {
    if (selectedScheduleId == null || selectedTeachingBlockId == null) return;

    setState(() {
      loadingExams = true;
      studentExams = [];
    });

    final url = Uri.parse(
        "http://localhost:3000/api/exams/block/$selectedTeachingBlockId/group/$selectedScheduleId");

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
        setState(() => studentExams = data is Map ? data['exams'] ?? [] : data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al obtener evaluaciones: ${res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    }

    setState(() => loadingExams = false);
  }

  Future<void> _loadExamsByStudent() async {
    if (selectedStudentId == null || selectedScheduleId == null) return;

    setState(() {
      loadingExams = true;
      studentExams = [];
    });

    final url = Uri.parse(
        "http://localhost:3000/api/exams/student/$selectedStudentId/group/$selectedScheduleId");

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
        setState(() => studentExams = data is Map ? data['exams'] ?? [] : data);
      }
    } finally {
      setState(() => loadingExams = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Calificación de Evaluación - Docente ${widget.teacherId}",
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
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
                    icon: const Icon(Icons.refresh, color: Colors.white),
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
              CustomInputContainer(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Grupo Docente",
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: const Icon(Icons.groups),
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
                  onChanged: (val) {
                    setState (() => selectedScheduleId = val);
                    _loadGroupExams();
                  }
                ),
              ),
              const SizedBox(height: 15),
              // Seleccionar bloque lectivo
              CustomInputContainer(
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
                  onChanged: (val) {
                    setState(() => selectedTeachingBlockId = val);
                    _loadGroupExams();
                  },
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
              if (students.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTitleWidget(
                      child: Text("Registrar Calificación de Evaluación",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white,),
                      ),
                    ),
                    const SizedBox(height: 15),
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
                    Row(
                      children: [
                        // Tipo de evaluación
                        Expanded(
                          child: CustomInputContainer(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "Tipo de Evaluación",
                                border: InputBorder.none,
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: const Icon(Icons.check_box_outlined),
                              ),
                              value: selectedExamType,
                              items: const [
                                DropdownMenuItem(value: "Práctica", child: Text("Práctica")),
                                DropdownMenuItem(value: "Examen", child: Text("Examen")),
                              ],
                              onChanged: (val) => setState(() => selectedExamType = val),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Calificación obtenida
                        Expanded(
                          child: TextField(
                            controller: scoreController,
                            decoration: const InputDecoration(
                              labelText: 'Calificación Obtenida',
                              prefixIcon: Icon(Icons.check_box_outlined),
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              if(selectedStudentId != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () {
                        // 1. Limpia el ID del estudiante seleccionado
                        setState(() async {
                          selectedStudentId = null;
                          studentExams = [];
                          await _loadGroupExams(); // Limpiamos para mostrar el loading si fuera necesario
                        });
                        // NOTA: El DropdownButtonFormField se actualizará
                        // automáticamente a "Seleccionar Estudiante" (null)
                        // porque su propiedad `value` maneja el null correctamente.
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text("Quitar Filtro de Estudiante"),
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
                  ],
                ),
              const SizedBox(height: 15,),
              if (studentExams.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ver evaluaciones
                    CustomTitleWidget(
                      child: Text(selectedStudentId != null ? "Evaluciones de Estudiante" : "Evaluciones por Grupo",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white,),
                      ),
                    ),
                    const SizedBox(height: 15),
                    StudentExamsTable(studentExams: studentExams)
                  ],
                ),
            ],
          ),
        )
      ),
    );
  }
}

class StudentExamsTable extends StatelessWidget {
  final List studentExams;

  const StudentExamsTable({super.key, required this.studentExams});

  @override
  Widget build(BuildContext context) {
    final dataSource = _StudentExamsDataSource(studentExams: studentExams);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: PaginatedDataTable(
            columns: const [
              DataColumn(label: Text("Estudiante", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Bloque", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Tipo", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Puntaje", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Acción", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            source: dataSource,
            rowsPerPage: 15,
            availableRowsPerPage: const [5, 10, 15, 20],
            showCheckboxColumn: false,
          ),
        ),
      ],
    );
  }
}

class _StudentExamsDataSource extends DataTableSource {
  final List studentExams;

  _StudentExamsDataSource({required this.studentExams});

  Color _getScoreColor(double? score) {
    if (score == null) return Colors.black87;
    return score >= 11 ? Colors.green[700]! : Colors.red[700]!;
  }

  Color _getScoreBackground(double? score) {
    if (score == null) return Colors.transparent;
    return score >= 11
        ? Colors.green.withOpacity(0.08)
        : Colors.red.withOpacity(0.08);
  }

  DataCell _buildScoreCell(double? score) {
    return DataCell(Container(
      color: _getScoreBackground(score),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        score != null ? score.toStringAsFixed(2) : "—",
        style: TextStyle(
          color: _getScoreColor(score),
          fontWeight: FontWeight.w600,
        ),
      ),
    ));
  }

  @override
  DataRow? getRow(int index) {
    if (index >= studentExams.length) return null;

    final exam = studentExams[index];
    final student = exam['students']?['persons'];
    final fullNames = student != null
        ? "${student["names"]} ${student["lastNames"]}"
        : "Desconocido";
    final block = exam["teachingblocks"]?["teachingBlock"] ?? "—";
    final type = exam["type"] ?? "—";
    final score = double.tryParse(exam["score"]?.toString() ?? "");

    return DataRow(
      color: index.isEven
          ? WidgetStateProperty.all(Colors.grey.shade50)
          : WidgetStateProperty.all(Colors.white),
      cells: [
        DataCell(Text(fullNames)),
        DataCell(Text(block)),
        DataCell(Text(type)),
        _buildScoreCell(score),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.teal),
                tooltip: "Editar Evaluación",
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                tooltip: "Eliminar Evaluación",
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
  int get rowCount => studentExams.length;

  @override
  int get selectedRowCount => 0;
}
