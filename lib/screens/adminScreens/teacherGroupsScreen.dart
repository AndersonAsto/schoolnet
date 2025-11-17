import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/customTextFields.dart';
import 'package:http/http.dart' as http;

class TeacherGroupsScreen extends StatefulWidget {
  const TeacherGroupsScreen({super.key});

  @override
  State<TeacherGroupsScreen> createState() => _TeacherGroupsScreenState();
}

class _TeacherGroupsScreenState extends State<TeacherGroupsScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController teacherIdController = TextEditingController();
  TextEditingController yearIdController = TextEditingController();
  TextEditingController courseIdController = TextEditingController();
  TextEditingController gradeIdController = TextEditingController();
  TextEditingController sectionIdController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController createdAtController = TextEditingController();
  TextEditingController updatedAtController = TextEditingController();
  TextEditingController teacherDisplayController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();
  TextEditingController courseDisplayController = TextEditingController();
  TextEditingController gradeDisplayController = TextEditingController();
  TextEditingController sectionDisplayController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> filteredTeacherGroupsList = [];
  List<Map<String, dynamic>> teacherGroupsList = [];
  Map<String,dynamic>? savedTeacherGroups;
  late _TeacherGroupsDataSource _teacherGroupsDataSource;
  int? idToEdit;
  String? token;

  Future<void> saveTeacherGroup() async {
    if(
        yearIdController.text.trim().isEmpty ||
        teacherIdController.text.trim().isEmpty ||
        courseIdController.text.trim().isEmpty ||
        gradeIdController.text.trim().isEmpty ||
        sectionIdController.text.trim().isEmpty
    ){
      CustomNotifications.showNotification(context, "Algunos campos aún están vacíos.", color: Colors.red);
      return;
    }

    if (idToEdit != null) {
      CustomNotifications.showNotification(context, "Estás editando un registro. Cancela la edición para guardar uno nuevo.", color: Colors.red);
      return;
    }

    final url = Uri.parse('${generalUrl}api/teacherGroups/create');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "yearId": int.parse(yearIdController.text),
          "teacherAssignmentId": int.parse(teacherIdController.text),
          "courseId": int.parse(courseIdController.text),
          "gradeId": int.parse(gradeIdController.text),
          "sectionId": int.parse(sectionIdController.text)
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          savedTeacherGroups = data;
          idController.text = data['id'].toString();
          statusController.text = data['status'].toString();
          createdAtController.text = data['createdAt'].toString();
          updatedAtController.text = data['updatedAt'].toString();
        });
        clearTextFields();
        idToEdit = null;
        await getTeacherGroups();
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

  Future<void> getTeacherGroups() async {
    final url = Uri.parse('${generalUrl}api/teacherGroups/list');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          teacherGroupsList = List<Map<String, dynamic>>.from(data);
          // Update the DataTableSource with the new data
          filteredTeacherGroupsList = teacherGroupsList;
          _teacherGroupsDataSource = _TeacherGroupsDataSource(
            teacherGroupsList: filteredTeacherGroupsList,
            onEdit: _handleEditTeacherGroup,
            onDelete: deleteTeacherGroup,
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

  Future<void> updateTeacherGroup () async {
    if (idToEdit == null) {
      CustomNotifications.showNotification(context, "Selecciona un horario para actualizar", color: Colors.red);
      return;
    }
    if(
        yearIdController.text.trim().isEmpty ||
        teacherIdController.text.trim().isEmpty ||
        courseIdController.text.trim().isEmpty ||
        gradeIdController.text.trim().isEmpty ||
        sectionIdController.text.trim().isEmpty
    ){
      CustomNotifications.showNotification(context, "Algunos campos aún están vacíos.", color: Colors.red);
      return;
    }

    final url = Uri.parse('${generalUrl}api/teacherGroups/update/$idToEdit');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "yearId": int.parse(yearIdController.text),
          "teacherAssignmentId": int.parse(teacherIdController.text),
          "courseId": int.parse(courseIdController.text),
          "gradeId": int.parse(gradeIdController.text),
          "sectionId": int.parse(sectionIdController.text)
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clearTextFields();
          idToEdit = null;
        });
        await getTeacherGroups();
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

  Future<void> deleteTeacherGroup(int id) async {
    final url = Uri.parse('${generalUrl}api/teacherGroups/delete/$id');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("Horario eliminado: $id");
        await getTeacherGroups();
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
    statusController.clear();
    createdAtController.clear();
    updatedAtController.clear();
    teacherDisplayController.clear();
    yearDisplayController.clear();
    sectionDisplayController.clear();
    courseDisplayController.clear();
    gradeDisplayController.clear();
    filterTeacherGroups("");
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

  void _handleEditTeacherGroup(Map<String, dynamic> teacherGroup) {
    setState(() {
      idToEdit = teacherGroup['id'];
      idController.text = teacherGroup['id'].toString();
      yearIdController.text = teacherGroup['years']['id'].toString();
      yearDisplayController.text = '${teacherGroup['years']['id']} - ${teacherGroup['years']['year']}';
      sectionIdController.text = teacherGroup['sections']['id'].toString();
      sectionDisplayController.text = '${teacherGroup['sections']['id']} - ${teacherGroup['sections']['seccion']}';
      teacherIdController.text = teacherGroup['teacherassignments']['id'].toString();
      teacherDisplayController.text = '${teacherGroup['teacherassignments']['id']} - ${teacherGroup['teacherassignments']['persons']['names']} ${teacherGroup['teacherassignments']['persons']['lastNames']}';
      courseIdController.text = teacherGroup['courses']['id'].toString();
      courseDisplayController.text = '${teacherGroup['courses']['id']} - ${teacherGroup['courses']['course']}';
      gradeIdController.text = teacherGroup['grades']['id'].toString();
      gradeDisplayController.text = '${teacherGroup['grades']['id']} - ${teacherGroup['grades']['grade']}';
      statusController.text = teacherGroup['status'].toString();
      createdAtController.text = teacherGroup['createdAt'].toString();
      updatedAtController.text = teacherGroup['updatedAt'].toString();
    });
  }

  void filterTeacherGroups(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredTeacherGroupsList = teacherGroupsList;
      } else {
        filteredTeacherGroupsList = teacherGroupsList.where((teacherGroup) {
          final fullName = '${teacherGroup['years']['year'].toString()} ${teacherGroup['teacherassignments']['persons']['names']} ${teacherGroup['teacherassignments']['persons']['lastNames']} '
              '${teacherGroup['courses']['course']} ${teacherGroup['grades']['grade'].toString()} ${teacherGroup['sections']['seccion']}'.toLowerCase();
          return fullName.contains(lowerQuery);
        }).toList();
      }

      _teacherGroupsDataSource = _TeacherGroupsDataSource(
        teacherGroupsList: filteredTeacherGroupsList,
        onEdit: _handleEditTeacherGroup,
        onDelete: deleteTeacherGroup,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    getTeacherGroups();
    _teacherGroupsDataSource = _TeacherGroupsDataSource(
      teacherGroupsList: teacherGroupsList,
      onEdit: _handleEditTeacherGroup,
      onDelete: deleteTeacherGroup,
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
        title: const Text('Grupos de Docentes', style: TextStyle(fontSize: 15, color: Colors.white),),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Card(
              child: ExpansionTile(
                title: const Text('Registrar/Actualizar Grupo de Docente'),
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
                              labelText: "Seleccionar Curso",
                              displayController: courseDisplayController,
                              idController: courseIdController,
                              onTap: () async => await showCourseSelection(context, courseIdController, courseDisplayController),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SelectionField(
                              labelText: "Seleccionar Grado",
                              displayController: gradeDisplayController,
                              idController: gradeIdController,
                              onTap: () async => await showGradeSelection(context, gradeIdController, gradeDisplayController),
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  CommonTimestampsFields(createdAtController: createdAtController, updatedAtController: updatedAtController),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(onPressed: saveTeacherGroup, icon: Icon(Icons.save, color: appColors[3]), tooltip: 'Guardar'),
                      IconButton(onPressed: cancelUpdate, icon: const Icon(Icons.clear_all, color: Colors.deepOrange), tooltip: 'Cancelar Actualización'),
                      IconButton(onPressed: updateTeacherGroup, icon: Icon(Icons.update, color: appColors[8]), tooltip: 'Actualizar'),
                    ],
                  ),
                ],
              ),
            ),
            // Sección de la tabla de datos
            const SizedBox(height: 15),
            const CustomTitleWidget(
              child: Text('Grupos de Docentes Registrados', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
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
                  filterTeacherGroups(value);
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
                    //DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones'))
                  ],
                  source: _teacherGroupsDataSource,
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
    );
  }
}

