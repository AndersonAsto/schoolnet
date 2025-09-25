import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/customTextFields.dart';
import 'package:schoolnet/utils/customDataSelection.dart';

class StudentEnrollmentsScreen extends StatefulWidget {
  const StudentEnrollmentsScreen({super.key});

  @override
  State<StudentEnrollmentsScreen> createState() => _StudentEnrollmentsScreenState();
}

class _StudentEnrollmentsScreenState extends State<StudentEnrollmentsScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController studentIdController = TextEditingController();
  TextEditingController yearIdController = TextEditingController();
  TextEditingController gradeIdController = TextEditingController();
  TextEditingController sectionIdController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController createdAtController = TextEditingController();
  TextEditingController updatedAtController = TextEditingController();
  TextEditingController studentDisplayController = TextEditingController();
  TextEditingController yearDisplayController = TextEditingController();
  TextEditingController gradeDisplayController = TextEditingController();
  TextEditingController sectionDisplayController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  Map<String,dynamic>? savedStudentEnrollments;
  List<Map<String, dynamic>> studentEnrollmentsList = [];
  int? idToEdit;
  List<Map<String, dynamic>> filteredStudentEnrollments = [];
  late _StudentEnrollmentsDataSource _studentEnrollmentsDataSource;

  Future<void> saveStudentEnrollment() async {
    if(
      studentIdController.text.trim().isEmpty ||
      yearIdController.text.trim().isEmpty ||
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

    final url = Uri.parse('${apiUrl}api/studentEnrollments/create');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "studentId": int.parse(studentIdController.text),
          "yearId": int.parse(yearIdController.text),
          "gradeId": int.parse(gradeIdController.text),
          "sectionId": int.parse(sectionIdController.text)
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          savedStudentEnrollments = data;
          idController.text = data['id'].toString();
          statusController.text = data['status'].toString();
          createdAtController.text = data['createdAt'].toString();
          updatedAtController.text = data['updatedAt'].toString();
        });
        clearTextFields();
        idToEdit = null;
        await getStudentEnrollments();
        CustomNotifications.showNotification(context, "Usuario guardado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al guardar usuario", color: Colors.red);
        print("Error al guardar usuario: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al guardar usuario: $e");
    }
  }

  Future<void> getStudentEnrollments() async {
    final url = Uri.parse('${apiUrl}api/studentEnrollments/list');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          studentEnrollmentsList = List<Map<String, dynamic>>.from(data);
          filteredStudentEnrollments = studentEnrollmentsList;
          _studentEnrollmentsDataSource = _StudentEnrollmentsDataSource(
            usersList: filteredStudentEnrollments,
            onEdit: _handleEditStudentEnrollments,
            onDelete: deleteStudentEnrollments,
          );
        });
      } else {
        CustomNotifications.showNotification(context, "Error al obtener datos de usuarios", color: Colors.red);
        print("Error al obtener datos de usuarios: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al obtener datos de usuarios: $e");
    }
  }

  Future<void> updateStudentEnrollments () async {
    if (idToEdit == null) {
      CustomNotifications.showNotification(context, "Selecciona un usuario para actualizar", color: Colors.red);
      return;
    }
    if(
      studentIdController.text.trim().isEmpty ||
      yearIdController.text.trim().isEmpty ||
      gradeIdController.text.trim().isEmpty ||
      sectionIdController.text.trim().isEmpty
    ){
      CustomNotifications.showNotification(context, "Algunos campos aún están vacíos.", color: Colors.red);
      return;
    }

    final url = Uri.parse('${apiUrl}api/studentEnrollments/update/$idToEdit');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "studentId": int.parse(studentIdController.text),
          "yearId": int.parse(yearIdController.text),
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
        await getStudentEnrollments();
        CustomNotifications.showNotification(context, "Usuario actualizado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al actualizar usuario", color: Colors.red);
        print("Error al actualizar usuario: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al actualizar usuario: $e");
    }
  }

  Future<void> deleteStudentEnrollments(int id) async {
    final url = Uri.parse('${apiUrl}api/studentEnrollments/delete/$id');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("Usuario eliminado: $id");
        await getStudentEnrollments();
        CustomNotifications.showNotification(context, "Usuario eliminado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al eliminar usuario", color: Colors.red);
        print("Error al eliminar usuario: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al eliminar usuario: $e");
    }
  }

  void clearTextFields (){
    idController.clear();
    studentIdController.clear();
    yearIdController.clear();
    gradeIdController.clear();
    sectionIdController.clear();
    statusController.clear();
    createdAtController.clear();
    updatedAtController.clear();
    /*
    studentDisplayController.clear();
    yearDisplayController.clear();
    gradeDisplayController.clear();
    sectionDisplayController.clear();
    */
    filterUsers("");
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

  void _handleEditStudentEnrollments(Map<String, dynamic> user) {
    setState(() {
      idToEdit = user['id'];
      idController.text = user['id'].toString();
      studentIdController.text = user['persons']['id'].toString();
      studentDisplayController.text = '${user['persons']['id']} - ${user['persons']['names']} ${user['persons']['lastNames']}';
      yearIdController.text = user['years']['id'].toString();
      yearDisplayController.text = '${user['years']['id']} - ${user['years']['year']}';
      gradeIdController.text = user['grades']['id'].toString();
      gradeDisplayController.text = '${user['grades']['id']} - ${user['grades']['grade']}';
      sectionIdController.text = user['sections']['id'].toString();
      sectionDisplayController.text = '${user['sections']['id']} - ${user['sections']['seccion']}';
      statusController.text = user['status'].toString();
      createdAtController.text = user['createdAt'].toString();
      updatedAtController.text = user['updatedAt'].toString();
    });
  }

  void filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredStudentEnrollments = studentEnrollmentsList.where((user) {
        final nombre = '${user['persons']['names']} ${user['persons']['lastNames']} ${user['role']} ${user['userName']}'.toLowerCase();
        return nombre.contains(lowerQuery);
      }).toList();

      _studentEnrollmentsDataSource = _StudentEnrollmentsDataSource(
        usersList: filteredStudentEnrollments,
        onEdit: _handleEditStudentEnrollments,
        onDelete: deleteStudentEnrollments,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    getStudentEnrollments();
    _studentEnrollmentsDataSource = _StudentEnrollmentsDataSource(
      usersList: studentEnrollmentsList,
      onEdit: _handleEditStudentEnrollments,
      onDelete: deleteStudentEnrollments,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudiantes+', style: TextStyle(fontSize: 15, color: Colors.white),),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: materialTextSelectionControls,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: ExpansionTile(
                  title: const Text('Registrar/Actualizar Estudiante'),
                  subtitle: const Text('Toca para abrir el formulario'),
                  leading: const Icon(Icons.add_box),
                  childrenPadding: const EdgeInsets.all(16.0),
                  children: [
                    CommonInfoFields(idController: idController, statusController: statusController),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SelectionField(
                              hintText: "Seleccionar Estudiante",
                              displayController: studentDisplayController,
                              idController: studentIdController,
                              onTap: () async => await showPersonsByRole(context, studentIdController, studentDisplayController, 'Estudiante')
                          ),
                        ),
                        const SizedBox(width: 10),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SelectionField(
                            hintText: "Seleccionar Grado",
                            displayController: gradeDisplayController,
                            idController: gradeIdController,
                            onTap: () async => await showGradeSelection(context, gradeIdController, gradeDisplayController),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SelectionField(
                            hintText: "Seleccionar Sección",
                            displayController: sectionDisplayController,
                            idController: sectionIdController,
                            onTap: () async => await showSectionsSelection(context, sectionIdController, sectionDisplayController),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CommonTimestampsFields(createdAtController: createdAtController, updatedAtController: updatedAtController),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(onPressed: saveStudentEnrollment, icon: Icon(Icons.save, color: appColors[3]),),
                        IconButton(onPressed: cancelUpdate, icon: const Icon(Icons.clear_all, color: Colors.deepOrange)),
                        IconButton(onPressed: updateStudentEnrollments, icon: Icon(Icons.update, color: appColors[8])),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              const Text("Asignaciones de Docentes", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombres o apellidos',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  filterUsers(value);
                },
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                  child: PaginatedDataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('(ID) Nombres y Apellidos')),
                      DataColumn(label: Text('(ID) Año')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Creado')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    source: _studentEnrollmentsDataSource,
                    rowsPerPage: 10,
                    onPageChanged: (int page) {
                      print('Page changed to: $page');
                    },
                    availableRowsPerPage: const [5, 10, 15, 20, 50],
                    showCheckboxColumn: false, // Hide checkboxes if not needed
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

class _StudentEnrollmentsDataSource extends DataTableSource {
  final List<Map<String, dynamic>> usersList;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  _StudentEnrollmentsDataSource({
    required this.usersList,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= usersList.length) {
      return null;
    }
    final user = usersList[index];
    return DataRow(
      cells: [
        DataCell(Text(user['id'].toString())),
        DataCell(Text('(${user['persons']['id']}) ${user['persons']['names']} ${user['persons']['lastNames']}')),
        DataCell(Text('(${user['years']['id']}) ${user['years']['year']}')),
        DataCell(Text(user['status'] == true ? 'Activo' : 'Inactivo')),
        DataCell(Text(user['createdAt'].toString())),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => onEdit(user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(user['id']),
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => usersList.length;

  @override
  int get selectedRowCount => 0;
}