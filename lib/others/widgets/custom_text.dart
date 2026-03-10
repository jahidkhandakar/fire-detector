import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String message;
  final String? icon;

  const CustomText({
    super.key, 
    required this.message,
    this.icon
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          '${icon ?? ''} $message',
          style: const TextStyle(
            fontSize: 18.0,
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}