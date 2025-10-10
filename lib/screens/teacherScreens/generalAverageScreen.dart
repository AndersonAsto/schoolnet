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
  String? token;
  List generalAverages = [];
  bool loadingGeneralAverages = false;
  TextEditingController yearIdController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();
  TextEditingController gradeAverageController = TextEditingController();
  TextEditingController examAverageController = TextEditingController();
  TextEditingController teachingBlockAverage = TextEditingController();

  String? selectedExamType;
  String? selectedStudentId;

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

      // 🔥 Reset de dependencias del año
      selectedStudentId = null;
      generalAverages = [];
      students = [];
    });

    try {
      // Peticiones en paralelo (más eficiente)
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
      // 🔥 Reset dependencias del horario
      selectedStudentId = null;
      generalAverages = [];
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
    if (selectedStudentId == null || selectedScheduleId == null || yearIdController.text.isEmpty) return;

    setState(() => loadingGeneralAverages = true);

    final url = Uri.parse(
      "http://localhost:3000/api/generalAvarage/byStudentYearAndSchedule"
          "?studentId=$selectedStudentId&yearId=${yearIdController.text}&scheduleId=$selectedScheduleId",
    );

    try {
      final res = await http.get(url, headers: {
        "Authorization": "Bearer ${token ?? widget.token}",
        "Content-Type": "application/json",
      });

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);

        // 🔥 Evita crash si no hay data (por ejemplo, alumno sin notas)
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
          "Promedio General - Docente ${widget.teacherId}",
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
                decoration: const InputDecoration(labelText: "Horario"),
                value: schedules.any((s) => s["id"].toString() == selectedScheduleId)
                    ? selectedScheduleId
                    : null,
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
                    selectedStudentId = null;
                    students = [];
                    generalAverages = [];
                    loadingStudents = true;
                  });
                  if (val != null) await _loadStudentsBySchedule();
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
                      decoration: const InputDecoration(labelText: "Seleccionar Estudiante"),
                      value: students.any((s) => s["id"].toString() == selectedStudentId)
                          ? selectedStudentId
                          : null,
                      items: students.map<DropdownMenuItem<String>>((student) {
                        final person = student["persons"];
                        final studentName = "${person["names"]} ${person["lastNames"]}";
                        return DropdownMenuItem<String>(
                          value: student["id"].toString(),
                          child: Text(studentName),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        setState(() {
                          selectedStudentId = val;
                          generalAverages = [];
                        });
                        if (val != null) await _fetchGeneralAverages();
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
                      "Promedios Generales Registrados",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Año")),
                          DataColumn(label: Text("Curso")),
                          DataColumn(label: Text("Estudiante")),
                          DataColumn(label: Text("Grado y Sección")),
                          DataColumn(label: Text("Promedio Anual")),
                        ],
                        rows: generalAverages.map<DataRow>((avg) {
                          final student = avg["students"]?["persons"];
                          final schedules = avg["schedules"];
                          final course = schedules?["courses"]?["course"] ?? '—';
                          final grade = schedules?["grades"]?["grade"] ?? '—';
                          final section = schedules?["sections"]?["seccion"] ?? '—';
                          final year = avg["years"]?["year"] ?? '—';
                          final annualAvg = avg["annualAvarage"]?.toString() ?? '—';
                          final names = student?["names"] ?? '—';
                          final lastNames = student?["lastNames"] ?? '';

                          return DataRow(cells: [
                            DataCell(Text(year.toString())),
                            DataCell(Text(course)),
                            DataCell(Text("$names $lastNames")),
                            DataCell(Text("$grade $section")),
                            DataCell(Text(annualAvg)),
                          ]);
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
                    "http://localhost:3000/api/teachingblockaverage/byStudent/$selectedStudentId/year/${yearIdController.text}/schedule/$selectedScheduleId"
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
            final avg = item["teachingblockavarage"];
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
                  "scheduleId": selectedScheduleId,
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