class _TeacherGroupsDataSource extends DataTableSource {
  final List<Map<String, dynamic>> teacherGroupsList;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  _TeacherGroupsDataSource({
    required this.teacherGroupsList,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= teacherGroupsList.length) {
      return null;
    }
    final teacherGroup = teacherGroupsList[index];
    return DataRow(
      cells: [
        DataCell(Text(teacherGroup['id'].toString())),
        DataCell(Text('(${teacherGroup['years']['id']}) ${teacherGroup['years']['year']}')),
        DataCell(Text('(${teacherGroup['teacherassignments']['id']}) ${teacherGroup['teacherassignments']['persons']['names']} ${teacherGroup['teacherassignments']['persons']['lastNames']}')),
        DataCell(Text('(${teacherGroup['courses']['id']}) ${teacherGroup['courses']['course']}')),
        DataCell(Text('(${teacherGroup['grades']['id']}) ${teacherGroup['grades']['grade']}')),
        DataCell(Text('(${teacherGroup['sections']['id']}) ${teacherGroup['sections']['seccion']}')),
        DataCell(Row(
          children: [
            IconButton(
              icon: Icon(Icons.info_outline, color: appColors[9]),
              onPressed: () {},
              tooltip: 'Más Información',
            ),
            IconButton(
              icon: Icon(Icons.edit, color: appColors[3]),
              onPressed: () => onEdit(teacherGroup),
              tooltip: 'Editar Horario',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(teacherGroup['id']),
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
  int get rowCount => teacherGroupsList.length;

  @override
  int get selectedRowCount => 0;
}
