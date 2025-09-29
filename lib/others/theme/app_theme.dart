import 'package:flutter/material.dart';

class AppTheme {
  //_________________________Theme Data_________________________//
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepOrange,
        brightness: Brightness.light,
      ),

      //_______________________AppBar Theme_______________________//
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),

      //_______________________Button Theme_______________________//
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
      ),

      //_______________________Text Theme_______________________//
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.deepOrange,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(color: Colors.white),
      ),
    );
  }


  //___________________________Gradients_______________________________//
  static const LinearGradient fireGradient = LinearGradient(
    colors: [Color(0xFFFFA53E), Color(0xFFFF512F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient oceanGradient = LinearGradient(
    colors: [Color(0xFF00BFFF), Color(0xFF1E90FF), Color(0xFF87CEFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );


}
