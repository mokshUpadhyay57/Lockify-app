import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';


class MyTextField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool readOnly;

  const MyTextField({
    super.key, 
    required this.icon, 
    required this.label,
    required this.controller, 
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 25),
      child: TextField(
        readOnly: readOnly,
        controller: controller,
        obscureText: label == 'Confirm Password' || label == 'Password' ? true : false,
        style: TextStyle(color: readOnly ? AppColors.grey : AppColors.primaryPurple),
        enabled: !readOnly,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 240, 202, 202)),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          disabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 240, 202, 202)),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryPurple, width: 1.0),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          prefixIcon: Icon(icon, size: 20, color: readOnly ? AppColors.grey : AppColors.purple400,),
          hintText: label,
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 16),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        ),
      ),
    );
  }
}

