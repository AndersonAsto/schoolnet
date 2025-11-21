import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/teacherScreens/annualAverageScreen.dart';
import 'package:schoolnet/screens/teacherScreens/overallCourseAverageScreen.dart';
import 'package:schoolnet/screens/teacherScreens/teachingBlockAveragesScreen.dart';
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:schoolnet/utils/customTextFields.dart';
import 'package:http/http.dart' as http;

class AcademicPerformanceScreen extends StatefulWidget {
  const AcademicPerformanceScreen({super.key});

  @override
  State<AcademicPerformanceScreen> createState() => _AcademicPerformanceScreenState();
}

class _AcademicPerformanceScreenState extends State<AcademicPerformanceScreen> {
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

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([
      _fetchYears(),
      _fetchTutors(),
    ]);
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

  Future<void> _fetchTutors() async {
    setState(() => loadingTutors = true);
    try {
      final response = await ApiService.request("api/tutors/list");
      if (response.statusCode == 200) {
        setState(() {
          tutors = json.decode(response.body);
        });
      } else {
        debugPrint("Error al obtener tutores: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error al conectar (tutores): $e");
    } finally {
      setState(() => loadingTutors = false);
    }
  }

  Future<void> _onLoadYearAndTutorPressed() async {
    final selectedYearId = yearIdController.text.trim();
    if (selectedYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione primero un año escolar.")),
      );
      return;
    }

    setState(() {
      yearLoaded = true;
      selectedTutorId = null;
      students = [];
      selectedStudentId = null;
      annualAverages = [];
      schedules = [];
      assignmentId = null;
    });
  }

  Future<void> _loadStudentsByTutor() async {
    if (selectedTutorId == null) return;

    setState(() {
      loadingStudents = true;
      students = [];
      selectedStudentId = null;
    });

    try {
      final response = await ApiService.request(
          "api/studentEnrollments/by-tutor/$selectedTutorId");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => students = data);

        if (data.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No hay estudiantes en este grupo.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error cargando estudiantes: ${response.body}")),
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

  Future<void> _fetchAnnualAveragesByTutor() async {
    if (yearIdController.text.isEmpty || selectedTutorId == null) return;

    setState(() => loadingAnnualAverages = true);

    try {
      final response = await ApiService.request(
          "api/annualAverage/by-year-&-tutor/${yearIdController.text}/$selectedTutorId");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded["data"];
        setState(() {
          annualAverages =
          data is List ? List<Map<String, dynamic>>.from(data) : [];
        });
      } else {
        setState(() => annualAverages = []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error al obtener promedios anuales del grupo: ${response.body}",
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error al obtener promedio anual del estudiante: ${response.body}",
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
          Uri.parse("http://localhost:3000/api/qualifications/by-group/$assignmentId/student/$selectedStudentId"),
        ),
        http.get(
          Uri.parse("http://localhost:3000/api/assistances/by-group/$assignmentId/student/$selectedStudentId"),
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
        "http://localhost:3000/api/teacherGroups/by-year/${yearIdController.text}/by-tutor/$selectedTutorId",
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          // asumo que el endpoint devuelve un array como el que pegaste
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

    final url = Uri.parse("http://localhost:3000/api/exams/student/$selectedStudentId/group/$assignmentId");

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendimiento Académico', style: TextStyle(fontSize: 15, color: Colors.white),),
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
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                    label: const Text("Cargar Grupo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors[3],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
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
                child: loadingTutors
                    ? const Center(child: CircularProgressIndicator())
                    : CustomInputContainer(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Seleccionar Tutor (Grado y Sección)",
                      border: InputBorder.none,
                      fillColor: Colors.grey[100],
                      filled: true,
                      prefixIcon: const Icon(Icons.groups),
                    ),
                    value: tutors.any(
                            (t) => t["id"].toString() == selectedTutorId)
                        ? selectedTutorId
                        : null,
                    items: tutors
                        .map<DropdownMenuItem<String>>((item) {
                      final teacher = item["teachers"]?["persons"];
                      final teacherName = teacher != null
                          ? "${teacher["names"]} ${teacher["lastNames"]}"
                          : "Sin docente";
                      final grade = item["grades"]?["grade"] ?? "—";
                      final section =
                          item["sections"]?["seccion"] ?? "—";
                      return DropdownMenuItem<String>(
                        value: item["id"].toString(),
                        child: Text("$grade $section – $teacherName"),
                      );
                    }).toList(),
                    onChanged: (!yearLoaded)
                        ? null
                        : (val) async {
                      setState(() {
                        selectedTutorId = val;
                        students = [];
                        selectedStudentId = null;
                        annualAverages = [];
                      });
                      if (val != null) {
                        await _loadStudentsByTutor();
                        await _fetchAnnualAveragesByTutor();
                        await _loadSchedulesByYearAndTutor();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Dropdown de Estudiantes
              if (students.isNotEmpty) ...[
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
                      value: students.any((s) =>
                      s["id"].toString() == selectedStudentId)
                          ? selectedStudentId
                          : null,
                      items: students
                          .map<DropdownMenuItem<String>>((student) {
                        final person = student["persons"];
                        final studentName =
                            "${person["names"]} ${person["lastNames"]}";
                        return DropdownMenuItem<String>(
                          value: student["id"].toString(),
                          child: Text(studentName),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        setState(() {
                          selectedStudentId = val;
                          annualAverages = [];
                        });
                        if (val != null) {
                          await _fetchAnnualAverageByStudent();
                        } else {
                          await _fetchAnnualAveragesByTutor();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
              // Acciones por estudiante
              if (isStudentSelected)...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: loadingSchedules
                      ? const CircularProgressIndicator()
                      : CustomInputContainer(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Cursos",
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.collections_bookmark_outlined),
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
                ElevatedButton.icon(
                  onPressed: () async {
                    if (selectedStudentId == null || assignmentId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Debe seleccionar un estudiante y un curso.")),
                      );
                      return;
                    }

                    await _loadExamsByStudent();   // 👈 carga desde el endpoint

                    if (!mounted) return;

                    if (studentExams.isNotEmpty) {
                      await _showStudentExamsModal(); // 👈 muestra el diálogo
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No hay registros de evaluaciones para este estudiante.")),
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
                      "Authorization": "Bearer",
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
                  onPressed: loadingGeneralAverages
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
                        vertical: 16, horizontal: 24),
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
                      annualAverages = [];
                    });
                    await _fetchAnnualAveragesByTutor();
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text("Quitar Filtro Estudiante"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors[9],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
              // Tabla de promedios anuales
              if (loadingAnnualAverages)
                const Center(child: CircularProgressIndicator())
              else if (annualAverages.isNotEmpty) ...[
                CustomTitleWidget(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  child: Text(
                    isStudentSelected
                        ? "Rendimiento Académico General del Estudiante"
                        : "Rendimiento Académico General del Grupo",
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
