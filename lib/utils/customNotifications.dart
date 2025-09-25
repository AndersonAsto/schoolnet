import 'package:flutter/material.dart';

class CustomNotifications {
  static void showNotification(BuildContext context, String mensaje,
      {Color color = Colors.black, Duration duracion = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: duracion,
      ),
    );
  }
}