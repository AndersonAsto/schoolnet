import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:schoolnet/utils/colors.dart';

class CommonInfoFields extends StatelessWidget {
  final TextEditingController idController;
  final TextEditingController statusController;

  const CommonInfoFields({
    super.key,
    required this.idController,
    required this.statusController,
  });

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
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                labelText: "Código",
                labelStyle: const TextStyle(fontSize: 11, color: Colors.black),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                labelText: "Estado",
                labelStyle: const TextStyle(fontSize: 11, color: Colors.black),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
    super.key,
    required this.createdAtController,
    required this.updatedAtController,
  });

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
                labelStyle: const TextStyle(fontSize: 11, color: Colors.black),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
              style: const TextStyle(fontSize: 12),
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
                labelStyle: const TextStyle(fontSize: 11, color: Colors.black),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
              style: const TextStyle(fontSize: 12),
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
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child:
        SizedBox(
          height: 36,
          child: TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              labelText: label,
              labelStyle: const TextStyle(fontSize: 11, color: Colors.black),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(width: 1, color: Colors.black,),
              ),
            ),
            style: const TextStyle(fontSize: 12),
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            readOnly: readOnly,
            onTap: onTap,
          ),
        ),
        ),
      ],
    );
  }
}

class CustomInputContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const CustomInputContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CustomTitleWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const CustomTitleWidget({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: appColors[3],
        borderRadius: BorderRadius.circular(10),
      ),
      height: 40,
      alignment: Alignment.center,
      child: child,
    );
  }
}

class CustomElevatedButtonIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const CustomElevatedButtonIcon({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: appColors[3],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      label: Text(label, style: const TextStyle(color: Colors.white),),
    );
  }
}
