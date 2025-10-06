import 'package:flutter/material.dart';
import 'package:schoolnet/utils/colors.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/customTextFields.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController gradeController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController createdAtController = TextEditingController();
  TextEditingController updatedAtController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  int? idToEdit;
  Map<String, dynamic>? savedGrades;
  late _GradesDataSource _gradesDataSource;
  List<Map<String, dynamic>> gradesList = [];
  List<Map<String, dynamic>> filteredGradesList = [];

  Future<void> saveGrade() async {
    if (gradeController.text.trim().isEmpty) {
      CustomNotifications.showNotification(context, "El nombre del grado no puede estar vacío.", color: appColors[0]);
      return;
    }
    if (idToEdit != null) {
      CustomNotifications.showNotification(context, "Estás editando un grado. Cancela la edición para guardar uno nuevo.", color: appColors[0]);
      return;
    }
    final url = Uri.parse('${generalUrl}api/grades/create');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"grade": gradeController.text}),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          savedGrades = data;
          idController.text = data['id'].toString();
          statusController.text = data['status'].toString();
          createdAtController.text = data['createdAt'].toString();
          updatedAtController.text = data['updatedAt'].toString();
        });
        clearTextFields();
        idToEdit = null;
        await getGrades();
        CustomNotifications.showNotification(context, "Grado guardado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al guardar grado", color: appColors[0]);
        print("Error al guardar grado: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: appColors[0]);
      print("Error de conexión al guardar grado: $e");
    }
  }

  Future<void> getGrades() async {
    final url = Uri.parse('${generalUrl}api/grades/list');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          gradesList = List<Map<String, dynamic>>.from(data);
          filteredGradesList = gradesList;
          _gradesDataSource = _GradesDataSource(
            gradesList: filteredGradesList,
            onEdit: _handleEditGrade,
            onDelete: deleteGrade,
          );
        });
      } else {
        CustomNotifications.showNotification(context, "Error al obtener grados", color: appColors[0]);
        print("Error al obtener grados: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: appColors[0]);
      print("Error de conexión al obtener grados: $e");
    }
  }

  Future<void> updateGrade() async {
    if (idToEdit == null) {
      CustomNotifications.showNotification(context, "Selecciona un grado para actualizar", color: appColors[0]);
      return;
    }
    if (gradeController.text.trim().isEmpty) {
      CustomNotifications.showNotification(context, "El nombre del grado no puede estar vacío.", color: appColors[0]);
      return;
    }

    final url = Uri.parse('${generalUrl}api/grades/update/$idToEdit');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"grade": gradeController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clearTextFields();
          idToEdit = null;
        });
        await getGrades();
        CustomNotifications.showNotification(context, "Grado actualizado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al actualizar grado", color: appColors[0]);
        print("Error al actualizar grado: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: appColors[0]);
      print("Error de conexión al actualizar grado: $e");
    }
  }

  Future<void> deleteGrade(int id) async {
    final url = Uri.parse('${generalUrl}api/grades/delete/$id');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("Grado eliminado: $id");
        await getGrades();
        CustomNotifications.showNotification(context, "Grado eliminado correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al eliminar grado", color: appColors[0]);
        print("Error al eliminar grado: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: appColors[0]);
      print("Error de conexión al eliminar grado: $e");
    }
  }

  void clearTextFields() {
    idController.clear();
    gradeController.clear();
    statusController.clear();
    createdAtController.clear();
    updatedAtController.clear();
    filterGrades("");
  }

  void filterGrades(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredGradesList = gradesList.where((grade) {
        final nombre = grade['grade']?.toLowerCase() ?? '';
        return nombre.contains(lowerQuery);
      }).toList();
      _gradesDataSource = _GradesDataSource(
        gradesList: filteredGradesList,
        onEdit: _handleEditGrade,
        onDelete: deleteGrade,
      );
    });
  }

  void _handleEditGrade(Map<String, dynamic> grade) {
    setState(() {
      idToEdit = grade['id'];
      idController.text = grade['id'].toString();
      gradeController.text = grade['grade'];
      statusController.text = grade['status'].toString();
      createdAtController.text = grade['createdAt'].toString();
      updatedAtController.text = grade['updatedAt'].toString();
    });
  }

  Future<void> cancelUpdate() async {
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

  @override
  void initState() {
    super.initState();
    getGrades();
    _gradesDataSource = _GradesDataSource(
      gradesList: gradesList,
      onEdit: _handleEditGrade,
      onDelete: deleteGrade,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grados', style: TextStyle(fontSize: 15, color: Colors.white),),
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
                  title: const Text('Registrar/Actualizar Grado'),
                  subtitle: const Text('Toca para abrir el formulario'),
                  leading: const Icon(Icons.add_box),
                  childrenPadding: const EdgeInsets.all(10),
                  children: [
                    CommonInfoFields(idController: idController, statusController: statusController),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: CustomTextField(label: "Grado", controller: gradeController, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]"))])
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CommonTimestampsFields(createdAtController: createdAtController, updatedAtController: updatedAtController),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(onPressed: saveGrade, icon: Icon(Icons.save, color: appColors[3]),),
                        IconButton(onPressed: cancelUpdate, icon: const Icon(Icons.clear_all, color: Colors.deepOrange)),
                        IconButton(onPressed: updateGrade, icon: Icon(Icons.update, color: appColors[8])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text("Grados Registrados", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre',
                  prefixIcon: const Icon(Icons.search, color: Colors.teal,),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  filterGrades(value);
                },
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                  child: PaginatedDataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Grado')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Creado')),
                      DataColumn(label: Text('Actualizado')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    source: _gradesDataSource,
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

class _GradesDataSource extends DataTableSource {
  final List<Map<String, dynamic>> gradesList;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  _GradesDataSource({
    required this.gradesList,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= gradesList.length) {
      return null;
    }
    final grade = gradesList[index];
    return DataRow(
      cells: [
        DataCell(Text(grade['id'].toString())),
        DataCell(Text(grade['grade'])),
        DataCell(Text(grade['status'] == true ? 'Activo' : 'Inactivo')),
        DataCell(Text(grade['createdAt'].toString())),
        DataCell(Text(grade['updatedAt'].toString())),
        DataCell(Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => onEdit(grade),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(grade['id']),
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => gradesList.length;

  @override
  int get selectedRowCount => 0;
}