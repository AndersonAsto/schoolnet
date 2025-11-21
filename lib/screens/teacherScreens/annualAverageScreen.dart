import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/customTextFields.dart';

class AnnualAverageScreen extends StatefulWidget {
  final int teacherId;
  final int tutorId;
  final String token;

  const AnnualAverageScreen({
    super.key,
    required this.teacherId,
    required this.tutorId,
    required this.token
  });

  @override
  State<AnnualAverageScreen> createState() => _AnnualAverageScreenState();
}

class _AnnualAverageScreenState extends State<AnnualAverageScreen> {
  TextEditingController yearIdController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();

  List<Map<String, dynamic>> annualAverages = [];
  List students = [];

  String? token;
  String? selectedStudentId;

  bool loadingTutorInfo = false;
  bool loadingStudents = false;
  bool loadingAnnualAverages = false;
  bool loadingGeneralAverages = false;
  bool loadingAnnualAverage = false;

  String? tutorName;
  String? gradeName;
  String? sectionName;

  @override
  void initState() {
    super.initState();
    loadTokenAndTutorInfo();
  }

  Future<void> loadTokenAndTutorInfo() async {
    final savedToken = await storage.read(key: "auth_token");
    setState(() {
      token = savedToken ?? widget.token;
    });
    await _loadTutorInfo();
  }

  Future<void> _loadTutorInfo() async {
    setState(() => loadingTutorInfo = true);

    final url = Uri.parse(
        "http://localhost:3000/api/tutors/by-id/${widget.tutorId}");

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);

        if (decoded is List && decoded.isNotEmpty) {
          final tutor = decoded[0];

          final person = tutor["teachers"]?["persons"];
          final grades = tutor["grades"];
          final sections = tutor["sections"];

          setState(() {
            tutorName =
                "${person?["names"] ?? ""} ${person?["lastNames"] ?? ""}".trim();
            gradeName = grades?["grade"] ?? "";
            sectionName = sections?["seccion"] ?? "";
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar datos del tutor: ${res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar con el servidor: $e")),
      );
    } finally {
      setState(() => loadingTutorInfo = false);
    }
  }

  /// Botón "Cargar Estudiantes"
  Future<void> _onLoadYearPressed() async {
    final selectedYearId = yearIdController.text.trim();
    if (selectedYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione primero un año escolar.")),
      );
      return;
    }

    setState(() {
      students = [];
      selectedStudentId = null;
      annualAverages = [];
    });

    await _loadStudentsByTutor();
    await _fetchAnnualAveragesByTutor(); // 🔹 Cargar promedios del grupo
  }

