import 'package:flutter/material.dart';

class CustomMessage extends StatelessWidget {
  final String message;
  final String? icon;
  //optional knobs (keeps old behavior possible)
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final EdgeInsets padding;
  final bool center;
  final TextAlign textAlign;

  const CustomMessage({
    super.key,
    required this.message,
    this.icon,
    this.fontSize = 18.0,
    this.color = Colors.deepOrange,
    this.fontWeight = FontWeight.bold,
    this.padding = const EdgeInsets.all(16.0),
    this.center = true,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      '${icon ?? ''}${icon == null ? '' : ' '}'
      '$message',
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      ),
    );

    return Padding(
      padding: padding,
      child: center ? Center(child: text) : text,
    );
  }
}
