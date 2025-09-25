import 'package:flutter/material.dart';
import 'package:schoolnet/screens/teacherScreens/assistancesScreen.dart';
import 'package:schoolnet/screens/teacherScreens/qualificationsScreen.dart';
import 'package:sidebarx/sidebarx.dart';

const sidebarCanvasColor = Color(0xff3b7861); // Color de fondo del sidebar
const sidebarAccentCanvasColor = Color(0xff256d7b); // Un color más claro para el gradiente del item seleccionado
const sidebarActionColor = Color(0xff204760); // Color para el borde del item seleccionado (sin opacidad aquí)
final sidebarDivider = Divider(color: Colors.white.withOpacity(0.3), height: 1); // Divisor sutil para sidebar

class TeacherNavigationRail extends StatefulWidget {
  const TeacherNavigationRail({super.key});

  @override
  State<TeacherNavigationRail> createState() => _TeacherNavigationRailState();
}

class _TeacherNavigationRailState extends State<TeacherNavigationRail> {
  final SidebarXController _controller = SidebarXController(selectedIndex: 0, extended: true);

  final List<Widget> pages = [
    AssistancesScreen(),
    QualificationsScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarX(
            controller: _controller,
            theme: SidebarXTheme(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: sidebarCanvasColor,
                borderRadius: BorderRadius.circular(20),
              ),
              hoverColor: Colors.white.withOpacity(0.1),
              hoverTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              hoverIconTheme: const IconThemeData(
                color: Colors.white,
                size: 20,
              ),
              textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              iconTheme: IconThemeData(
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              selectedTextStyle: const TextStyle(color: Colors.white),
              selectedIconTheme: const IconThemeData(
                color: Colors.white,
                size: 20,
              ),
              selectedItemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sidebarActionColor.withOpacity(0.37),
                ),
                gradient: const LinearGradient(
                  colors: [sidebarAccentCanvasColor, sidebarCanvasColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 30,
                  )
                ],
              ),
              itemTextPadding: const EdgeInsets.only(left: 16),
              selectedItemTextPadding: const EdgeInsets.only(left: 16),
              itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sidebarCanvasColor),
              ),
              padding: const EdgeInsets.all(0),
            ),
            extendedTheme: const SidebarXTheme(
              width: 200,
              decoration: BoxDecoration(
                color: sidebarCanvasColor,
              ),
            ),
            headerDivider: sidebarDivider,
            footerDivider: sidebarDivider,
            headerBuilder: (context, extended) {
              return SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: extended
                      ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(child: Text(
                        'Bienvenido/a',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),),
                    ],
                  )
                      : const Icon(Icons.person, color: Colors.white, size: 32),
                ),
              );
            },
            items: const [
              SidebarXItem(icon: Icons.check_box_outlined, label: 'Asistencia'),
              SidebarXItem(icon: Icons.filter_list_sharp, label: 'Calificación'),
            ],
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return pages[_controller.selectedIndex];
              },
            ),
          ),
        ],
      ),
    );
  }
}