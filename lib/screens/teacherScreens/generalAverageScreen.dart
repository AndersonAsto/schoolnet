import 'package:flutter/material.dart';
import 'package:schoolnet/utils/colors.dart';

class GeneralAverageScreen extends StatefulWidget {
  final int teacherId;
  final String token;

  const GeneralAverageScreen({
    super.key,
    required this.teacherId,
    required this.token
  });

  @override
  State<GeneralAverageScreen> createState() => _GeneralAverageScreenState();
}

class _GeneralAverageScreenState extends State<GeneralAverageScreen> {
  String? token;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Promedio General - Docente ${widget.teacherId}",
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: appColors[3],
      ),
    );
  }
}