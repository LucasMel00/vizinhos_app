import 'package:flutter/material.dart';

class LoginOptionButton extends StatelessWidget {
  final String text;
  final Widget iconWidget;
  final VoidCallback? onPressed;

  LoginOptionButton({required this.text, required this.iconWidget, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: iconWidget,
        label: Text(
          text,
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: const Color.fromARGB(255, 145, 141, 141)),
        ),
      ),
    );
  }
}
