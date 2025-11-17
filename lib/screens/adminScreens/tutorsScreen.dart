import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customDataSelection.dart';
import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/customTextFields.dart';
import 'package:http/http.dart' as http;

class TutorsScreen extends StatefulWidget {
  const TutorsScreen({super.key});

  @override
  State<TutorsScreen> createState() => _TutorsScreenState();
}

class _TutorsScreenState extends State<TutorsScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController teacherIdController = TextEditingController();
  TextEditingController gradeIdController = TextEditingController();
  TextEditingController sectionIdController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController createdAtController = TextEditingController();
  TextEditingController updatedAtController = TextEditingController();
  TextEditingController sectionDisplayController = TextEditingController();
  TextEditingController teacherDisplayController = TextEditingController();
  TextEditingController gradeDisplayController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> filteredTutorsList = [];
  List<Map<String, dynamic>> tutorsList = [];
  Map<String,dynamic>? savedTutors;
  late _TutorsDataSource _tutorsDataSource;
  int? idToEdit;
  String? token;

  Future<void> saveTutor() async {
    if(
        teacherIdController.text.trim().isEmpty ||
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

    final url = Uri.parse('${generalUrl}api/tutors/create');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "teacherId": int.parse(teacherIdController.text),
          "gradeId": int.parse(gradeIdController.text),
          "sectionId": int.parse(sectionIdController.text),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          savedTutors = data;
          idController.text = data['id'].toString();
          statusController.text = data['status'].toString();
          createdAtController.text = data['createdAt'].toString();
          updatedAtController.text = data['updatedAt'].toString();
        });
        clearTextFields();
        idToEdit = null;
        await getTutors();
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

  Future<void> getTutors() async {
    final url = Uri.parse('${generalUrl}api/tutors/list');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          tutorsList = List<Map<String, dynamic>>.from(data);
          filteredTutorsList = tutorsList;
          _tutorsDataSource = _TutorsDataSource(
            tutorsList: filteredTutorsList,
            onEdit: _handleEditTutor,
            onDelete: deleteTutor,
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

  Future<void> updateTutor () async {
    if (idToEdit == null) {
      CustomNotifications.showNotification(context, "Selecciona un horario para actualizar", color: Colors.red);
      return;
    }
    if(
        teacherIdController.text.trim().isEmpty ||
        gradeIdController.text.trim().isEmpty ||
        sectionIdController.text.trim().isEmpty
    ){
      CustomNotifications.showNotification(context, "Algunos campos aún están vacíos.", color: Colors.red);
      return;
    }

    final url = Uri.parse('${generalUrl}api/tutors/update/$idToEdit');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "teacherId": int.parse(teacherIdController.text),
          "gradeId": int.parse(gradeIdController.text),
          "sectionId": int.parse(sectionIdController.text),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clearTextFields();
          idToEdit = null;
        });
        await getTutors();
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

  Future<void> deleteTutor(int id) async {
    final url = Uri.parse('${generalUrl}api/tutors/delete/$id');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("Horario eliminado: $id");
        await getTutors();
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
    gradeIdController.clear();
    sectionIdController.clear();
    statusController.clear();
    createdAtController.clear();
    updatedAtController.clear();
    teacherDisplayController.clear();
    gradeDisplayController.clear();
    sectionDisplayController.clear();
    filterTutors("");
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

  void _handleEditTutor(Map<String, dynamic> tutors) {
    setState(() {
      idToEdit = tutors['id'];
      idController.text = tutors['id'].toString();
      sectionIdController.text = tutors['sections']['id'].toString();
      sectionDisplayController.text = '${tutors['sections']['id']} - ${tutors['sections']['seccion']}';
      teacherIdController.text = tutors['teachers']['id'].toString();
      teacherDisplayController.text = '${tutors['teachers']['id']} - ${tutors['teachers']['persons']['names']} ${tutors['teachers']['persons']['lastNames']}';
      gradeIdController.text = tutors['grades']['id'].toString();
      gradeDisplayController.text = '${tutors['grades']['id']} - ${tutors['grades']['grade']}';
      statusController.text = tutors['status'].toString();
      createdAtController.text = tutors['createdAt'].toString();
      updatedAtController.text = tutors['updatedAt'].toString();
    });
  }

  Future<void> loadTokenAndData() async {
    final savedToken = await storage.read(key: "auth_token");
    if (savedToken != null) {
      setState(() => token = savedToken);
    }
  }

  void filterTutors(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredTutorsList = tutorsList;
      } else {
        filteredTutorsList = tutorsList.where((tutor) {
          final fullName = '${tutor['teachers']['years']['year'].toString()} ${tutor['teachers']['persons']['names']} ${tutor['teachers']['persons']['lastNames']} '
              '${tutor['grades']['grade'].toString()} ${tutor['sections']['seccion']}'.toLowerCase();
          return fullName.contains(lowerQuery);
        }).toList();
      }

      _tutorsDataSource = _TutorsDataSource(
        tutorsList: filteredTutorsList,
        onEdit: _handleEditTutor,
        onDelete: deleteTutor,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    getTutors();
    _tutorsDataSource = _TutorsDataSource(
      tutorsList: tutorsList,
      onEdit: _handleEditTutor,
      onDelete: deleteTutor,
    );
    loadTokenAndData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutores', style: TextStyle(fontSize: 15, color: Colors.white),),
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
                  title: const Text('Registrar/Actualizar Tutor'),
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
                        IconButton(onPressed: saveTutor, icon: Icon(Icons.save, color: appColors[3]), tooltip: 'Guardar'),
                        IconButton(onPressed: cancelUpdate, icon: const Icon(Icons.clear_all, color: Colors.deepOrange), tooltip: 'Cancelar Actualización'),
                        IconButton(onPressed: updateTutor, icon: Icon(Icons.update, color: appColors[8]), tooltip: 'Actualizar'),
                      ],
                    ),
                  ],
                ),
              ),
              // Sección de la tabla de datos
              const SizedBox(height: 15),
              const CustomTitleWidget(
                child: Text('Tutores Registrados', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    filterTutors(value);
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
                      DataColumn(label: Text('Especialidad')),
                      DataColumn(label: Text('Grado')),
                      DataColumn(label: Text('Sección')),
                      DataColumn(label: Text('Acciones'))
                    ],
                    source: _tutorsDataSource,
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

class _TutorsDataSource extends DataTableSource {
  final List<Map<String, dynamic>> tutorsList;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  _TutorsDataSource({
    required this.tutorsList,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= tutorsList.length) {
      return null;
    }
    final tutors = tutorsList[index];
    return DataRow(
      cells: [
        DataCell(Text(tutors['id'].toString())),
        DataCell(Text('(${tutors['teachers']['years']['id']}) ${tutors['teachers']['years']['year']}')),
        DataCell(Text('(${tutors['teachers']['id']}) ${tutors['teachers']['persons']['names']} ${tutors['teachers']['persons']['lastNames']}')),
        DataCell(Text('${tutors['teachers']['courses']['course']}')),
        DataCell(Text('(${tutors['grades']['id']}) ${tutors['grades']['grade']}')),
        DataCell(Text('(${tutors['sections']['id']}) ${tutors['sections']['seccion']}')),
        DataCell(Row(
          children: [
            IconButton(
              icon: Icon(Icons.info_outline, color: appColors[9]),
              onPressed: () {},
              tooltip: 'Más Información',
            ),
            IconButton(
              icon: Icon(Icons.edit, color: appColors[3]),
              onPressed: () => onEdit(tutors),
              tooltip: 'Editar Tutor',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(tutors['id']),
              tooltip: 'Eliminar Tutor',
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => tutorsList.length;

  @override
  int get selectedRowCount => 0;
}