import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:intl/intl.dart';
import 'package:schoolnet/utils/customTextFields.dart';
import 'package:table_calendar/table_calendar.dart';

class AssistancesScreen extends StatefulWidget {
  final int teacherId;
  final String token;

  const AssistancesScreen({super.key, required this.teacherId, required this.token});

  @override
  State<AssistancesScreen> createState() => _AssistancesScreenState();
}

class _AssistancesScreenState extends State<AssistancesScreen> {
  TextEditingController yearIdController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();
  TextEditingController selectedDateController = TextEditingController();

  String? token;
  String? selectedScheduleId;
  String? selectedSchoolDayId;

  bool loadingSchedules = false;
  bool loadingDays = false;

  List schedules = [];
  List schoolDays = [];

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
      body: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: materialTextSelectionControls,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selección y carga de año escolar
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
                    onPressed: _loadSchedulesByYear,
                    icon: const Icon(Icons.schedule, color: Colors.white),
                    label: const Text("Cargar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors[3],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Selección de horarios
              CustomInputContainer(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Horario",
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: const Icon(Icons.schedule),
                  ),
                  value: selectedScheduleId,
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
                  onChanged: (val) => setState(() => selectedScheduleId = val),
                ),
              ),
              const SizedBox(height: 15),
              // Recargar días lectivos
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors[3],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                ),
                onPressed: () async {
                  if (selectedScheduleId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Seleccione primero un horario")),
                    );
                    return;
                  }
                  setState(() {
                    loadingDays = true;
                    schoolDays = [];
                    selectedSchoolDayId = null;
                  });
                  try {
                    final url = Uri.parse(
                        "http://localhost:3000/api/scheduleSDs/by-schedule/$selectedScheduleId");
                    final res = await http.get(url, headers: {
                      "Content-Type": "application/json",
                    });
                    if (res.statusCode == 200) {
                      final data = json.decode(res.body);
                      final days = data.map((d) => {
                        "scheduleSchoolDayId": d["id"],
                        "schoolDayId": d["schoolDays"]["id"],
                        "teachingDay": d["schoolDays"]["teachingDay"],
                        "weekday": d["schoolDays"]["weekday"],
                      }).toList();
                      setState(() {
                        schoolDays = days;
                        loadingDays = false;
                      });
                      if (schoolDays.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No se encontraron días lectivos.")),
                        );
                      } else {
                        // Seleccionar automáticamente el primer día lectivo
                        selectedSchoolDayId = schoolDays.first["schoolDayId"].toString();
                        selectedDateController.text =
                        "${schoolDays.first["teachingDay"]} (${schoolDays.first["weekday"]})";

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                              Text("Días lectivos cargados y primer día seleccionado.")),
                        );
                      }
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error al conectar: $e")),
                    );
                  } finally {
                    setState(() => loadingDays = false);
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("Recargar Días Lectivos del Año"),
              ),
              const SizedBox(height: 15),
              // Campo de día lectivo y calendario
              if (selectedDateController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: selectedDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: "Día Lectivo Seleccionado",
                            prefixIcon: Icon(Icons.date_range),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_calendar, color: Colors.teal),
                        onPressed: () async {
                          if (schoolDays.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Primero recargue los días lectivos del año.")),
                            );
                            return;
                          }
                          final selectedDay = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => SchoolDaysDialog(schoolDays: schoolDays),
                          );
                          if (selectedDay != null && selectedDay.isNotEmpty) {
                            setState(() {
                              selectedSchoolDayId = selectedDay["schoolDayId"].toString();
                              selectedDateController.text =
                              "${selectedDay["teachingDay"]} (${selectedDay["weekday"]})";
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 15),
              // Abrir registro de asistencias
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors[3],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _openAssistancesDialog,
                  icon: const Icon(Icons.checklist, color: Colors.white),
                  label: const Text("Cargar Asistencias", style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
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
            "assistanceDetail": existing?["assistanceDetail"] ?? "",
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
        "status": true,
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
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: appColors[3]),
              const SizedBox(width: 8),
              const Text(
                "Registro de Asistencias",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
      content: SizedBox(
        width: screenWidth * 0.6,
        height: 420,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.indigo.shade50),
            dataRowHeight: 48,
            horizontalMargin: 12,
            columnSpacing: 10,
            columns: const [
              DataColumn(label: Text("N°", textAlign: TextAlign.center,)),
              DataColumn(label: Text("Estudiante", textAlign: TextAlign.center)),
              DataColumn(label: Text("Asistencia", textAlign: TextAlign.center)),
            ],
            rows: List.generate(students.length, (index) {
              final student = students[index];

              return DataRow(
                cells: [
                  DataCell(Text("${index + 1}")),
                  DataCell(Text(student["name"])),
                  DataCell(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: attendanceOptions.map((opt) {
                        final selected = student["assistance"] == opt;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ChoiceChip(
                            label: Text(opt,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: selected ? Colors.white : Colors.black)),
                            selected: selected,
                            selectedColor: appColors[3],
                            onSelected: (_) => _setAttendance(index, opt),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancelar", style: TextStyle(color: appColors[3])),
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

class SchoolDaysDialog extends StatelessWidget {
  final List schoolDays;
  const SchoolDaysDialog({super.key, required this.schoolDays});

  @override
  Widget build(BuildContext context) {
    if (schoolDays.isEmpty) {
      return const AlertDialog(
        content: Text("No hay días lectivos cargados."),
      );
    }

    final year = int.parse(schoolDays.first["teachingDay"].toString().substring(0, 4));
    final firstDay = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31);
    final focusedDay = DateTime.parse(schoolDays.first["teachingDay"]);

    return AlertDialog(
      title: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: appColors[3]),
              const SizedBox(width: 8),
              const Text(
                "Cambiar Día Lectivo",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: TableCalendar(
          locale: 'es_ES',
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.month,
          availableGestures: AvailableGestures.horizontalSwipe,

          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: appColors[3]),
            rightChevronIcon: Icon(Icons.chevron_right, color: appColors[3]),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            weekendStyle: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          calendarStyle: CalendarStyle(
            isTodayHighlighted: true,
            outsideDaysVisible: false,
            defaultTextStyle: const TextStyle(fontSize: 13),
            weekendTextStyle: const TextStyle(color: Colors.redAccent),
            todayDecoration: BoxDecoration(
              color: appColors[3].withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: appColors[3],
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            cellMargin: const EdgeInsets.all(2),
          ),

          enabledDayPredicate: (day) {
            final formatted = DateFormat('yyyy-MM-dd').format(day);
            return schoolDays.any((d) =>
                d["teachingDay"].toString().startsWith(formatted));
          },
          onDaySelected: (selectedDay, _) {
            final formatted = DateFormat('yyyy-MM-dd').format(selectedDay);
            final found = schoolDays.firstWhere(
                  (d) => d["teachingDay"].toString().startsWith(formatted),
              orElse: () => {},
            );

            if (found.isNotEmpty) {
              Navigator.pop(context, found);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancelar", style: TextStyle(color: appColors[3])),
        ),
      ],
    );
  }
}
