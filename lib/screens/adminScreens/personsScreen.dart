import 'package:flutter/material.dart';
import 'package:schoolnet/utils/colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/customTextFields.dart';
import 'package:schoolnet/utils/customDataSelection.dart';

class PersonsScreen extends StatefulWidget {
  const PersonsScreen({super.key});

  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController dniController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController roleController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController createdAtController = TextEditingController();
  TextEditingController updatedAtController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  int? idToEdit;
  Map<String, dynamic>? savedPersons;
  late _PersonsDataSource _personsDataSource;
  List<Map<String, dynamic>> personsList = [];
  List<Map<String, dynamic>> filteredPersonsList = [];

  Future<void> savePerson() async {
    if (
      nameController.text.trim().isEmpty ||
      lastNameController.text.trim().isEmpty ||
      dniController.text.trim().isEmpty ||
      emailController.text.trim().isEmpty ||
      phoneController.text.trim().isEmpty ||
      roleController.text.trim().isEmpty
    ){
      CustomNotifications.showNotification(context, "Algunos de los campos aún están vacíos.", color: Colors.red);
      return;
    }

    if (idToEdit != null) {
      CustomNotifications.showNotification(context, "Estás editando un registro. Cancela la edición para guardar uno nuevo.", color: Colors.red);
      return;
    }

    final url = Uri.parse('${generalUrl}api/persons/create');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "names": nameController.text,
          "lastNames": lastNameController.text,
          "dni": dniController.text,
          "email": emailController.text,
          "phone": phoneController.text,
          "role": roleController.text
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          savedPersons = data;
          idController.text = data['id'].toString();
          statusController.text = data['status'].toString();
          createdAtController.text = data['createdAt'].toString();
          updatedAtController.text = data['updatedAt'].toString();
        });
        clearTextFields();
        idToEdit = null;
        await getPersons();
        CustomNotifications.showNotification(context, "Persona guardada correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al guardar persona", color: Colors.red);
        print("Error al guardar persona: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al guardar persona: $e");
    }
  }

  Future<void> getPersons() async {
    final url = Uri.parse('${generalUrl}api/persons/list');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          personsList = List<Map<String, dynamic>>.from(data);
          filteredPersonsList = personsList;
          _personsDataSource = _PersonsDataSource(
            personsList: filteredPersonsList,
            onEdit: _handleEditPerson,
            onDelete: deletePerson,
          );
        });
      } else {
        CustomNotifications.showNotification(context, "Error al obtener datos de personas", color: Colors.red);
        print("Error al obtener datos de personas: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al obtener datos de personas: $e");
    }
  }

  Future<void> updatePerson () async {
    if (idToEdit == null) {
      CustomNotifications.showNotification(context, "Selecciona una persona para actualizar", color: Colors.red);
      return;
    }
    if (
      nameController.text.trim().isEmpty ||
      lastNameController.text.trim().isEmpty ||
      dniController.text.trim().isEmpty ||
      emailController.text.trim().isEmpty ||
      phoneController.text.trim().isEmpty ||
      roleController.text.trim().isEmpty
    ){
      CustomNotifications.showNotification(context, "Algunos de los campos aún están vacíos.", color: Colors.red);
      return;
    }

    final url = Uri.parse('${generalUrl}api/persons/update/$idToEdit');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "names": nameController.text,
          "lastNames": lastNameController.text,
          "dni": dniController.text,
          "email": emailController.text,
          "phone": phoneController.text,
          "role": roleController.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clearTextFields();
          idToEdit = null;
        });
        await getPersons();
        CustomNotifications.showNotification(context, "Persona actualizada correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al actualizar persona", color: Colors.red);
        print("Error al actualizar persona: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al actualizar persona: $e");
    }
  }

  Future<void> deletePerson(int id) async {
    final url = Uri.parse('${generalUrl}api/persons/delete/$id');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("Persona removida: $id");
        await getPersons();
        CustomNotifications.showNotification(context, "Persona eliminada correctamente", color: Colors.teal);
      } else {
        CustomNotifications.showNotification(context, "Error al remover persona", color: Colors.red);
        print("Error al remover persona: ${response.body}");
      }
    } catch (e) {
      CustomNotifications.showNotification(context, "Error de conexión: $e", color: Colors.red);
      print("Error de conexión al remover persona: $e");
    }
  }

  void clearTextFields (){
    idController.clear();
    nameController.clear();
    lastNameController.clear();
    dniController.clear();
    emailController.clear();
    phoneController.clear();
    roleController.clear();
    statusController.clear();
    createdAtController.clear();
    updatedAtController.clear();
    filterPersons("");
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

  void _handleEditPerson(Map<String, dynamic> person) {
    setState(() {
      idToEdit = person['id'];
      idController.text = person['id'].toString();
      nameController.text = person['names'];
      lastNameController.text = person['lastNames'];
      dniController.text = person['dni'];
      emailController.text = person['email'];
      phoneController.text = person['phone'];
      roleController.text = person['role'];
      statusController.text = person['status'].toString();
      createdAtController.text = person['createdAt'].toString();
      updatedAtController.text = person['updatedAt'].toString();
    });
  }

  void filterPersons(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredPersonsList = personsList;
      } else {
        filteredPersonsList = personsList.where((person) {
          final fullName = '${person['names']} ${person['lastNames']} ${person['dni'].toString()} ${person['email']} ${person['phone'].toString()}'.toLowerCase();
          return fullName.contains(lowerQuery);
        }).toList();
      }
      _personsDataSource = _PersonsDataSource(
        personsList: filteredPersonsList,
        onEdit: _handleEditPerson,
        onDelete: deletePerson,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    getPersons();
    _personsDataSource = _PersonsDataSource(
      personsList: personsList,
      onEdit: _handleEditPerson,
      onDelete: deletePerson,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personas', style: TextStyle(fontSize: 15, color: Colors.white),),
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
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                margin: const EdgeInsets.only(bottom: 20),
                child: ExpansionTile(
                  title: const Text('Registrar/Actualizar Persona'),
                  subtitle: const Text('Toca para abrir el formulario'),
                  leading: const Icon(Icons.add_box),
                  childrenPadding: const EdgeInsets.all(16.0),
                  children: [
                    CustomTextField(
                      label: "Correo",
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9@._-]")),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SelectionField(
                            hintText: "Seleccionar Rol",
                            displayController: roleController,
                            onTap: () async => await showRoleSelection(context, roleController),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: "DNI",
                            controller: dniController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            label: "Teléfono",
                            controller: phoneController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
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
                        IconButton(onPressed: savePerson, icon: Icon(Icons.save, color: appColors[3]),),
                        IconButton(onPressed: cancelUpdate, icon: const Icon(Icons.clear_all, color: Colors.deepOrange)),
                        IconButton(onPressed: updatePerson, icon: Icon(Icons.update, color: appColors[8])),
                      ],
                    ),
                  ],
                ),
              ),
              // Sección de la tabla de datos
              const Divider(height: 20),
              const Text("Personas Registradas", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre',
                  prefixIcon: Icon(Icons.search, color: Colors.teal,),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  filterPersons(value);
                },
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                  child: PaginatedDataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Nombres y Apellidos')),
                      DataColumn(label: Text('DNI')),
                      DataColumn(label: Text('Teléfono')),
                      DataColumn(label: Text('Correo')),
                      DataColumn(label: Text('Rol*')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Creado')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    source: _personsDataSource,
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

class _PersonsDataSource extends DataTableSource {
  final List<Map<String, dynamic>> personsList;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  _PersonsDataSource({
    required this.personsList,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= personsList.length) {
      return null;
    }
    final person = personsList[index];
    return DataRow(
      cells: [
        DataCell(Text(person['id'].toString())),
        DataCell(Text('${person['names']} ${person['lastNames']}')),
        DataCell(Text('${person['dni']}')),
        DataCell(Text('${person['phone']}')),
        DataCell(Text('${person['email']}')),
        DataCell(Text('${person['role']}')),
        DataCell(Text(person['status'] == true ? 'Activo' : 'Inactivo')),
        DataCell(Text(person['createdAt'].toString())),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => onEdit(person),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(person['id']),
            ),
          ],
        )),
      ],
    );
  }
  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => personsList.length;

  @override
  int get selectedRowCount => 0;
}