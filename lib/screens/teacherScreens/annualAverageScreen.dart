import 'package:flutter/material.dart';
import 'package:schoolnet/utils/colors.dart';

class AnnualAverageScreen extends StatefulWidget {
  final int teacherId;
  final String token;

  const AnnualAverageScreen({
    super.key,
    required this.teacherId,
    required this.token
  });

  @override
  State<AnnualAverageScreen> createState() => _AnnualAverageScreenState();
}

class _AnnualAverageScreenState extends State<AnnualAverageScreen> {
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