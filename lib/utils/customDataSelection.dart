import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schoolnet/services/apiService.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/customTextFields.dart';

Future<void> showGenericSelection({
  required BuildContext context,
  required String title,
  String? endpoint, // Endpoint opcional
  List<Map<String, dynamic>>? localItems, // Lista local opcional
  String? token, // Token opcional
  bool useApiService = false, // Nueva flag
  bool enableSearch = true,
  required String Function(Map<String, dynamic>) displayTextBuilder,
  required Function(Map<String, dynamic>) onItemSelected,
}) async {
  try {
    List<Map<String, dynamic>> items = [];

    if (localItems != null && localItems.isNotEmpty) {
      // Emplear lista
      items = localItems;
    } else if (endpoint != null && endpoint.isNotEmpty) {
      // Método a emplear
      if (useApiService) {
        final response = await ApiService.request(endpoint);
        if (response.statusCode == 200) {
          items = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        } else {
          CustomNotifications.showNotification(context, "Error al cargar datos", color: Colors.red,);
          debugPrint("Error al cargar $title: ${response.body}");
          return;
        }
      } else {
        final url = Uri.parse('$generalUrl$endpoint');
        final response = await http.get(
          url,
          headers: token != null
              ? {"Authorization": "Bearer $token"}
              : {},
        );
        if (response.statusCode == 200) {
          items = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        } else {
          CustomNotifications.showNotification(context, "Error al cargar datos", color: Colors.red,);
          debugPrint("Error al cargar $title: ${response.body}");
          return;
        }
      }
    } else {
      CustomNotifications.showNotification(
        context,
        "No se encontraron datos para mostrar.",
        color: Colors.orange,
      );
      return;
    }

    // Búsqueda filtrada
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredItems = List.from(items);

    void applyFilter(String query) {
      final lowerQuery = query.toLowerCase();
      filteredItems = items.where((item) {
        final text = displayTextBuilder(item).toLowerCase();
        return text.contains(lowerQuery);
      }).toList();
    }
    applyFilter("");

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: AppBar(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: appColors[3],
                automaticallyImplyLeading: false,
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- NUEVO: campo de búsqueda ---
                    if (enableSearch) ...[
                      CustomInputContainer(
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              labelText: 'Buscar',
                              prefixIcon: Icon(Icons.search, color: Colors.teal),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() {
                                applyFilter(value);
                              });
                            },
                          )
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (filteredItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'No se encontraron resultados.',
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final displayText = displayTextBuilder(item);
                            return Card(
                              child: ListTile(
                                title: Text(displayText, style: const TextStyle(fontSize: 11),),
                                onTap: () {
                                  onItemSelected(item);
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } catch (e) {
    CustomNotifications.showNotification(
      context,
      "Error de conexión: $e",
      color: Colors.red,
    );
    debugPrint("Error de conexión en $title: $e");
  }
}

Future<void> showYearsSelection(BuildContext context,
    TextEditingController idCtrl, TextEditingController displayCtrl,
    {String? token}) {
  return showGenericSelection(
    context: context,
    token: token,
    useApiService: true,
    enableSearch: false,
    title: "Seleccionar Año",
    endpoint: "api/years/list",
    displayTextBuilder: (item) => "${item['year']}",
    onItemSelected: (item) {
      idCtrl.text = item['id'].toString();
      displayCtrl.text = "${item['year']}";
    },
  );
}

class SelectionField extends StatelessWidget {
  final String labelText;
  final String? token;
  final TextEditingController displayController;
  final TextEditingController? idController;
  final Future<void> Function() onTap;

  const SelectionField({
    super.key,
    required this.labelText,
    required this.displayController,
    this.idController,
    required this.onTap,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: TextField(
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              labelText: labelText,
              labelStyle: const TextStyle(fontSize: 11, color: Colors.black),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(width: 1, color: Colors.black,),
              ),
            ),
            controller: displayController,
          ),
        ),
      ),
    );
  }
}

Future<void> showGradeSelection(BuildContext context,
    TextEditingController idCtrl, TextEditingController displayCtrl) {
  return showGenericSelection(
    context: context,
    title: "Seleccionar Grado",
    endpoint: "api/grades/list",
    enableSearch: false,
    displayTextBuilder: (item) => "${item['id']} - ${item['grade']}",
    onItemSelected: (item) {
      idCtrl.text = item['id'].toString();
      displayCtrl.text = "${item['id']} - ${item['grade']}";
    },
  );
}

Future<void> showCourseSelection(BuildContext context,
    TextEditingController idCtrl, TextEditingController displayCtrl) {
  return showGenericSelection(
    context: context,
    enableSearch: false,
    title: "Seleccionar Curso",
    endpoint: "api/courses/list",
    displayTextBuilder: (item) => "${item['id']} - ${item['course']}",
    onItemSelected: (item) {
      idCtrl.text = item['id'].toString();
      displayCtrl.text = "${item['id']} - ${item['course']}";
    },
  );
}

