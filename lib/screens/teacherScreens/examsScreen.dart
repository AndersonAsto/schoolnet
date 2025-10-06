import 'package:flutter/material.dart';
import 'package:schoolnet/utils/colors.dart';

class ExamsScreen extends StatefulWidget {
  final int teacherId;
  final String token;

  const ExamsScreen({
    super.key,
    required this.teacherId,
    required this.token
  });

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  String? token;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Calificación de Exámenes - Docente ${widget.teacherId}",
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
    );
  }
}