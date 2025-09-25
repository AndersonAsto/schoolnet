import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommonInfoFields extends StatelessWidget {
  final TextEditingController idController;
  final TextEditingController statusController;

  const CommonInfoFields({
    Key? key,
    required this.idController,
    required this.statusController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: idController,
              enabled: false,
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: "Código",
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 1,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: statusController,
              enabled: false,
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: "Estado",
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 1,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CommonTimestampsFields extends StatelessWidget {
  final TextEditingController createdAtController;
  final TextEditingController updatedAtController;

  const CommonTimestampsFields({
    Key? key,
    required this.createdAtController,
    required this.updatedAtController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                labelText: "Creado el...",
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 1,
                    color: Colors.black,
                  ),
                ),
              ),
              controller: createdAtController,
              style: TextStyle(fontSize: 13),
              enabled: false,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                labelText: "Actualizado el...",
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 1,
                    color: Colors.black,
                  ),
                ),
              ),
              controller: updatedAtController,
              style: TextStyle(fontSize: 13),
              enabled: false,
            ),
          ),
        ),
      ],
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child:
        SizedBox(
          height: 36,
          child: TextField(
            decoration: InputDecoration(
              labelText: label,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  width: 1,
                  color: Colors.black,
                ),
              ),
            ),
            style: TextStyle(fontSize: 13),
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
          ),
        ),
        ),
      ],
    );
  }
}