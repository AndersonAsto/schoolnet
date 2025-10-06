import 'package:flutter/material.dart';
import 'package:schoolnet/utils/colors.dart';

class TeachingBlockAveragesScreen extends StatefulWidget {
  final int teacherId;
  final String token;

  const TeachingBlockAveragesScreen({
    super.key,
    required this.teacherId,
    required this.token
  });

  @override
  State<TeachingBlockAveragesScreen> createState() => _TeachingBlockAveragesScreenState();
}

class _TeachingBlockAveragesScreenState extends State<TeachingBlockAveragesScreen> {
  String? token;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Calificación de Bloque Lectivo - Docente ${widget.teacherId}",
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
    );
  }
}