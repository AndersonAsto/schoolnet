import 'package:schoolnet/utils/customNotifications.dart';
import 'package:schoolnet/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';

Future<void> showGenericSelection({
  required BuildContext context,
  required String title,
  String? endpoint, // opcional
  List<Map<String, dynamic>>? localItems, // opcional
  required String Function(Map<String, dynamic>) displayTextBuilder,
  required Function(Map<String, dynamic>) onItemSelected,
}) async {
  try {
    List<Map<String, dynamic>> items = [];

    if (localItems != null && localItems.isNotEmpty) {
      // Usar lista local directamente
      items = localItems;
    } else if (endpoint != null && endpoint.isNotEmpty) {
      // Cargar datos desde API
      final url = Uri.parse('$apiUrl$endpoint');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        items = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        CustomNotifications.showNotification(
          context,
          "Error al cargar datos",
          color: Colors.red,
        );
        debugPrint("Error al cargar $title: ${response.body}");
        return;
      }
    } else {
      // No hay fuente de datos
      CustomNotifications.showNotification(
        context,
        "No se encontraron datos para mostrar",
        color: Colors.orange,
      );
      return;
    }

    // Mostrar diálogo
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: AppBar(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.0),
                bottomRight: Radius.circular(16.0),
              ),
            ),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            backgroundColor: appColors[3],
            automaticallyImplyLeading: false,
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final displayText = displayTextBuilder(item);

                return Card(
                  child: ListTile(
                    title: Text(displayText),
                    onTap: () {
                      onItemSelected(item);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
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

Future<void> showGradeSelection(BuildContext context, TextEditingController idCtrl, TextEditingController displayCtrl) {
  return showGenericSelection(
    context: context,
    title: "Seleccionar Grado",
    endpoint: "api/grades/list",
    displayTextBuilder: (item) => "${item['id']} - ${item['grade']}",
    onItemSelected: (item) {
      idCtrl.text = item['id'].toString();
      displayCtrl.text = "${item['id']} - ${item['grade']}";
    },
  );
}

Future<void> showCourseSelection(BuildContext context, TextEditingController idCtrl, TextEditingController displayCtrl) {
  return showGenericSelection(
    context: context,
    title: "Seleccionar Curso",
    endpoint: "api/courses/list",
    displayTextBuilder: (item) => "${item['id']} - ${item['course']}",
    onItemSelected: (item) {
      idCtrl.text = item['id'].toString();
      displayCtrl.text = "${item['id']} - ${item['course']}";
    },
  );
}

Future<void> showSectionsSelection(BuildContext context, TextEditingController idCtrl, TextEditingController displayCtrl) {
  return showGenericSelection(
    context: context,
    title: "Seleccionar Sección",
    endpoint: "api/sections/list",
    displayTextBuilder: (item) => "${item['id']} - ${item['seccion']}",
    onItemSelected: (item) {
      idCtrl.text = item['id'].toString();
      displayCtrl.text = "${item['id']} - ${item['seccion']}";
    },
  );
}

Future<void> showYearsSelection(BuildContext context, TextEditingController idCtrl, TextEditingController displayCtrl) {
  return showGenericSelection(
    context: context,
    title: "Seleccionar Año",
    endpoint: "api/years/list",
    displayTextBuilder: (item) => "${item['id']} - ${item['year']}",
    onItemSelected: (item) {
      idCtrl.text = item['id'].toString();
      displayCtrl.text = "${item['id']} - ${item['year']}";
    },
  );
}

Future<void> showTeacherSelection(BuildContext context, TextEditingController idCtrl, TextEditingController displayCtrl) {
  return showGenericSelection(
    context: context,
    title: "Seleccionar Docente",
    endpoint: "api/teachersAssignments/list",
    displayTextBuilder: (item) => "${item['id']} - ${item['persons']['names']} ${item['persons']['lastNames']}",
    onItemSelected: (item) {
      idCtrl.text = item['id'].toString();
      displayCtrl.text = "${item['id']} - ${item['persons']['names']} ${item['persons']['lastNames']}";
    },
  );
}

Future<void> showStudentSelection(BuildContext context, TextEditingController idCtrl, TextEditingController displayCtrl) {
  return showGenericSelection(
      context: context,
      title: "Seleccionar Estudiante",
      endpoint: "api/studentEnrollments/list",
      displayTextBuilder: (item) => "${item['id']} - ${item['persons']['names']} ${item['persons']['lastNames']}",
      onItemSelected: (item) {
        idCtrl.text = item['id'].toString();
        displayCtrl.text = "${item['id']} - ${item['persons']['names']} ${item['persons']['lastNames']}";
      }
  );
}

Future<void> showPersonsByRole(BuildContext context, TextEditingController idCtrl, TextEditingController displayCtrl, String role) {
  return showGenericSelection(
      context: context,
      endpoint: "api/persons/byRole/$role",
      title: "Seleccionar $role",
      displayTextBuilder: (item) => "${item['id']} - ${item['names']} ${item['lastNames']}",
      onItemSelected: (item) {
        idCtrl.text = item['id'].toString();
        displayCtrl.text = "${item['id']} - ${item['names']} ${item['lastNames']}";
      }
  );
}

Future<void> showPersonsForUsersSelection(BuildContext context, TextEditingController idCtrl, TextEditingController displayCtrl, {String? newRole}) {
  return showGenericSelection(
      context: context,
      endpoint: newRole != null && newRole.isNotEmpty ? "api/persons/byRole/$newRole": "api/persons/byPrivilegien",
      title: "Seleccionar Persona",
      displayTextBuilder: (item) => "${item['id']} - ${item['names']} ${item['lastNames']} (${item['role']})",
      onItemSelected: (item) {
        idCtrl.text = item['id'].toString();
        displayCtrl.text = "${item['id']} - ${item['names']} ${item['lastNames']} (${item['role']})";
      }
  );
}

showPrivilegeSelection(
    BuildContext context,
    TextEditingController ctrl, {
      required Function(String) onRoleSelected,
    }) {
  return showGenericSelection(
    context: context,
    title: "Seleccionar Rol",
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

class SelectionField extends StatelessWidget {
  final String hintText;
  final TextEditingController displayController;
  final TextEditingController? idController;
  final Future<void> Function() onTap;

  const SelectionField({
    super.key,
    required this.hintText,
    required this.displayController,
    this.idController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: TextField(
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            controller: displayController,
          ),
        ),
      ),
    );
  }
}
