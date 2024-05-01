import 'package:flutter/material.dart';

class SignupTextField extends StatelessWidget {
  const SignupTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
      ),
    );
  }
}