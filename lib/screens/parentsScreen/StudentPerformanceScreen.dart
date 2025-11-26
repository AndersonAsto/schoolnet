import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/teacherScreens/annualAverageScreen.dart';
import 'package:schoolnet/screens/teacherScreens/overallCourseAverageScreen.dart';
import 'package:schoolnet/screens/teacherScreens/teachingBlockAveragesScreen.dart';
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:schoolnet/utils/customTextFields.dart';
import 'package:flutter/foundation.dart' ;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:html' as html;

class StudentPerformanceScreen extends StatefulWidget {
  final int parentId;
  final List<dynamic> students;
  final String token;
  const StudentPerformanceScreen({
    super.key,
    required this.parentId,
    required this.students,
    required this.token
  });

  @override
  State<StudentPerformanceScreen> createState() => _StudentPerformanceScreenState();
}

class _StudentPerformanceScreenState extends State<StudentPerformanceScreen> {
  final TextEditingController yearIdController = TextEditingController();
  final TextEditingController yearDisplayController = TextEditingController();

  List<Map<String, dynamic>> annualAverages = [];
  List<dynamic> years = [];
  List<dynamic> tutors = [];
  List<dynamic> students = [];
  List studentExams = [];
  List schedules = [];

  String? selectedTutorId;
  String? selectedStudentId;
  String? assignmentId;

  bool loadingSchedules = false;
  bool loadingExams = false;
  bool loadingYears = false;
  bool loadingTutors = false;
  bool loadingStudents = false;
  bool loadingAnnualAverages = false;
  bool loadingGeneralAverages = false;
  bool loadingAnnualAverage = false;
  bool yearLoaded = false;

