import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/customDataSelection.dart';

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
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loadYearData,
              icon: const Icon(Icons.refresh),
              label: const Text("Cargar Horarios"),
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
                decoration: const InputDecoration(labelText: "Grupo Docente"),
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

                    // 🔹 Si hay año seleccionado, mostrar el promedio general del grupo
                    if (yearIdController.text.isNotEmpty) {
                      await _fetchGeneralAverages();
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 10,),
            if (students.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Seleccionar Estudiante",
                        border: OutlineInputBorder(),
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
                  ],
                ),
              ),
            const SizedBox(height: 10,),
            if (loadingGeneralAverages)
              const Center(child: CircularProgressIndicator())
            else if (generalAverages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text(
                      "📊 Promedios Generales por Curso",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade50),
                        dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Theme.of(context).colorScheme.primary.withOpacity(0.08);
                            }
                            return null; // default
                          },
                        ),
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text("Año", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Curso", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Estudiante", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Grado y Sección", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Promedio Final", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: generalAverages.map<DataRow>((avg) {
                          final student = avg["students"]?["persons"];
                          final teacherGroup = avg["teachergroups"];

                          final course = teacherGroup?["courses"]?["course"] ?? '—';
                          final grade = teacherGroup?["grades"]?["grade"] ?? '—';
                          final section = teacherGroup?["sections"]?["seccion"] ?? '—';
                          final year = avg["years"]?["year"]?.toString() ?? '—';
                          final courseAverage = avg["courseAverage"]?.toString() ?? '—';

                          final names = student?["names"] ?? '—';
                          final lastNames = student?["lastNames"] ?? '';
                          final fullName = "$names $lastNames".trim();

                          return DataRow(
                            color: WidgetStateProperty.all(
                              generalAverages.indexOf(avg) % 2 == 0
                                  ? Colors.grey.shade50
                                  : Colors.white,
                            ),
                            cells: [
                              DataCell(Text(year, style: const TextStyle(fontSize: 13))),
                              DataCell(Text(course, style: const TextStyle(fontSize: 13))),
                              DataCell(Text(fullName, style: const TextStyle(fontSize: 13))),
                              DataCell(Text("$grade $section", style: const TextStyle(fontSize: 13))),
                              DataCell(
                                Text(
                                  double.tryParse(courseAverage)?.toStringAsFixed(2) ?? courseAverage,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueAccent),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              )
            else if (selectedStudentId != null)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text("No se encontraron promedios para este estudiante."),
              ),
            const SizedBox(height: 10,),
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
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => _buildAveragesModal(data),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error al obtener promedios: ${res.body}")),
                  );
                }
              },
              icon: const Icon(Icons.bar_chart),
              label: const Text("Ver Promedios de Bloques"),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors[3],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAveragesModal(List data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Promedios por Bloque Lectivo",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          ...data.map((item) {
            final block = item["teachingblocks"]["teachingBlock"];
            final avg = item["teachingBlockAvarage"];
            return ListTile(
              title: Text(block),
              trailing: Text(avg.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }).toList(),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () async {
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
            },
            icon: const Icon(Icons.summarize),
            label: const Text("Calcular Promedio Anual"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}