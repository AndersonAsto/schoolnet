import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/customTextFields.dart';

class SectionsScreens extends StatefulWidget {
  const SectionsScreens({super.key});

  @override
  State<SectionsScreens> createState() => _SectionsScreensState();
}

class _SectionsScreensState extends State<SectionsScreens> {
  TextEditingController idController = TextEditingController();
  TextEditingController sectionController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController createdAtController = TextEditingController();
  TextEditingController updatedAtController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  int? idToEdit;
  Map<String, dynamic>? savedSections;
  late _SectionsDataSource _sectionsDataSource;
  List<Map<String, dynamic>> sectionsList = [];
  List<Map<String, dynamic>> filteredSectionsList = [];

  Future<void> saveSection() async {
    if (sectionController.text.trim().isEmpty) {
      CustomNotifications.showNotification(
          context, "El nombre de la sección no puede estar vacío.",
          color: appColors[0]);
      return;
    }
    if (idToEdit != null) {
      CustomNotifications.showNotification(context,
          "Estás editando una sección. Cancela la edición para guardar uno nuevo.",
          color: appColors[0]);
      return;
    }
    final url = Uri.parse('${generalUrl}api/sections/create');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"seccion": sectionController.text}),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          savedSections = data;
          idController.text = data['id'].toString();
          statusController.text = data['status'].toString();
          createdAtController.text = data['createdAt'].toString();
          updatedAtController.text = data['updatedAt'].toString();
        });
        clearTextFields();
        idToEdit = null;
        await getSections();
        CustomNotifications.showNotification(
            context, "Sección guardada correctamente",
            color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al guardar sección",
            color: appColors[0]);
        print("Error al guardar sección: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e",
          color: appColors[0]);
      print("Error de conexión al guardar sección: $e");
    }
  }

  Future<void> getSections() async {
    final url = Uri.parse('${generalUrl}api/sections/list');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          sectionsList = List<Map<String, dynamic>>.from(data);
          filteredSectionsList = sectionsList;
          _sectionsDataSource = _SectionsDataSource(
            sectionsList: filteredSectionsList,
            onEdit: _handleEditGrade,
            onDelete: deleteSection,
          );
        });
      } else {
        CustomNotifications.showNotification(context, "Error al obtener secciones",
            color: appColors[0]);
        print("Error al obtener secciones: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e",
          color: appColors[0]);
      print("Error de conexión al obtener secciones: $e");
    }
  }

  Future<void> updateSection() async {
    if (idToEdit == null) {
      CustomNotifications.showNotification(
          context, "Selecciona una sección para actualizar",
          color: appColors[0]);
      return;
    }
    if (sectionController.text.trim().isEmpty) {
      CustomNotifications.showNotification(
          context, "El nombre de la sección no puede estar vacío.",
          color: appColors[0]);
      return;
    }

    final url = Uri.parse('${generalUrl}api/sections/update/$idToEdit');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"seccion": sectionController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clearTextFields();
          idToEdit = null;
        });
        await getSections();
        CustomNotifications.showNotification(
            context, "Sección actualizada correctamente",
            color: Colors.teal);
      } else {
        CustomNotifications.showNotification(
            context, "Error al actualizar sección",
            color: appColors[0]);
        print("Error al actualizar sección: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e",
          color: appColors[0]);
      print("Error de conexión al actualizar sección: $e");
    }
  }

  Future<void> deleteSection(int id) async {
    final url = Uri.parse('${generalUrl}api/sections/delete/$id');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("Sección eliminada: $id");
        await getSections();
        CustomNotifications.showNotification(
            context, "Sección eliminada correctamente",
            color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al eliminar sección",
            color: appColors[0]);
        print("Error al eliminar sección: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e",
          color: appColors[0]);
      print("Error de conexión al eliminar sección: $e");
    }
  }

  void clearTextFields() {
    idController.clear();
    sectionController.clear();
    statusController.clear();
    createdAtController.clear();
    updatedAtController.clear();
    filterSections("");
  }

  void filterSections(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredSectionsList = sectionsList.where((section) {
        final nombre = section['seccion']?.toLowerCase() ?? '';
        return nombre.contains(lowerQuery);
      }).toList();
      _sectionsDataSource = _SectionsDataSource(
        sectionsList: filteredSectionsList,
        onEdit: _handleEditGrade,
        onDelete: deleteSection,
      );
    });
  }

  void _handleEditGrade(Map<String, dynamic> grade) {
    setState(() {
      idToEdit = grade['id'];
      idController.text = grade['id'].toString();
      sectionController.text = grade['seccion'];
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
      CustomNotifications.showNotification(context, "Edición cancelada.",
          color: Colors.orange);
    } else {
      CustomNotifications.showNotification(
          context, "No hay edición activa para cancelar.",
          color: Colors.blueGrey);
    }
  }

  @override
  void initState() {
    super.initState();
    getSections();
    _sectionsDataSource = _SectionsDataSource(
      sectionsList: sectionsList,
      onEdit: _handleEditGrade,
      onDelete: deleteSection,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secciones', style: TextStyle(fontSize: 15, color: Colors.white),),
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
              // Card con ExpansionTile para el formulario
              Card(
                child: ExpansionTile(
                  title: const Text('Registrar/Actualizar Sección'),
                  subtitle: const Text('Toca para abrir el formulario'),
                  leading: const Icon(Icons.add_box),
                  childrenPadding: const EdgeInsets.all(15),
                  children: [
                    CommonInfoFields(idController: idController, statusController: statusController),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: "Sección",
                            controller: sectionController,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]"))]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CommonTimestampsFields(
                        createdAtController: createdAtController,
                        updatedAtController: updatedAtController),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(onPressed: saveSection, icon: Icon(Icons.save, color: appColors[3]), tooltip: 'Guardar'),
                        IconButton(onPressed: cancelUpdate, icon: const Icon(Icons.clear_all, color: Colors.deepOrange), tooltip: 'Cancelar Actualización'),
                        IconButton(onPressed: updateSection, icon: Icon(Icons.update, color: appColors[8]), tooltip: 'Actualizar'),
                      ],
                    ),
                  ],
                ),
              ),
              // Sección de la tabla de datos
              const SizedBox(height: 15),
              const CustomTitleWidget(
                child: Text('Secciones Registradas', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    filterSections(value);
                  },
                ),
              ),
              const SizedBox(height: 15),
              SingleChildScrollView(
                  child: ConstrainedBox(
                constraints:
                    BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                child: PaginatedDataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Sección')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Creado')),
                    DataColumn(label: Text('Actualizado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  source: _sectionsDataSource,
                  rowsPerPage: 5,
                  onPageChanged: (int page) {
                    if (kDebugMode) {
                      print('Page changed to: $page');
                    }
                  },
                  availableRowsPerPage: const [5, 10, 15, 20, 50],
                  showCheckboxColumn: false,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionsDataSource extends DataTableSource {
  final List<Map<String, dynamic>> sectionsList;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  _SectionsDataSource({
    required this.sectionsList,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= sectionsList.length) {
      return null;
    }
    final grade = sectionsList[index];
    return DataRow(
      cells: [
        DataCell(Text(grade['id'].toString())),
        DataCell(Text(grade['seccion'])),
        DataCell(Text(grade['status'] == true ? 'Activo' : 'Inactivo')),
        DataCell(Text(grade['createdAt'].toString())),
        DataCell(Text(grade['updatedAt'].toString())),
        DataCell(Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: appColors[3]),
              onPressed: () => onEdit(grade),
              tooltip: 'Editar Sección',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(grade['id']),
              tooltip: 'Eliminar Sección',
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => sectionsList.length;

  @override
  int get selectedRowCount => 0;
}