  Future<void> _loadStudentsByTutor() async {
    setState(() {
      loadingStudents = true;
      students = [];
      selectedStudentId = null;
    });

    final url = Uri.parse(
        "http://localhost:3000/api/studentEnrollments/by-tutor/${widget.tutorId}");

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
            const SnackBar(content: Text("No hay estudiantes en este grupo.")),
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

  /// 🔹 Usa: GET /api/annualAverage/by-year-&-tutor/:yearId/:tutorId
  Future<void> _fetchAnnualAveragesByTutor() async {
    if (yearIdController.text.isEmpty) return;

    setState(() => loadingAnnualAverages = true);

    final url = Uri.parse(
        "http://localhost:3000/api/annualAverage/by-year-&-tutor/${yearIdController.text}/${widget.tutorId}");

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);

        // aquí asumo que devuelves { status, message, data: [ ... ] }
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
                  "Error al obtener promedios anuales del grupo: ${res.body}")),
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

  /// 🔹 Usa: GET /api/annualAverage/by-year-&-student/:yearId/:studentId
  Future<void> _fetchAnnualAverageByStudent() async {
    if (selectedStudentId == null || yearIdController.text.isEmpty) {
      return;
    }

    setState(() => loadingAnnualAverages = true);

    final url = Uri.parse(
        "http://localhost:3000/api/annualAverage/by-year-&-student/${yearIdController.text}/$selectedStudentId");

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final data = decoded["data"];

        // aquí solo viene 1 registro
        setState(() {
          annualAverages = data != null ? [Map<String, dynamic>.from(data)] : [];
        });
      } else {
        setState(() => annualAverages = []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text("Error al obtener promedio anual del estudiante: ${res.body}")),
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

  /// 🔹 Botón que muestra el diálogo de promedios por curso (ya lo tenías armado)
  Future<void> _fetchGeneralAveragesForStudent() async {
    if (selectedStudentId == null || yearIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Debe seleccionar un año y un estudiante.")),
      );
      return;
    }

    setState(() => loadingGeneralAverages = true);

    final url = Uri.parse(
        "http://localhost:3000/api/generalAvarage/by-filters?yearId=${yearIdController.text}&studentId=$selectedStudentId");

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
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
          SnackBar(content: Text("Error al obtener promedios generales por curso: ${res.body}")),
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

  Future<void> _calculateAnnualAverage() async {
    final yearId = yearIdController.text.trim();
    final studentId = selectedStudentId;

    if (yearId.isEmpty || studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe seleccionar año y estudiante para calcular el promedio anual.")),
      );
      return;
    }

    setState(() => loadingAnnualAverage = true);

    try {
      final url = Uri.parse("http://localhost:3000/api/annualaverage/calculate");

      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${token ?? widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "yearId": int.parse(yearId),
          "studentId": int.parse(studentId),
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Promedio anual calculado correctamente.")),
        );

        // 🔹 Después de guardar/actualizar en backend, refrescamos la tabla
        // Solo si aún hay estudiante seleccionado
        if (selectedStudentId != null) {
          await _fetchAnnualAverageByStudent();
        }
      } else {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]?.toString() ?? "Error al calcular promedio anual."),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    } finally {
      setState(() => loadingAnnualAverage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = loadingTutorInfo
        ? "Cargando datos del tutor..."
        : "Promedio General"
        "${tutorName != null && tutorName!.isNotEmpty ? " – Tutor $tutorName" : ""}";
    final isStudentSelected = selectedStudentId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titleText,
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
              // 🔹 Selección de año
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
                    onPressed: _onLoadYearPressed,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                    label: const Text("Cargar Estudiantes"),
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
              // 🔹 Dropdown de estudiantes (sin grupo docente)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: loadingStudents
                    ? const CircularProgressIndicator()
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
                        // 🔹 Cargar promedio anual SOLO de ese estudiante
                        await _fetchAnnualAverageByStudent();
                      } else {
                        // 🔹 Volver a cargar el grupo completo
                        await _fetchAnnualAveragesByTutor();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              if (isStudentSelected)...[
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
                  label: const Text("Ver Promedios Generales de Cursos", style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors[9],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () async {
                    // 1. Limpia el ID del estudiante seleccionado
                    setState(() {
                      selectedStudentId = null;
                      annualAverages = []; // Limpiamos para mostrar el loading si fuera necesario
                    });
                    await _fetchAnnualAveragesByTutor();
                    // 2. Recarga los promedios de TODO el grupo
                    _fetchGeneralAveragesForStudent();
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
                    onPressed: loadingAnnualAverage ? null : _calculateAnnualAverage,
                    icon: loadingAnnualAverage
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.summarize, color: Colors.white),
                    label: Text(
                      loadingAnnualAverage ? "Calculando..." : "Calcular Promedio Anual",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                const SizedBox(height: 15),
              ],
              if (loadingAnnualAverages)
                const Center(child: CircularProgressIndicator())
              else if (annualAverages.isNotEmpty) ...[
                CustomTitleWidget(
                  padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    isStudentSelected
                        ? "Promedio Anual del Estudiante"
                        : "Promedios Anuales del Grupo",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
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

class GeneralCourseAveragesDialog extends StatelessWidget {
  final List<Map<String, dynamic>> averages;

  const GeneralCourseAveragesDialog({super.key, required this.averages});

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
    // asumo que todas las filas son del mismo estudiante/año
    final first = averages.isNotEmpty ? averages.first : null;
    final studentName = first?["students"]?["persons"] != null
        ? "${first!["students"]["persons"]["names"]} ${first["students"]["persons"]["lastNames"]}"
        : "";
    final year = first?["years"]?["year"]?.toString() ?? "";

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: appColors[3]),
              const SizedBox(width: 8),
              const Expanded(
                child: Text("Promedios Generales de Cursos", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
              ),
            ],
          ),
          if (studentName.isNotEmpty || year.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "$studentName - Año $year",
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const Divider(),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: averages.isEmpty
            ? const Padding(
          padding: EdgeInsets.all(15),
          child: Text("No hay promedios generales registrados."),
        )
            : SingleChildScrollView(
          child: DataTable(
            headingRowColor:
            MaterialStateProperty.all(Colors.indigo.shade50),
            columnSpacing: 18,
            columns: const [
              DataColumn(label: Text("Curso")),
              DataColumn(label: Text("Bloque 1")),
              DataColumn(label: Text("Bloque 2")),
              DataColumn(label: Text("Bloque 3")),
              DataColumn(label: Text("Bloque 4")),
              DataColumn(label: Text("Prom. Curso")),
            ],
            rows: averages.map((item) {
              final tg = item["teachergroups"] ?? {};
              final course = tg["courses"]?["course"] ?? "—";

              double? parse(String key) =>
                  double.tryParse(item[key]?.toString() ?? "");

              final b1 = parse("block1Average");
              final b2 = parse("block2Average");
              final b3 = parse("block3Average");
              final b4 = parse("block4Average");
              final avg = parse("courseAverage");

              DataCell buildCell(double? note) => DataCell(
                Container(
                  color: _getNoteBackground(note),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  child: Text(
                    note != null
                        ? note.toStringAsFixed(2)
                        : "—",
                    style: TextStyle(color: _getNoteColor(note)),
                  ),
                ),
              );

              return DataRow(cells: [
                DataCell(Text(course)),
                buildCell(b1),
                buildCell(b2),
                buildCell(b3),
                buildCell(b4),
                DataCell(
                  Container(
                    color: _getNoteBackground(avg),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    child: Text(
                      avg != null ? avg.toStringAsFixed(2) : "—",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getNoteColor(avg),
                      ),
                    ),
                  ),
                ),
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

class AnnualAveragesTable extends StatelessWidget {
  final List<Map<String, dynamic>> generalAverages;
  const AnnualAveragesTable({super.key, required this.generalAverages});

  @override
  Widget build(BuildContext context) {
    final dataSource =
    _AnnualAveragesDataSource(generalAverages: generalAverages);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: PaginatedDataTable(
            columns: const [
              DataColumn(
                  label: Text("Año",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text("Estudiante",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text("Grado y Sección",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text("Promedio Anual",
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            source: dataSource,
            rowsPerPage: 10,
            availableRowsPerPage: const [10, 15, 20, 30],
            showCheckboxColumn: false,
          ),
        ),
      ],
    );
  }
}

class _AnnualAveragesDataSource extends DataTableSource {
  final List<Map<String, dynamic>> generalAverages;

  _AnnualAveragesDataSource({required this.generalAverages});

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
    if (index >= generalAverages.length) return null;

    final avg = generalAverages[index];

    // Del JSON
    final year = avg["years"]?["year"]?.toString() ??
        avg["students"]?["years"]?["year"]?.toString() ??
        '—';

    final student = avg["students"];
    final person = student?["persons"];
    final names = person?["names"] ?? '—';
    final lastNames = person?["lastNames"] ?? '';
    final fullName = "$names $lastNames".trim();

    final grade = student?["grades"]?["grade"] ?? '—';
    final section = student?["sections"]?["seccion"] ?? '—';

    final annualAverage =
    double.tryParse(avg["average"]?.toString() ?? "");

    return DataRow(
      color: index % 2 == 0
          ? WidgetStateProperty.all(Colors.grey.shade50)
          : WidgetStateProperty.all(Colors.white),
      cells: [
        DataCell(Text(year)),
        DataCell(Text(fullName)),
        DataCell(Text("$grade $section")),
        _buildNoteCell(annualAverage),
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
