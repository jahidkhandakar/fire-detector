import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String routeName;
  final String buttonText;
  final String promptText;

  const AuthButton({
    super.key,
    required this.routeName,
    required this.buttonText,
    required this.promptText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "$promptText",
          style: TextStyle(color: Colors.grey[700]),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, routeName);
          },
          child: Text(
            buttonText,
            style: TextStyle(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