  bool get isStudentSelected => selectedStudentId != null;
  bool get isCourseSelected => assignmentId != null;
  bool get isYearSelected => yearIdController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    students = List<dynamic>.from(widget.students);
    selectedStudentId = null;
    _fetchYears();
  }

  Future<void> _fetchTutorByStudent() async {
    setState(() => loadingTutors = true);
    try {
      final url = Uri.parse(
        "${generalUrl}api/tutors/student/$selectedStudentId",
      );
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (kDebugMode) {
          print(data);
        }
        setState(() {
          tutors = [data];
          selectedTutorId = data["id"].toString();
        });
      } else {
        debugPrint("Error al obtener tutor por estudiante: ${res.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo obtener tutor del estudiante.")),
        );
      }
    } catch (e) {
      debugPrint("Error al conectar (tutor por estudiante): $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar (tutor): $e")),
      );
    } finally {
      setState(() => loadingTutors = false);
    }
  }

  Future<void> _fetchYears() async {
    setState(() => loadingYears = true);
    try {
      final response = await ApiService.request("api/years/list");
      if (response.statusCode == 200) {
        setState(() {
          years = json.decode(response.body);
        });
      } else {
        debugPrint("Error al obtener años: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error al conectar (años): $e");
    } finally {
      setState(() => loadingYears = false);
    }
  }

  Future<void> _fetchAnnualAveragesForAllStudents() async {
    if (yearIdController.text.isEmpty || students.isEmpty) return;

    setState(() => loadingAnnualAverages = true);

    try {
      final studentIds = students.map((s) => s['id']).toList();

      final res = await http.post(
        Uri.parse('${generalUrl}api/annualAverage/by-year-and-students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'yearId': int.parse(yearIdController.text),
          'studentIds': studentIds,
        }),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded['data'] ?? [];
        setState(() {
          annualAverages =
          List<Map<String, dynamic>>.from(data as List<dynamic>);
        });
      } else if (res.statusCode == 404) {
        setState(() => annualAverages = []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se encontraron promedios anuales.')),
        );
      } else {
        setState(() => annualAverages = []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${res.body}')),
        );
      }
    } catch (e) {
      setState(() => annualAverages = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    } finally {
      setState(() => loadingAnnualAverages = false);
    }
  }

  Future<void> _fetchAnnualAverageByStudent() async {
    if (selectedStudentId == null || yearIdController.text.isEmpty) {
      return;
    }

    setState(() => loadingAnnualAverages = true);

    try {
      final response = await ApiService.request(
          "api/annualAverage/by-year-&-student/${yearIdController.text}/$selectedStudentId");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded["data"];

        setState(() {
          annualAverages =
          data != null ? [Map<String, dynamic>.from(data)] : [];
        });
      } else {
        setState(() => annualAverages = []);
        final Map<String, dynamic> errorData = json.decode(response.body);
        final backendMessage = errorData['message'] ?? "Mensaje de error desconocido";
        final formattedMessage = "Error ${response.statusCode}: $backendMessage";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error al obtener promedio anual del estudiante: $formattedMessage",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con el servidor: $e")),
      );
    } finally {
      setState(() => loadingAnnualAverages = false);
    }
  }

  Future<void> _fetchGeneralAveragesForStudent() async {
    if (selectedStudentId == null || yearIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe seleccionar un año y un estudiante."),
        ),
      );
      return;
    }

    setState(() => loadingGeneralAverages = true);

    try {
      final response = await ApiService.request(
        "api/generalAvarage/by-filters?yearId=${yearIdController.text}&studentId=$selectedStudentId",
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded["data"];
        final averages = data is List ? data : [];

        showDialog(
          context: context,
          builder: (_) => GeneralCourseAveragesDialog(
            averages: List<Map<String, dynamic>>.from(averages),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error al obtener promedios generales por curso: ${response.body}",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con el servidor: $e")),
      );
    } finally {
      setState(() => loadingGeneralAverages = false);
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
          Uri.parse("${generalUrl}api/qualifications/by-group/$assignmentId/student/$selectedStudentId"),
        ),
        http.get(
          Uri.parse("${generalUrl}api/assistances/by-group/$assignmentId/student/$selectedStudentId"),
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

  Future<void> _loadSchedulesByYearAndTutor() async {
    if (yearIdController.text.isEmpty || selectedTutorId == null) return;

    setState(() {
      loadingSchedules = true;
      schedules = [];
      assignmentId = null;
    });

    try {
      final url = Uri.parse(
        "${generalUrl}api/teacherGroups/by-year/${yearIdController.text}/by-tutor/$selectedTutorId",
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          schedules = data is List ? data : [];
        });

        if (schedules.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El tutor no tiene cursos/grupos registrados para este año."),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al obtener cursos del tutor: ${res.body}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con el servidor: $e")),
      );
    } finally {
      setState(() => loadingSchedules = false);
    }
  }

  Future<void> _loadExamsByStudent() async {
    if (selectedStudentId == null) return;

    setState(() {
      loadingExams = true;
      studentExams = [];
    });

    final url = Uri.parse("${generalUrl}api/exams/student/$selectedStudentId/group/$assignmentId");

    try {
      final res = await http.get(url);

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

  Future<void> _onLoadYearAndTutorPressed() async {
    final selectedYearId = yearIdController.text.trim();
    if (selectedYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione primero un año escolar.")),
      );
      return;
    }

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay estudiantes asociados.")),
      );
      return;
    }

    setState(() {
      yearLoaded = true;
      annualAverages = [];
      schedules = [];
      assignmentId = null;
      selectedStudentId = null;   // sin filtro al inicio
    });

    // Tomamos el primer estudiante para obtener el tutor de la sección
    final firstStudentId = students.first["id"].toString();
    selectedTutorId = null;

    // 1. Cargar tutor a partir del primer estudiante
    final urlTutor = Uri.parse(
      "${generalUrl}api/tutors/student/$firstStudentId",
    );

    try {
      final resTutor = await http.get(urlTutor);
      if (resTutor.statusCode == 200) {
        final data = jsonDecode(resTutor.body);
        setState(() {
          tutors = [data];
          selectedTutorId = data["id"].toString();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo obtener tutor del grupo.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al obtener tutor del grupo: $e")),
      );
    }

    // 2. Cargar promedios de TODOS los estudiantes de una vez
    await _fetchAnnualAveragesForAllStudents();

    // 3. Cargar horarios del tutor
    await _loadSchedulesByYearAndTutor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rendimiento Académico de Estudiante', style: const TextStyle(fontSize: 14, color: Colors.white),),
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
                      token: null,
                      onTap: () async {
                        await showYearsSelection(
                          context,
                          yearIdController,
                          yearDisplayController,
                          token: null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _onLoadYearAndTutorPressed,
                    icon: const Icon(Icons.refresh, color: Colors.white,),
                    label: const Text("Cargar Grupo"),
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
              if (yearLoaded && students.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: loadingStudents
                      ? const Center(child: CircularProgressIndicator())
                      : CustomInputContainer(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Seleccionar Estudiante",
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon:
                        const Icon(Icons.person_search_outlined),
                      ),
                      value: students.any(
                              (s) => s["id"].toString() == selectedStudentId)
                          ? selectedStudentId
                          : null,
                      items: students
                          .map<DropdownMenuItem<String>>((student) {
                        final person = student["names"];
                        final lastName = student['lastNames'];
                        final studentName = "$person $lastName";
                        return DropdownMenuItem<String>(
                          value: student["id"].toString(),
                          child: Text(studentName),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        setState(() {
                          selectedStudentId = val;
                          annualAverages = [];
                          schedules = [];
                          assignmentId = null;
                        });

                        if (!isYearSelected) return;

                        if (val == null) {
                          await _fetchAnnualAveragesForAllStudents();
                          await _loadSchedulesByYearAndTutor();
                        } else {
                          await _fetchTutorByStudent();
                          await _fetchAnnualAverageByStudent();
                          await _loadSchedulesByYearAndTutor();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
              if (yearLoaded && isStudentSelected) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: loadingSchedules
                      ? const CircularProgressIndicator()
                      : CustomInputContainer(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Seleccionar Curso",
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(
                          Icons.collections_bookmark_outlined,
                        ),
                      ),
                      value: assignmentId,
                      items: schedules
                          .map<DropdownMenuItem<String>>((item) {
                        final course = item["courses"]?["course"] ?? "Sin curso";
                        final grade = item["grades"]?["grade"] ?? "—";
                        final section = item["sections"]?["seccion"] ?? "—";
                        return DropdownMenuItem<String>(
                          value: item["id"].toString(),
                          child: Text("$course - $grade $section"),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => assignmentId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
              if (yearLoaded && isStudentSelected && isCourseSelected) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    _showStudentDailyRecordsModal();
                  },
                  icon: const Icon(Icons.visibility, color: Colors.white),
                  label: const Text(
                    "Ver Calificación Diaria",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors[9],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _loadExamsByStudent();
                    if (!mounted) return;
                    if (studentExams.isNotEmpty) {
                      await _showStudentExamsModal();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "No hay registros de evaluaciones para este estudiante.",
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.visibility, color: Colors.white),
                  label: const Text(
                    "Ver Calificación de Evaluaciones",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors[9],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(
                      "${generalUrl}api/teachingblockaverage/byStudent/$selectedStudentId/year/${yearIdController.text}/assignment/$assignmentId",
                    );
                    final res = await http.get(url, headers: {
                      "Authorization": "Bearer ${widget.token}",
                      "Content-Type": "application/json",
                    });
                    if (res.statusCode == 200) {
                      final data = json.decode(res.body);
                      showDialog(
                        context: context,
                        builder: (_) => StudentBlockAveragesDialog(
                          blockAverages:
                          List<Map<String, dynamic>>.from(data),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Error al obtener promedios: ${res.body}",
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                  label: const Text("Ver Promedios por Bloques Lectivos del Curso"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors[9],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: loadingGeneralAverages || !isStudentSelected
                      ? null
                      : _fetchGeneralAveragesForStudent,
                  icon: loadingGeneralAverages
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.summarize, color: Colors.white),
                  label: const Text(
                    "Ver Promedios Generales de Cursos",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors[9],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () async {
                    setState(() {
                      selectedStudentId = null;
                      assignmentId = null;
                      annualAverages = [];
                    });
                    await _fetchAnnualAveragesForAllStudents();
                    await _loadSchedulesByYearAndTutor();
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text("Quitar Filtro Estudiante"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors[9],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: GenerateReportButton(
                    yearId: yearIdController.text.isNotEmpty ? yearIdController.text : null,
                    studentId: selectedStudentId,
                    studentName: () {
                      try {
                        final st = students.firstWhere(
                              (s) => s["id"].toString() == selectedStudentId,
                          orElse: () => null,
                        );
                        if (st == null) return null;
                        final names = st["names"] ?? "";
                        final lastNames = st["lastNames"] ?? "";
                        return "$names $lastNames";
                      } catch (_) {
                        return null;
                      }
                    }(),
                    token: widget.token,
                    yearLabel: yearDisplayController.text.isNotEmpty
                        ? yearDisplayController.text
                        : null,
                  ),
                ),
                const SizedBox(height: 15),
              ],
              // Tabla de promedios anuales
              if (loadingAnnualAverages)
                const Center(child: CircularProgressIndicator())
              else if (annualAverages.isNotEmpty) ...[
                CustomTitleWidget(
                  padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    isStudentSelected
                        ? "Rendimiento Académico General de Estudiante"
                        : "Rendimiento Académico General de Estudiantes",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                AnnualAveragesTable(generalAverages: annualAverages),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GenerateReportButton extends StatelessWidget {
  final String? yearId;
  final String? studentId;
  final String? studentName;
  final String? token;
  final VoidCallback? onBeforeRequest;
  final VoidCallback? onAfterRequest;
  final String? yearLabel;

  const GenerateReportButton({
    super.key,
    required this.yearId,
    required this.studentId,
    required this.studentName,
    required this.yearLabel,
    this.token,
    this.onBeforeRequest,
    this.onAfterRequest,
  });

  bool get _canGenerate => yearId != null && yearId!.isNotEmpty && studentId != null;

  String _getFileNameFromHeaders(http.Response res) {
    final contentDisposition = res.headers['content-disposition'];

    debugPrint('Content-Disposition: $contentDisposition');

    if (contentDisposition != null) {
      final regex = RegExp(r'filename="?([^\";]+)"?');
      final match = regex.firstMatch(contentDisposition);

      if (match != null && match.groupCount >= 1) {
        String filename = match.group(1)!;
        return filename.replaceAll('"', '').trim();
      }
    }

    return 'reporte.pdf';
  }

  Future<void> _downloadReport(BuildContext context) async {
    if (!_canGenerate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar año y estudiante.')),
      );
      return;
    }

    final url = Uri.parse(
      '${generalUrl}api/reports/student/$studentId/year/$yearId',
    );

    try {
      onBeforeRequest?.call();

      final res = await http.get(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) {
        throw 'Error al generar reporte (${res.statusCode})';
      }

      final bytes = res.bodyBytes;
      final fileName = _getFileNameFromHeaders(res);

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: blobUrl)
          ..setAttribute('download', fileName)
          ..style.display = 'none';

        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(blobUrl);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        await OpenFilex.open(file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar reporte: $e')),
      );
    } finally {
      onAfterRequest?.call();
    }
  }

  Future<void> _showConfirmDialog(BuildContext context) async {
    if (!_canGenerate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar año y estudiante.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.document_scanner_outlined, color: appColors[3]),
                  const SizedBox(width: 8),
                  const Text(
                    "Confirmar Generación de Reporte",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Colors.black),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Desea generar el reporte de rendimiento académico?'),
              const SizedBox(height: 8),
              if (studentName != null) Text('Estudiante: $studentName'),
              if (yearLabel != null) ...[
                Text('Año: $yearLabel'),
              ],
              const Divider(color: Colors.black),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors[3],
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _downloadReport(context);
              },
              icon: const Icon(
                Icons.download,
                color: Colors.white,
              ),
              label: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _canGenerate ? () => _showConfirmDialog(context) : null,
      icon: const Icon(Icons.document_scanner_outlined, color: Colors.white),
      label: const Text("Generar Reporte", style: TextStyle(color: Colors.white, fontSize: 12),),
      style: ElevatedButton.styleFrom(
        backgroundColor: _canGenerate ? appColors[3] : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
