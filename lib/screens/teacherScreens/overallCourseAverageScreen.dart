import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:schoolnet/utils/customTextFields.dart';

class GeneralAverageScreen extends StatefulWidget {
  final int teacherId;
  final String token;

  const GeneralAverageScreen({
    super.key,
    required this.teacherId,
    required this.token
  });

  @override
  State<GeneralAverageScreen> createState() => _GeneralAverageScreenState();
}

class _GeneralAverageScreenState extends State<GeneralAverageScreen> {
  TextEditingController yearIdController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();
  TextEditingController gradeAverageController = TextEditingController();
  TextEditingController examAverageController = TextEditingController();
  TextEditingController teachingBlockAverage = TextEditingController();

  List generalAverages = [];
  List schedules = [];
  List schoolDays = [];
  List studentExams = [];
  List teachingBlocks = [];
  List students = [];

  String? selectedTeachingBlockId;
  String? selectedScheduleId;
  String? selectedSchoolDayId;
  String? selectedExamType;
  String? selectedStudentId;
  String? token;

  bool loadingExams = false;
  bool loadingGeneralAverages = false;
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
      selectedScheduleId = null;
      selectedTeachingBlockId = null;

      // 🔥 Reset de dependencias del año
      selectedStudentId = null;
      generalAverages = [];
      students = [];
    });

    try {
      // Peticiones en paralelo (más eficiente)
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
      // 🔥 Reset dependencias del horario
      selectedStudentId = null;
      generalAverages = [];
    });

    final url = Uri.parse("http://localhost:3000/api/studentEnrollments/by-group/$selectedScheduleId");

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con el servidor: $e")),
      );
    } finally {
      setState(() => loadingStudents = false);
    }
  }

  Future<void> _fetchGeneralAverages() async {
    if (selectedScheduleId == null || yearIdController.text.isEmpty) return;

    setState(() => loadingGeneralAverages = true);

    Uri url;

    if (selectedStudentId != null) {
      url = Uri.parse(
        "http://localhost:3000/api/generalAvarage/by-SYA?studentId=$selectedStudentId&yearId=${yearIdController.text}&assignmentId=$selectedScheduleId",
      );
    } else {
      url = Uri.parse(
        "http://localhost:3000/api/generalAvarage/by-assignment?yearId=${yearIdController.text}&assignmentId=$selectedScheduleId",
      );
    }

    try {
      final res = await http.get(url, headers: {
        "Authorization": "Bearer ${token ?? widget.token}",
        "Content-Type": "application/json",
      });

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final data = decoded["data"];
        setState(() => generalAverages = data is List ? data : []);
      } else {
        setState(() => generalAverages = []);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con el servidor: $e")),
      );
    } finally {
      setState(() => loadingGeneralAverages = false);
    }
  }

  Future<void> _calculateAnnualAverage() async {
    final url = Uri.parse("http://localhost:3000/api/generalAvarage/calculate");
    final res = await http.post(
      url,
      headers: {
        "Authorization": "Bearer ${token ?? widget.token}",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "studentId": selectedStudentId,
        "assignmentId": selectedScheduleId,
        "yearId": yearIdController.text
      }),
    );

    if (res.statusCode == 200) {
      final result = json.decode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Promedio general calculado.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al calcular: ${res.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Promedio General de Curso - Docente ${widget.teacherId}",
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
                    label: const Text("Cargar Grupos"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors[3],
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
              const SizedBox(height: 15),
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
                      onChanged: (val) async {
                        setState(() {
                          selectedScheduleId = val;
                          selectedStudentId = null;
                          students = [];
                          generalAverages = [];
                          loadingStudents = true;
                        });
                        if (val != null) {
                          await _loadStudentsBySchedule();
                          // Mostrar promedio general de grupo si se selecciona un año
                          if (yearIdController.text.isNotEmpty) {
                            await _fetchGeneralAverages();
                          }
                        }
                      },
                    ),
                )
              ),
              const SizedBox(height: 15),
              CustomInputContainer(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Seleccionar Estudiante",
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.person_search_outlined),
                    ),
                    // 🔹 Si el estudiante seleccionado ya no está en la lista, mostrar null
                    value: students.any((s) => s["id"].toString() == selectedStudentId)
                        ? selectedStudentId
                        : null,
                    // 🔹 Lista desplegable de estudiantes
                    items: students.map<DropdownMenuItem<String>>((student) {
                      final person = student["persons"];
                      final studentName = "${person["names"]} ${person["lastNames"]}";
                      return DropdownMenuItem<String>(
                        value: student["id"].toString(),
                        child: Text(studentName),
                      );
                    }).toList(),
                    // 🔹 Cuando seleccionas un estudiante específico
                    onChanged: (val) async {
                      setState(() {
                        selectedStudentId = val;
                        generalAverages = [];
                      });

                      if (val != null) {
                        // Si hay estudiante seleccionado → buscar por SYA
                        await _fetchGeneralAverages();
                      } else {
                        // Si quitas la selección → buscar por grupo
                        if (selectedScheduleId != null && yearIdController.text.isNotEmpty) {
                          await _fetchGeneralAverages();
                        }
                      }
                    },
                  ),
              ),
              if (selectedStudentId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (selectedStudentId == null || selectedScheduleId == null || yearIdController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Debe seleccionar año, horario y estudiante.")),
                            );
                            return;
                          }

                          final url = Uri.parse(
                              "http://localhost:3000/api/teachingblockaverage/byStudent/$selectedStudentId/year/${yearIdController.text}/assignment/$selectedScheduleId"
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
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        onPressed: () {
                          // 1. Limpia el ID del estudiante seleccionado
                          setState(() {
                            selectedStudentId = null;
                            generalAverages = []; // Limpiamos para mostrar el loading si fuera necesario
                          });
                          // 2. Recarga los promedios de TODO el grupo
                          _fetchGeneralAverages();
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
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _calculateAnnualAverage,
                          icon: const Icon(Icons.summarize, color: Colors.white),
                          label: const Text(
                            "Calcular Promedio Anual",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
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
                ),
              const SizedBox(height: 15),
              if (generalAverages.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTitleWidget(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text(selectedStudentId == null? "Promedios Generales por Grupo" : "Promedio General de Estudiante",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white,),),
                    ),
                    const SizedBox(height: 15),
                    GeneralAveragesTable(generalAverages: generalAverages.cast<Map<String, dynamic>>()),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}

class StudentBlockAveragesDialog extends StatelessWidget {
  final List<Map<String, dynamic>> blockAverages;

  const StudentBlockAveragesDialog({super.key, required this.blockAverages});

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
              Icon(Icons.bar_chart, color: appColors[3]),
              const SizedBox(width: 8),
              const Text(
                "Promedios por Bloques Lectivos del Curso",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
      content: Container(
        width: 600,
        child: blockAverages.isEmpty
            ? const Padding(
          padding: EdgeInsets.all(15),
          child: Text("No hay promedios registrados."),
        )
            : SingleChildScrollView(
          child: DataTable(
            headingRowColor:
            MaterialStateProperty.all(Colors.indigo.shade50),
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text("Bloque")),
              DataColumn(label: Text("P. Diario")),
              DataColumn(label: Text("P. Prácticas")),
              DataColumn(label: Text("P. Exámenes")),
              DataColumn(label: Text("P. Final")),
            ],
            rows: blockAverages.map((item) {
              final block = item["teachingblocks"]?["teachingBlock"] ?? "—";
              final daily = double.tryParse(item["dailyAvarage"]?.toString() ?? "");
              final practices = double.tryParse(item["practiceAvarage"]?.toString() ?? "");
              final exams = double.tryParse(item["examAvarage"]?.toString() ?? "");
              final total = double.tryParse(item["teachingBlockAvarage"]?.toString() ?? "");

              return DataRow(cells: [
                DataCell(Text(block)),
                DataCell(Container(
                  color: _getNoteBackground(daily),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    daily != null ? daily.toStringAsFixed(2) : "—",
                    style: TextStyle(color: _getNoteColor(daily)),
                  ),
                )),
                DataCell(Container(
                  color: _getNoteBackground(practices),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    practices != null ? practices.toStringAsFixed(2) : "—",
                    style: TextStyle(color: _getNoteColor(practices)),
                  ),
                )),
                DataCell(Container(
                  color: _getNoteBackground(exams),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    exams != null ? exams.toStringAsFixed(2) : "—",
                    style: TextStyle(color: _getNoteColor(exams)),
                  ),
                )),
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

class GeneralAveragesTable extends StatelessWidget {
  final List<Map<String, dynamic>> generalAverages;
  const GeneralAveragesTable({super.key, required this.generalAverages});

  @override
  Widget build(BuildContext context) {
    // 1. Crear la fuente de datos
    final dataSource = _GeneralAveragesDataSource(generalAverages: generalAverages);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // El widget PaginatedDataTable maneja automáticamente el scroll horizontal
        // y la paginación, logrando el comportamiento deseado.
        SizedBox( // Usamos SizedBox para que el PaginatedDataTable se estire.
          width: double.infinity,
          child: PaginatedDataTable(
            columns: const [
              DataColumn(label: Text("Año", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Curso", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Estudiante", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Grado y Sección", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Prom. BL1", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Prom. BL2", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Prom. BL3", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Prom. BL4", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Promedio Final", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            source: dataSource,
            rowsPerPage: 15,
            availableRowsPerPage: const [10, 15, 20, 30],
            showCheckboxColumn: false,
          ),
        ),
      ],
    );
  }
}

class _GeneralAveragesDataSource extends DataTableSource {
  final List<Map<String, dynamic>> generalAverages;

  _GeneralAveragesDataSource({required this.generalAverages});

  // Helper functions (duplicadas de GeneralAveragesTable)
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

  // Helper widget para las celdas de notas
  DataCell _buildNoteCell(double? note) {
    return DataCell(Container(
      color: _getNoteBackground(note),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        note != null ? note.toStringAsFixed(2) : "—",
        style: TextStyle(
          color: _getNoteColor(note),
          fontWeight: note != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ));
  }

  @override
  DataRow? getRow(int index) {
    if (index >= generalAverages.length) {
      return null;
    }

    final avg = generalAverages[index];
    final student = avg["students"]?["persons"];
    final teacherGroup = avg["teachergroups"];

    final course = teacherGroup?["courses"]?["course"] ?? '—';
    final grade = teacherGroup?["grades"]?["grade"] ?? '—';
    final section = teacherGroup?["sections"]?["seccion"] ?? '—';
    final year = avg["years"]?["year"]?.toString() ?? '—';
    final courseAverage = double.tryParse(avg["courseAverage"]?.toString() ?? "");
    final pbl1 = double.tryParse(avg['block1Average']?.toString() ?? "");
    final pbl2 = double.tryParse(avg['block2Average']?.toString() ?? "");
    final pbl3 = double.tryParse(avg['block3Average']?.toString() ?? "");
    final pbl4 = double.tryParse(avg['block4Average']?.toString() ?? "");
    final names = student?["names"] ?? '—';
    final lastNames = student?["lastNames"] ?? '';
    final fullName = "$names $lastNames".trim();

    return DataRow(
      color: index % 2 == 0
          ? WidgetStateProperty.all(Colors.grey.shade50)
          : WidgetStateProperty.all(Colors.white),
      cells: [
        DataCell(Text(year)),
        DataCell(Text(course)),
        DataCell(Text(fullName)),
        DataCell(Text("$grade $section")),
        _buildNoteCell(pbl1),
        _buildNoteCell(pbl2),
        _buildNoteCell(pbl3),
        _buildNoteCell(pbl4),
        _buildNoteCell(courseAverage), // Promedio Final
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => generalAverages.length;

  @override
  int get selectedRowCount => 0;
}
