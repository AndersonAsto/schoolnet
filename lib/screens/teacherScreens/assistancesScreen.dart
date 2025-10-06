import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AssistancesScreen extends StatefulWidget {
  final int teacherId;
  final String token;

  const AssistancesScreen({
    super.key,
    required this.teacherId,
    required this.token,
  });

  @override
  State<AssistancesScreen> createState() => _AssistancesScreenState();
}

class _AssistancesScreenState extends State<AssistancesScreen> {
  TextEditingController yearIdController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();

  String? token;
  List schedules = [];
  List schoolDays = [];

  String? selectedScheduleId;
  String? selectedSchoolDayId;

  bool loadingSchedules = false;
  bool loadingDays = false;

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

  // 🧩 Nueva versión del método para cargar horarios por año
  Future<void> _loadSchedulesByYear() async {
    final selectedYearId = yearIdController.text.trim();
    if (selectedYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione primero un año")),
      );
      return;
    }

    setState(() {
      loadingSchedules = true;
      schedules = [];
      selectedScheduleId = null;
    });

    final url = Uri.parse(
      "http://localhost:3000/api/schedules/by-user/${widget.teacherId}/year/$selectedYearId",
    );

    print("📅 Cargando horarios para teacherId=${widget.teacherId}, yearId=$selectedYearId");

    final res = await http.get(
      url,
      headers: {
        "Authorization": "Bearer ${token ?? widget.token}",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() => schedules = data);
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se encontraron horarios para este año.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cargando horarios: ${res.body}")),
      );
    }

    setState(() => loadingSchedules = false);
  }

  Future<void> _openAssistancesDialog() async {
    if (selectedScheduleId == null || selectedSchoolDayId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione horario y día lectivo")),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AssistancesDialog(
          scheduleId: selectedScheduleId!,
          schoolDayId: selectedSchoolDayId!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Asistencias - Docente ${widget.teacherId}",
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: SelectionField(
                    hintText: "Seleccionar Año",
                    displayController: yearDisplayController,
                    idController: yearIdController,
                    onTap: () async => await showYearsSelection(context, yearIdController, yearDisplayController),
                  ),
                ),
              ],
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
                    "${item["weekday"]} (${item["startTime"]} - ${item["endTime"]})",
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedScheduleId = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: loadingDays
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Día lectivo"),
              value: selectedSchoolDayId,
              items: schoolDays.map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem<String>(
                  value: item["id"].toString(),
                  child: Text(item["teachingDay"]),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedSchoolDayId = val),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appColors[3]),
            onPressed: _openAssistancesDialog,
            child: const Text("Cargar asistencias", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class AssistancesDialog extends StatefulWidget {
  final String scheduleId;
  final String schoolDayId;

  const AssistancesDialog({
    super.key,
    required this.scheduleId,
    required this.schoolDayId,
  });

  @override
  State<AssistancesDialog> createState() => _AssistancesDialogState();
}

class _AssistancesDialogState extends State<AssistancesDialog> {
  List<Map<String, dynamic>> students = [];
  bool loading = false;
  final List<String> attendanceOptions = ['P', 'J', 'T', 'F'];

  @override
  void initState() {
    super.initState();
    _loadStudentsAndAssistances();
  }

  Future<void> _loadStudentsAndAssistances() async {
    setState(() => loading = true);

    try {
      final studentsRes = await http.get(
        Uri.parse("http://localhost:3000/api/studentEnrollments/bySchedule/${widget.scheduleId}"),
      );
      final assistancesRes = await http.get(Uri.parse(
        "http://localhost:3000/api/assistances/byScheduleAndDay?scheduleId=${widget.scheduleId}&schoolDayId=${widget.schoolDayId}",
      ));

      if (studentsRes.statusCode == 200 && assistancesRes.statusCode == 200) {
        final enrollments = json.decode(studentsRes.body);
        final assistances = json.decode(assistancesRes.body) as List;

        students = enrollments.map<Map<String, dynamic>>((e) {
          final existing = assistances.firstWhere(
                (a) => a["studentId"] == e["id"],
            orElse: () => null,
          );
          return {
            "id": existing?["id"],
            "studentId": e["id"],
            "name": "${e["persons"]["names"]} ${e["persons"]["lastNames"]}",
            "assistance": existing?["assistance"] ?? "P",
            "assistanceDetail": existing?["assistanceDetail"] ?? ""
          };
        }).toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: $e")),
      );
    }

    setState(() => loading = false);
  }

  void _setAttendance(int index, String value) {
    setState(() {
      students[index]["assistance"] = value;
    });
  }

  Future<void> _saveAssistances() async {
    final nuevos = students.where((s) => s["id"] == null).map((s) {
      return {
        "studentId": s["studentId"],
        "scheduleId": int.parse(widget.scheduleId),
        "schoolDayId": int.parse(widget.schoolDayId),
        "assistance": s["assistance"],
        "assistanceDetail": s["assistanceDetail"] ?? "",
        "status": true
      };
    }).toList();

    final existentes = students.where((s) => s["id"] != null).map((s) {
      return {
        "id": s["id"],
        "studentId": s["studentId"],
        "scheduleId": int.parse(widget.scheduleId),
        "schoolDayId": int.parse(widget.schoolDayId),
        "assistance": s["assistance"],
        "assistanceDetail": s["assistanceDetail"] ?? "",
      };
    }).toList();

    try {
      if (nuevos.isNotEmpty) {
        final resCreate = await http.post(
          Uri.parse("http://localhost:3000/api/assistances/bulkCreate"),
          headers: {"Content-Type": "application/json"},
          body: json.encode(nuevos),
        );
        if (resCreate.statusCode != 200 && resCreate.statusCode != 201) {
          throw Exception("Error en creación: ${resCreate.body}");
        }
      }

      if (existentes.isNotEmpty) {
        final resUpdate = await http.put(
          Uri.parse("http://localhost:3000/api/assistances/bulkUpdate"),
          headers: {"Content-Type": "application/json"},
          body: json.encode(existentes),
        );
        if (resUpdate.statusCode != 200) {
          throw Exception("Error en actualización: ${resUpdate.body}");
        }
      }

      Navigator.pop(context); // Cerramos el diálogo al confirmar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Asistencias guardadas/actualizadas correctamente")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: const Text("Registrar asistencias"),
      content: SizedBox(
        width: screenWidth * 0.6,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          shrinkWrap: true,
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return ListTile(
              title: Text(student["name"]),
              subtitle: Row(
                children: attendanceOptions.map((opt) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(opt),
                      selected: student["assistance"] == opt,
                      onSelected: (_) => _setAttendance(index, opt),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _saveAssistances,
          style: ElevatedButton.styleFrom(backgroundColor: appColors[3]),
          child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
