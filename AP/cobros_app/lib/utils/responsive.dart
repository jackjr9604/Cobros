import 'package:flutter/material.dart';

class Responsive {
  // Método para saber si es móvil
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  // Método para saber si es tablet
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1100;

  // Método para saber si es escritorio
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  // Método para obtener el ancho de pantalla
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // Método para obtener el alto de pantalla
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
}
