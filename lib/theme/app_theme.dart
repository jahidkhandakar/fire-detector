import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3:
          true,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.orange,

      ).copyWith(
        primary: Colors.orangeAccent,
        secondary: Colors.deepOrange, 
        tertiary: Colors.deepOrangeAccent,
        // You can also override other scheme colors if desired:
        // primaryContainer, secondaryContainer, background, surface, etc.
      ),
      //*_________________AppBar___________________*//
      appBarTheme: AppBarTheme(
        backgroundColor:
            Colors.deepOrange, // example: using secondary for AppBar
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      //*_________________Buttons_________________*//
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange, // uses secondary color
          foregroundColor: Colors.white,
        ),
      ),
      //*_________________TextTheme_________________*//
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: Colors.deepOrange,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
    );
  }

  //*____________________________Gradients___________________________*//
  static LinearGradient get fireGradient => const LinearGradient(
    colors: [Color(0xFFFFA53E), Color(0xFFFF512F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static LinearGradient get oceanGradient => const LinearGradient(
    colors: [Color(0xFF00BFFF), Color(0xFF1E90FF), Color(0xFF87CEFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
