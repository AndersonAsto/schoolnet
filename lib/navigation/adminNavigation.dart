import 'package:flutter/material.dart';
import 'package:schoolnet/screens/adminScreens/academicPerformanceScreen.dart';
import 'package:schoolnet/screens/adminScreens/coursesScreen.dart';
import 'package:schoolnet/screens/adminScreens/gradesScreen.dart';
import 'package:schoolnet/screens/adminScreens/holidaysScreen.dart';
import 'package:schoolnet/screens/adminScreens/parentAssignmentsScreen.dart';
import 'package:schoolnet/screens/adminScreens/personsScreen.dart';
import 'package:schoolnet/screens/adminScreens/schedulesScreen.dart';
import 'package:schoolnet/screens/adminScreens/schoolDaysByScheduleScreen.dart';
import 'package:schoolnet/screens/adminScreens/studentEnrollmentsScreen.dart';
import 'package:schoolnet/screens/adminScreens/teacherAssignmentsScreen.dart';
import 'package:schoolnet/screens/adminScreens/teacherGroupsScreen.dart';
import 'package:schoolnet/screens/adminScreens/schoolDaysScreen.dart';
import 'package:schoolnet/screens/adminScreens/sectionsScreen.dart';
import 'package:schoolnet/screens/adminScreens/teachingBlocksScreen.dart';
import 'package:schoolnet/screens/adminScreens/tutorsScreen.dart';
import 'package:schoolnet/screens/adminScreens/usersScreen.dart';
import 'package:schoolnet/screens/adminScreens/yearsScreen.dart';
import 'package:sidebarx/sidebarx.dart';

const sidebarCanvasColor = Color(0xff3b7861); // Color de fondo del sidebar
const sidebarAccentCanvasColor = Color(0xff256d7b); // Un color más claro para el gradiente del item seleccionado
const sidebarActionColor = Color(0xff204760); // Color para el borde del item seleccionado (sin opacidad aquí)
final sidebarDivider = Divider(color: Colors.white.withOpacity(0.3), height: 1); // Divisor sutil para sidebar

class AdminNavigationRail extends StatefulWidget {
  const AdminNavigationRail({super.key});

  @override
  State<AdminNavigationRail> createState() => _AdminNavigationRailState();
}

class _AdminNavigationRailState extends State<AdminNavigationRail> {
  final SidebarXController _controller = SidebarXController(selectedIndex: 0, extended: true);

  final List<Widget> pages = [
    YearsScreen(),
    TeachingBlocksScreen(),
    HolidaysScreen(),
    TeachingDaysScreen(),
    SectionsScreens(),
    GradesScreen(),
    CoursesScreen(),
    PersonsScreen(),
    UsersScreen(),
    TeachersAssignmentsScreen(),
    TeacherGroupsScreen(),
    StudentEnrollmentsScreen(),
    ParentAssignmentsScreen(),
    SchedulesScreen(),
    SchoolDaysByScheduleScreen(),
    TutorsScreen(),
    AcademicPerformanceScreen()
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
                      Flexible(child: Text('Bienvenido/a', style: TextStyle(color: Colors.white, fontSize: 15),),),
                    ],
                  )
                      : const Icon(Icons.person, color: Colors.white, size: 32),
                ),
              );
            },
            items: const [
              SidebarXItem(icon: Icons.date_range, label: 'Años'),
              SidebarXItem(icon: Icons.table_chart, label: 'Bloques Lectivos'),
              SidebarXItem(icon: Icons.view_day, label: 'Días Feriados'),
              SidebarXItem(icon: Icons.schedule, label: 'Días Lectivos'),
              SidebarXItem(icon: Icons.safety_divider, label: 'Secciones'),
              SidebarXItem(icon: Icons.list_sharp, label: 'Grados'),
              SidebarXItem(icon: Icons.book, label: 'Cursos'),
              SidebarXItem(icon: Icons.group, label: 'Personas'),
              SidebarXItem(icon: Icons.person_pin, label: 'Usuarios'),
              SidebarXItem(icon: Icons.work, label: 'Docentes+'),
              SidebarXItem(icon: Icons.groups, label: 'Grupos'),
              SidebarXItem(icon: Icons.border_color_outlined, label: 'Estudiantes+'),
              SidebarXItem(icon: Icons.family_restroom, label: 'Apoderados+'),
              SidebarXItem(icon: Icons.schedule, label: 'Horarios'),
              SidebarXItem(icon: Icons.schema, label: 'Días/Horarios'),
              SidebarXItem(icon: Icons.personal_injury_rounded, label: 'Tutores'),
              SidebarXItem(icon: Icons.check_box_outlined, label: 'Rendimiento'),
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