import 'package:flutter/material.dart';
import 'package:schoolnet/utils/colors.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/customTextFields.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController courseController = TextEditingController();
  TextEditingController recurrenceController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController createdAtController = TextEditingController();
  TextEditingController updatedAtController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> filteredCoursesList = [];
  List<Map<String,dynamic>> coursesList = [];
  late _CoursesDataSource _coursesDataSource;
  Map<String, dynamic>? savedCourses;
  int? idToEdit;

  Future<void> saveCourse() async {
    if(courseController.text.trim().isEmpty){
      CustomNotifications.showNotification(context, "El nombre del curso no puede estar vacío.", color: Colors.red);
      return;
    }
    if (idToEdit != null) {
      CustomNotifications.showNotification(context, "Estás editando un grado. Cancela la edición para guardar uno nuevo.", color: Colors.red);
      return;
    }
    final url = Uri.parse('${generalUrl}api/courses/create');
    try{
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "course": courseController.text,
          "descripcion": recurrenceController.text
        }),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          savedCourses = data;
          idController.text = data['id'].toString();
          statusController.text = data['status'].toString();
          createdAtController.text = data['createdAt'].toString();
          updatedAtController.text = data['updatedAt'].toString();
        });
        clearTextFields();
        idToEdit = null;
        getCourses();
        CustomNotifications.showNotification(context, "Curso guardado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al guardar curso", color: Colors.red);
        print("Error al guardar grado: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al guardar curso: $e");
    }
  }

  Future<void> getCourses() async {
    final url = Uri.parse('${generalUrl}api/courses/list');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          coursesList = List<Map<String, dynamic>>.from(data);
          filteredCoursesList = coursesList;
          _coursesDataSource = _CoursesDataSource(
            coursesList: filteredCoursesList,
            onEdit: _handleEditCourse,
            onDelete: deleteCourse,
          );
        });
      } else {
        CustomNotifications.showNotification(context, "Error al obtener cursos", color: Colors.red);
        print("Error al obtener cursos: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al obtener curso: $e");
    }
  }

  Future<void> updateCourse () async {
    if (idToEdit == null) {
      CustomNotifications.showNotification(context, "Selecciona un curso para actualizar", color: Colors.red);
      return;
    }
    if (courseController.text.trim().isEmpty) {
      CustomNotifications.showNotification(context, "El nombre del grado no puede estar vacío.", color: Colors.red);
      return;
    }

    final url = Uri.parse('${generalUrl}api/courses/update/$idToEdit');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "course": courseController.text,
          "descripcion": recurrenceController.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clearTextFields();
          idToEdit = null;
        });
        await getCourses();
        CustomNotifications.showNotification(context, "Curso actualizado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al actualizar curso", color: Colors.red);
        print("Error al actualizar curso: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al actualizar curso: $e");
    }
  }

  Future<void> deleteCourse(int id) async {
    final url = Uri.parse('${generalUrl}api/courses/delete/$id');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("Curso eliminado: $id");
        await getCourses();
        CustomNotifications.showNotification(context, "Curso eliminado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al eliminar curso", color: Colors.red);
        print("Error al eliminar curso: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al eliminar curso: $e");
    }
  }

  void clearTextFields (){
    idController.clear();
    courseController.clear();
    recurrenceController.clear();
    statusController.clear();
    createdAtController.clear();
    updatedAtController.clear();
    filterCourses("");
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

  void _handleEditCourse(Map<String, dynamic> course) {
    setState(() {
      idToEdit = course['id'];
      idController.text = course['id'].toString();
      courseController.text = course['course'];
      recurrenceController.text = course['descripcion'].toString();
      statusController.text = course['status'].toString();
      createdAtController.text = course['createdAt'].toString();
      updatedAtController.text = course['updatedAt'].toString();
    });
  }

  void filterCourses(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredCoursesList = coursesList.where((course) {
        final nombre = '${course['course']} ${course['descripcion'].toString()}'.toLowerCase() ?? '';
        return nombre.contains(lowerQuery);
      }).toList();

      _coursesDataSource = _CoursesDataSource(
        coursesList: filteredCoursesList,
        onEdit: _handleEditCourse,
        onDelete: deleteCourse,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    getCourses();
    _coursesDataSource = _CoursesDataSource(
      coursesList: coursesList,
      onEdit: _handleEditCourse,
      onDelete: deleteCourse,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos', style: TextStyle(fontSize: 15, color: Colors.white),),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
      body: SelectableRegion(
        selectionControls: materialTextSelectionControls,
        focusNode: FocusNode(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Card(
                child: ExpansionTile(
                  title: const Text('Registrar/Actualizar Curso'),
                  subtitle: const Text('Toca para abrir el formulario'),
                  leading: const Icon(Icons.add_box),
                  childrenPadding: const EdgeInsets.all(15),
                  children: [
                    CommonInfoFields(idController: idController, statusController: statusController),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(label: "Curso", controller: courseController, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]"))]),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            label: "Recurrencia",
                            controller: recurrenceController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CommonTimestampsFields(createdAtController: createdAtController, updatedAtController: updatedAtController),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(onPressed: saveCourse, icon: Icon(Icons.save, color: appColors[3]), tooltip: 'Guardar',),
                        IconButton(onPressed: cancelUpdate, icon: const Icon(Icons.clear_all, color: Colors.deepOrange), tooltip: 'Cancelar Actualización'),
                        IconButton(onPressed: updateCourse, icon: Icon(Icons.update, color: appColors[8]), tooltip: 'Actualizar'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const CustomTitleWidget(
                child: Text('Cursos Registrados', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    filterCourses(value);
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
                      DataColumn(label: Text('Grado')),
                      DataColumn(label: Text('Recurrencia')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Creado')),
                      DataColumn(label: Text('Actualizado')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    source: _coursesDataSource,
                    rowsPerPage: 10,
                    onPageChanged: (int page) {
                      print('Page changed to: $page');
                    },
                    availableRowsPerPage: const [5, 10, 15, 20, 50],
                    showCheckboxColumn: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoursesDataSource extends DataTableSource{
  final List<Map<String, dynamic>> coursesList;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  _CoursesDataSource({
    required this.coursesList,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= coursesList.length) {
      return null;
    }
    final course = coursesList[index];
    return DataRow(
      cells: [
        DataCell(Text(course['id'].toString())),
        DataCell(Text(course['course'])),
        DataCell(Text(course['descripcion'])),
        DataCell(Text(course['status'] == true ? 'Activo' : 'Inactivo')),
        DataCell(Text(course['createdAt'].toString())),
        DataCell(Text(course['updatedAt'].toString())),
        DataCell(Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: appColors[3]),
              onPressed: () => onEdit(course),
              tooltip: 'Editar Curso',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(course['id']),
              tooltip: 'Eliminar Curso',
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => coursesList.length;

  @override
  int get selectedRowCount => 0;
}
