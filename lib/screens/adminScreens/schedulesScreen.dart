import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/customTextFields.dart';
import 'package:schoolnet/utils/customDataSelection.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController teacherIdController = TextEditingController();
  TextEditingController courseIdController = TextEditingController();
  TextEditingController gradeIdController = TextEditingController();
  TextEditingController yearIdController = TextEditingController();
  TextEditingController sectionIdController = TextEditingController();
  TextEditingController weekdayController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController createdAtController = TextEditingController();
  TextEditingController updatedAtController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();
  TextEditingController sectionDisplayController = TextEditingController();
  TextEditingController teacherDisplayController = TextEditingController();
  TextEditingController courseDisplayController = TextEditingController();
  TextEditingController gradeDisplayController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> filteredSchedulesList = [];
  List<Map<String, dynamic>> schedulesList = [];
  Map<String,dynamic>? savedSchedules;
  late _SchedulesDataSource _schedulesDataSource;
  int? idToEdit;
  String? token;

  Future<void> saveSchedule() async {
    if(
        yearIdController.text.trim().isEmpty ||
        teacherIdController.text.trim().isEmpty ||
        courseIdController.text.trim().isEmpty ||
        gradeIdController.text.trim().isEmpty ||
        sectionIdController.text.trim().isEmpty ||
        weekdayController.text.trim().isEmpty ||
        startTimeController.text.trim().isEmpty ||
        endTimeController.text.trim().isEmpty
    ){
      CustomNotifications.showNotification(context, "Algunos campos aún están vacíos.", color: Colors.red);
      return;
    }

    if (idToEdit != null) {
      CustomNotifications.showNotification(context, "Estás editando un registro. Cancela la edición para guardar uno nuevo.", color: Colors.red);
      return;
    }

    final url = Uri.parse('${generalUrl}api/schedules/create');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "yearId": int.parse(yearIdController.text),
          "teacherId": int.parse(teacherIdController.text),
          "courseId": int.parse(courseIdController.text),
          "gradeId": int.parse(gradeIdController.text),
          "sectionId": int.parse(sectionIdController.text),
          "weekday": weekdayController.text,
          "startTime": startTimeController.text,
          "endTime": endTimeController.text,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          savedSchedules = data;
          idController.text = data['id'].toString();
          statusController.text = data['status'].toString();
          createdAtController.text = data['createdAt'].toString();
          updatedAtController.text = data['updatedAt'].toString();
        });
        clearTextFields();
        idToEdit = null;
        await getSchedules(); // Await to ensure schedules are reloaded before notification
        CustomNotifications.showNotification(context, "Horario guardado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al guardar horario", color: Colors.red);
        print("Error al guardar horario: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al guardar horario: $e");
    }
  }

  Future<void> getSchedules() async {
    final url = Uri.parse('${generalUrl}api/schedules/list');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          schedulesList = List<Map<String, dynamic>>.from(data);
          // Update the DataTableSource with the new data
          filteredSchedulesList = schedulesList;
          _schedulesDataSource = _SchedulesDataSource(
            schedulesList: filteredSchedulesList,
            onEdit: _handleEditSchedule,
            onDelete: deleteSchedule,
          );
        });
      } else {
        CustomNotifications.showNotification(context, "Error al obtener datos de horarios", color: Colors.red);
        print("Error al obtener datos de horarios: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al obtener datos de horarios: $e");
    }
  }

  Future<void> updateSchedule () async {
    if (idToEdit == null) {
      CustomNotifications.showNotification(context, "Selecciona un horario para actualizar", color: Colors.red);
      return;
    }
    if(
      yearIdController.text.trim().isEmpty ||
      teacherIdController.text.trim().isEmpty ||
      courseIdController.text.trim().isEmpty ||
      gradeIdController.text.trim().isEmpty ||
      sectionIdController.text.trim().isEmpty ||
      weekdayController.text.trim().isEmpty ||
      startTimeController.text.trim().isEmpty ||
      endTimeController.text.trim().isEmpty
    ){
      CustomNotifications.showNotification(context, "Algunos campos aún están vacíos.", color: Colors.red);
      return;
    }

    final url = Uri.parse('${generalUrl}api/schedules/update/$idToEdit');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "yearId": int.parse(yearIdController.text),
          "teacherId": int.parse(teacherIdController.text),
          "courseId": int.parse(courseIdController.text),
          "gradeId": int.parse(gradeIdController.text),
          "sectionId": int.parse(sectionIdController.text),
          "weekday": weekdayController.text,
          "startTime": startTimeController.text,
          "endTime": endTimeController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clearTextFields();
          idToEdit = null;
        });
        await getSchedules();
        CustomNotifications.showNotification(context, "Horario actualizado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al actualizar horario", color: Colors.red);
        print("Error al actualizar horario: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al actualizar horario: $e");
    }
  }

  Future<void> deleteSchedule(int id) async {
    final url = Uri.parse('${generalUrl}api/schedules/delete/$id');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("Horario eliminado: $id");
        await getSchedules();
        CustomNotifications.showNotification(context, "Horario eliminado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al eliminar horario", color: Colors.red);
        print("Error al eliminar horario: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al eliminar horario: $e");
    }
  }

  void clearTextFields (){
    idController.clear();
    teacherIdController.clear();
    sectionIdController.clear();
    yearIdController.clear();
    courseIdController.clear();
    gradeIdController.clear();
    weekdayController.clear();
    startTimeController.clear();
    endTimeController.clear();
    statusController.clear();
    createdAtController.clear();
    updatedAtController.clear();
    teacherDisplayController.clear();
    yearDisplayController.clear();
    sectionDisplayController.clear();
    courseDisplayController.clear();
    gradeDisplayController.clear();
    filterSchedules("");
  }

  Future<void> cancelUpdate () async {
    if (idToEdit != null) {
      setState(() {
        clearTextFields();
        idToEdit = null;
      });
      CustomNotifications.showNotification(context, "Edición cancelada.", color: Colors.orange);
    } else {
      CustomNotifications.showNotification(context, "No hay edición activa para cancelar.", color: Colors.blueGrey);
    }
  }

  void _handleEditSchedule(Map<String, dynamic> schedule) {
    setState(() {
      idToEdit = schedule['id'];
      idController.text = schedule['id'].toString();
      yearIdController.text = schedule['years']['id'].toString();
      yearDisplayController.text = '${schedule['years']['id']} - ${schedule['years']['year']}';
      sectionIdController.text = schedule['sections']['id'].toString();
      sectionDisplayController.text = '${schedule['sections']['id']} - ${schedule['sections']['seccion']}';
      teacherIdController.text = schedule['teachers']['id'].toString();
      teacherDisplayController.text = '${schedule['teachers']['id']} - ${schedule['teachers']['persons']['names']} ${schedule['teachers']['persons']['lastNames']}';
      courseIdController.text = schedule['courses']['id'].toString();
      courseDisplayController.text = '${schedule['courses']['id']} - ${schedule['courses']['course']}';
      gradeIdController.text = schedule['grades']['id'].toString();
      gradeDisplayController.text = '${schedule['grades']['id']} - ${schedule['grades']['grade']}';
      weekdayController.text = schedule['weekday'];
      startTimeController.text = schedule['startTime'];
      endTimeController.text = schedule['endTime'];
      statusController.text = schedule['status'].toString();
      createdAtController.text = schedule['createdAt'].toString();
      updatedAtController.text = schedule['updatedAt'].toString();
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute:00";
  }

  void filterSchedules(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredSchedulesList = schedulesList;
      } else {
        filteredSchedulesList = schedulesList.where((schedule) {
          final fullName = '${schedule['years']['year'].toString()} ${schedule['teachers']['persons']['names']} ${schedule['teachers']['persons']['lastNames']} '
              '${schedule['courses']['course']} ${schedule['grades']['grade'].toString()} ${schedule['sections']['seccion']}'
              '${schedule['weekday']} ${schedule['startTime'].toString()} ${schedule['endTime'].toString()}'.toLowerCase();
          return fullName.contains(lowerQuery);
        }).toList();
      }

      _schedulesDataSource = _SchedulesDataSource(
        schedulesList: filteredSchedulesList,
        onEdit: _handleEditSchedule,
        onDelete: deleteSchedule,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    getSchedules();
    _schedulesDataSource = _SchedulesDataSource(
      schedulesList: schedulesList,
      onEdit: _handleEditSchedule,
      onDelete: deleteSchedule,
    );
    loadTokenAndData();
  }

  Future<void> loadTokenAndData() async {
    final savedToken = await storage.read(key: "auth_token");
    if (savedToken != null) {
      setState(() => token = savedToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios', style: TextStyle(fontSize: 15, color: Colors.white),),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: materialTextSelectionControls,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Card(
                child: ExpansionTile(
                  title: const Text('Registrar/Actualizar Horario'),
                  subtitle: const Text('Toca para abrir el formulario'),
                  leading: const Icon(Icons.add_box),
                  childrenPadding: const EdgeInsets.all(15),
                  children: [
                    CommonInfoFields(idController: idController, statusController: statusController),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SelectionField(
                                labelText: "Seleccionar Docente",
                                displayController: teacherDisplayController,
                                idController: teacherIdController,
                                onTap: () async => await showTeacherSelection(context, teacherIdController, teacherDisplayController),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectionField(
                                labelText: "Seleccionar Día",
                                displayController: weekdayController,
                                onTap: () async => await showDaySelection(context, weekdayController),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SelectionField(
                                labelText: "Seleccionar Año",
                                displayController: yearDisplayController,
                                idController: yearIdController,
                                token: token,
                                onTap: () async => await showYearsSelection(context, yearIdController, yearDisplayController, token: token),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectionField(
                                labelText: "Seleccionar Sección",
                                displayController: sectionDisplayController,
                                idController: sectionIdController,
                                onTap: () async => await showSectionsSelection(context, sectionIdController, sectionDisplayController),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SelectionField(
                                labelText: "Seleccionar Curso",
                                displayController: courseDisplayController,
                                idController: courseIdController,
                                onTap: () async => await showCourseSelection(context, courseIdController, courseDisplayController),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectionField(
                                labelText: "Seleccionar Grado",
                                displayController: gradeDisplayController,
                                idController: gradeIdController,
                                onTap: () async => await showGradeSelection(context, gradeIdController, gradeDisplayController),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: SizedBox(
                              height: 36,
                              child: TextField(
                                controller: startTimeController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  labelText: 'Hora de Inicio',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(width: 1, color: Colors.black,),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 13),
                                onTap: () async {
                                  TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    startTimeController.text = _formatTime(picked);
                                  }
                                },
                              ),
                            ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: TextField(
                              controller: endTimeController,
                              style: const TextStyle(fontSize: 13),
                              readOnly: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[100],
                                labelText: 'Hora de Finalización',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(width: 1, color: Colors.black,),
                                ),
                              ),
                              onTap: () async {
                                TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  endTimeController.text = _formatTime(picked);
                                }
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    CommonTimestampsFields(createdAtController: createdAtController, updatedAtController: updatedAtController),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(onPressed: saveSchedule, icon: Icon(Icons.save, color: appColors[3]), tooltip: 'Guardar'),
                        IconButton(onPressed: cancelUpdate, icon: const Icon(Icons.clear_all, color: Colors.deepOrange), tooltip: 'Cancelar Actualización'),
                        IconButton(onPressed: updateSchedule, icon: Icon(Icons.update, color: appColors[8]), tooltip: 'Actualizar'),
                      ],
                    ),
                  ],
                ),
              ),
              // Sección de la tabla de datos
              const SizedBox(height: 15),
              const CustomTitleWidget(
                child: Text('Horarios Registrados', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 15),
              CustomInputContainer(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar',
                    prefixIcon: Icon(Icons.search, color: Colors.teal),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    filterSchedules(value);
                  },
                ),
              ),
              const SizedBox(height: 15),
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                  child: PaginatedDataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Año')),
                      DataColumn(label: Text('Docente')),
                      DataColumn(label: Text('Curso')),
                      DataColumn(label: Text('Grado')),
                      DataColumn(label: Text('Sección')),
                      DataColumn(label: Text('Día')),
                      DataColumn(label: Text('Hora Inicio')),
                      DataColumn(label: Text('Hora Fin')),
                      //DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Acciones'))
                    ],
                    source: _schedulesDataSource,
                    rowsPerPage: 10,
                    onPageChanged: (int page) {
                      if (kDebugMode) {
                        print('Página cambiada a: $page');
                      }
                    },
                    availableRowsPerPage: const [5, 10, 15, 20, 50],
                    showCheckboxColumn: false,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _SchedulesDataSource extends DataTableSource {
  final List<Map<String, dynamic>> schedulesList;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  _SchedulesDataSource({
    required this.schedulesList,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= schedulesList.length) {
      return null;
    }
    final schedule = schedulesList[index];
    return DataRow(
      cells: [
        DataCell(Text(schedule['id'].toString())),
        DataCell(Text('(${schedule['years']['id']}) ${schedule['years']['year']}')),
        DataCell(Text('(${schedule['teachers']['id']}) ${schedule['teachers']['persons']['names']} ${schedule['teachers']['persons']['lastNames']}')),
        DataCell(Text('(${schedule['courses']['id']}) ${schedule['courses']['course']}')),
        DataCell(Text('(${schedule['grades']['id']}) ${schedule['grades']['grade']}')),
        DataCell(Text('(${schedule['sections']['id']}) ${schedule['sections']['seccion']}')),
        DataCell(Text(schedule['weekday'])),
        DataCell(Text(schedule['startTime'])),
        DataCell(Text(schedule['endTime'])),
        //DataCell(Text(schedule['status'] == true ? 'Activo' : 'Inactivo')),
        DataCell(Row(
          children: [
            IconButton(
              icon: Icon(Icons.info_outline, color: appColors[9]),
              onPressed: () {},
              tooltip: 'Más Información',
            ),
            IconButton(
              icon: Icon(Icons.edit, color: appColors[3]),
              onPressed: () => onEdit(schedule),
              tooltip: 'Editar Horario',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(schedule['id']),
              tooltip: 'Eliminar Horario',
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => schedulesList.length;

  @override
  int get selectedRowCount => 0;
}