Future<void> showSectionsSelection(BuildContext context,
    TextEditingController idCtrl, TextEditingController displayCtrl) {
  return showGenericSelection(
    context: context,
    enableSearch: false,
    title: "Seleccionar Sección",
    endpoint: "api/sections/list",
    displayTextBuilder: (item) => "${item['id']} - ${item['seccion']}",
    onItemSelected: (item) {
      idCtrl.text = item['id'].toString();
      displayCtrl.text = "${item['id']} - ${item['seccion']}";
    },
  );
}

Future<void> showTeacherSelection(BuildContext context,
    TextEditingController idCtrl, TextEditingController displayCtrl) {
  return showGenericSelection(
    context: context,
    title: "Seleccionar Docente",
    enableSearch: true,
    endpoint: "api/teachersAssignments/list",
    displayTextBuilder: (item) =>
        "${item['id']} - ${item['persons']['names']} ${item['persons']['lastNames']}",
    onItemSelected: (item) {
      idCtrl.text = item['id'].toString();
      displayCtrl.text =
          "${item['id']} - ${item['persons']['names']} ${item['persons']['lastNames']}";
    },
  );
}

Future<void> showStudentSelection(BuildContext context,
    TextEditingController idCtrl, TextEditingController displayCtrl) {
  return showGenericSelection(
      context: context,
      title: "Seleccionar Estudiante",
      endpoint: "api/studentEnrollments/list",
      enableSearch: true,
      displayTextBuilder: (item) =>
          "${item['id']} - ${item['persons']['names']} ${item['persons']['lastNames']}",
      onItemSelected: (item) {
        idCtrl.text = item['id'].toString();
        displayCtrl.text =
            "${item['id']} - ${item['persons']['names']} ${item['persons']['lastNames']}";
      });
}

Future<void> showPersonsByRole(
    BuildContext context,
    TextEditingController idCtrl,
    TextEditingController displayCtrl,
    String role) {
  return showGenericSelection(
      context: context,
      enableSearch: true,
      endpoint: "api/persons/byRole/$role",
      title: "Seleccionar $role",
      displayTextBuilder: (item) =>
          "${item['id']} - ${item['names']} ${item['lastNames']}",
      onItemSelected: (item) {
        idCtrl.text = item['id'].toString();
        displayCtrl.text =
            "${item['id']} - ${item['names']} ${item['lastNames']}";
      });
}

Future<void> showPersonsForUsersSelection(BuildContext context,
    TextEditingController idCtrl, TextEditingController displayCtrl,
    {String? newRole}) {
  return showGenericSelection(
      context: context,
      endpoint: newRole != null && newRole.isNotEmpty
          ? "api/persons/byRole/$newRole"
          : "api/persons/byPrivilegien",
      title: "Seleccionar Persona",
      displayTextBuilder: (item) =>
          "${item['id']} - ${item['names']} ${item['lastNames']} (${item['role']})",
      onItemSelected: (item) {
        idCtrl.text = item['id'].toString();
        displayCtrl.text =
            "${item['id']} - ${item['names']} ${item['lastNames']} (${item['role']})";
      });
}

showPrivilegeSelection(
  BuildContext context,
  TextEditingController ctrl, {
  required Function(String) onRoleSelected,
}) {
  return showGenericSelection(
    context: context,
    title: "Seleccionar Rol",
    enableSearch: false,
    localItems: [
      {"name": "Administrador"},
      {"name": "Docente"},
      {"name": "Apoderado"},
    ],
    displayTextBuilder: (item) => item['name'],
    onItemSelected: (item) {
      ctrl.text = item['name'];
      onRoleSelected(item['name']); // Ejecutar acción extra
    },
  );
}

showDaySelection(BuildContext context, TextEditingController ctrl) {
  return showGenericSelection(
    context: context,
    title: "Seleccionar Día",
    localItems: [
      {"name": "Lunes"},
      {"name": "Martes"},
      {"name": "Miércoles"},
      {"name": "Jueves"},
      {"name": "Viernes"},
    ],
    displayTextBuilder: (item) => item['name'],
    onItemSelected: (item) => ctrl.text = item['name'],
  );
}

showRoleSelection(BuildContext context, TextEditingController ctrl) {
  return showGenericSelection(
    context: context,
    title: "Seleccionar Rol",
    enableSearch: false,
    localItems: [
      {"name": "Administrador"},
      {"name": "Docente"},
      {"name": "Estudiante"},
      {"name": "Apoderado"},
    ],
    displayTextBuilder: (item) => item['name'],
    onItemSelected: (item) {
      ctrl.text = item['name'];
    },
  );
}
