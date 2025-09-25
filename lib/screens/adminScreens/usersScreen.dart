import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customTextFields.dart';
import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/customDataSelection.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController personIdController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController roleController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController createdAtController = TextEditingController();
  TextEditingController updatedAtController = TextEditingController();
  TextEditingController personDisplayController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  Map<String,dynamic>? savedUsers;
  List<Map<String, dynamic>> usersList = [];
  int? idToEdit;
  bool _showPassword = false;
  List<Map<String, dynamic>> filteredUsersList = [];
  late _UsersDataSource _usersDataSource;

  Future<void> saveUser() async {
    if(
    personIdController.text.trim().isEmpty ||
        userNameController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        roleController.text.trim().isEmpty
    ){
      CustomNotifications.showNotification(context, "Algunos campos aún están vacíos.", color: Colors.red);
      return;
    }

    if (idToEdit != null) {
      CustomNotifications.showNotification(context, "Estás editando un registro. Cancela la edición para guardar uno nuevo.", color: Colors.red);
      return;
    }

    final url = Uri.parse('${apiUrl}api/users/create');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "personId": int.parse(personIdController.text),
          "userName": userNameController.text,
          "passwordHash": passwordController.text,
          "role": roleController.text,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          savedUsers = data;
          idController.text = data['id'].toString();
          statusController.text = data['status'].toString();
          createdAtController.text = data['createdAt'].toString();
          updatedAtController.text = data['updatedAt'].toString();
        });
        clearTextFields();
        idToEdit = null;
        await getUsers(); // Await to ensure users are reloaded before notification
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

  Future<void> getUsers({ String? role }) async {
    final url = role != null && role.isNotEmpty
        ? Uri.parse('${apiUrl}api/users/byRole/$role')
        : Uri.parse('${apiUrl}api/users/list');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          usersList = List<Map<String, dynamic>>.from(data);
          filteredUsersList = usersList;
          _usersDataSource = _UsersDataSource(
            usersList: filteredUsersList,
            onEdit: _handleEditUser,
            onDelete: deleteUser,
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

  Future<void> updateUser () async {
    if (idToEdit == null) {
      CustomNotifications.showNotification(context, "Selecciona un usuario para actualizar", color: Colors.red);
      return;
    }
    if(
        personIdController.text.trim().isEmpty ||
        userNameController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        roleController.text.trim().isEmpty
    ){
      CustomNotifications.showNotification(context, "Algunos campos aún están vacíos.", color: Colors.red);
      return;
    }

    final url = Uri.parse('${apiUrl}api/users/update/$idToEdit');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "personId": int.parse(personIdController.text),
          "userName": userNameController.text,
          "passwordHash": passwordController.text,
          "role": roleController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          clearTextFields();
          idToEdit = null;
        });
        await getUsers();
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

  Future<void> deleteUser(int id) async {
    final url = Uri.parse('${apiUrl}api/users/delete/$id');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("Usuario eliminado: $id");
        await getUsers();
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
    personIdController.clear();
    userNameController.clear();
    passwordController.clear();
    roleController.clear();
    statusController.clear();
    createdAtController.clear();
    updatedAtController.clear();
    personDisplayController.clear();
    filterUsers("");
  }

  Future<void> cancelUpdate () async {
    if (idToEdit != null) {
      setState(() {
        clearTextFields();
        idToEdit = null;
      });
      await getUsers();
      CustomNotifications.showNotification(context, "Edición cancelada.", color: Colors.orange);
    } else {
      CustomNotifications.showNotification(context, "No hay edición activa para cancelar.", color: Colors.blueGrey);
    }
  }

  void _handleEditUser(Map<String, dynamic> user) async {
    setState(() {
      idToEdit = user['id'];
      idController.text = user['id'].toString();
      personIdController.text = user['persons']['id'].toString();
      personDisplayController.text = '${user['persons']['id']} - ${user['persons']['names']} ${user['persons']['lastNames']}';
      userNameController.text = user['userName'];
      passwordController.text = user['passwordHash'];
      roleController.text = user['role'];
      statusController.text = user['status'].toString();
      createdAtController.text = user['createdAt'].toString();
      updatedAtController.text = user['updatedAt'].toString();
    });

    // Filtrar datos según rol del usuario
    await getUsers(role: user['role']);
  }

  void filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredUsersList = usersList.where((user) {
        final nombre = '${user['persons']['names']} ${user['persons']['lastNames']} ${user['role']} ${user['userName']}'.toLowerCase();
        return nombre.contains(lowerQuery);
      }).toList();

      _usersDataSource = _UsersDataSource(
        usersList: filteredUsersList,
        onEdit: _handleEditUser,
        onDelete: deleteUser,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    getUsers();
    _usersDataSource = _UsersDataSource(
      usersList: usersList,
      onEdit: _handleEditUser,
      onDelete: deleteUser,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios', style: TextStyle(fontSize: 15, color: Colors.white),),
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
                  title: const Text('Registrar/Actualizar Usuario'),
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
                              hintText: "Seleccionar Persona",
                              displayController: personDisplayController,
                              idController: personIdController,
                              onTap: () async => await showPersonsForUsersSelection(context, personIdController, personDisplayController, newRole: roleController.text.isNotEmpty ? roleController.text : null)
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SelectionField(
                            hintText: "Seleccionar Rol",
                            displayController: roleController,
                            onTap: () async {
                              await showPrivilegeSelection(
                                context,
                                roleController,
                                onRoleSelected: (selectedRole) {
                                  getUsers(role: selectedRole);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(label: "Nombre de Usuario", controller: userNameController),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 36, // Increased height for better tap target
                            child: TextField(
                              controller: passwordController,
                              obscureText: !_showPassword,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: "Contraseña",
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                enabled: idToEdit != null? false : true,
                                suffixIcon: IconButton(
                                  icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () {
                                    setState(() {
                                      _showPassword = !_showPassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder( // Added border
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
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
                        IconButton(onPressed: saveUser, icon: Icon(Icons.save, color: appColors[3]),),
                        IconButton(onPressed: cancelUpdate, icon: const Icon(Icons.clear_all, color: Colors.deepOrange)),
                        IconButton(onPressed: updateUser, icon: Icon(Icons.update, color: appColors[8])),
                      ],
                    ),
                  ],
                ),
              ),
              // Sección de la tabla de datos
              const Divider(height: 20),
              const Text("Usuarios Registrados", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      DataColumn(label: Text('Usuario')),
                      DataColumn(label: Text('Rol')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Creado')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    source: _usersDataSource, // Our custom data source
                    rowsPerPage: 10, // Set 15 rows per page
                    onPageChanged: (int page) {
                      // Optional: You can add logic here if you need to do something when the page changes
                      print('Page changed to: $page');
                    },
                    // Optional: Adjust available rows per page options
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

class _UsersDataSource extends DataTableSource {
  final List<Map<String, dynamic>> usersList;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  _UsersDataSource({
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
        DataCell(Text(user['userName'])),
        DataCell(Text(user['role'])),
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