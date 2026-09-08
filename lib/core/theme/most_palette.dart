import 'package:flutter/material.dart';

/// Палитра Most. Построена от логотипа: голубой градиент на глубоком синем.
/// Собственная, не наследует цвета апстрима.
///
/// Тёмная тема — основная: приложение чаще открывают вечером и в дороге,
/// а тёмный фон меньше слепит и экономит батарею на OLED.
abstract class MostPalette {
  // Фирменный градиент со знака приложения
  static const brandLight = Color(0xFF25E4FF);
  static const brand = Color(0xFF22B8FF);
  static const brandDeep = Color(0xFF2A7BFF);

  // Смысловые цвета состояний
  static const connected = Color(0xFF34D399);
  static const connecting = Color(0xFFFBBF24);
  static const failed = Color(0xFFF87171);

  // Тёмная тема
  static const darkBackground = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF111C2E);
  static const darkSurfaceHigh = Color(0xFF16233A);
  static const darkOutline = Color(0xFF22314C);
  static const darkText = Color(0xFFE8EEF7);
  static const darkTextMuted = Color(0xFF93A4BF);

  // Светлая тема — та же логика, перевёрнутая по светлоте
  static const lightBackground = Color(0xFFF4F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFEDF2F9);
  static const lightOutline = Color(0xFFD8E1EE);
  static const lightText = Color(0xFF0E1A2B);
  static const lightTextMuted = Color(0xFF5C6B82);

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: brand,
    onPrimary: Color(0xFF04121F),
    primaryContainer: Color(0xFF123A5C),
    onPrimaryContainer: brandLight,
    secondary: brandDeep,
    onSecondary: Color(0xFFF2F7FF),
    secondaryContainer: darkSurfaceHigh,
    onSecondaryContainer: darkText,
    tertiary: connected,
    onTertiary: Color(0xFF04120C),
    error: failed,
    onError: Color(0xFF2A0A0A),
    errorContainer: Color(0xFF4A1414),
    onErrorContainer: Color(0xFFFFD9D9),
    surface: darkSurface,
    onSurface: darkText,
    surfaceContainerLowest: darkBackground,
    surfaceContainerLow: Color(0xFF0F1828),
    surfaceContainer: darkSurface,
    surfaceContainerHigh: darkSurfaceHigh,
    surfaceContainerHighest: Color(0xFF1B2C46),
    onSurfaceVariant: darkTextMuted,
    outline: darkOutline,
    outlineVariant: Color(0xFF1A2740),
    inverseSurface: lightSurface,
    onInverseSurface: lightText,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0E7FC7),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD5EEFF),
    onPrimaryContainer: Color(0xFF00344F),
    secondary: brandDeep,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE2ECFF),
    onSecondaryContainer: Color(0xFF0B2447),
    tertiary: Color(0xFF12996E),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFC4342F),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD7),
    onErrorContainer: Color(0xFF410004),
    surface: lightSurface,
    onSurface: lightText,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: lightBackground,
    surfaceContainer: lightSurfaceHigh,
    surfaceContainerHigh: Color(0xFFE4EBF5),
    surfaceContainerHighest: Color(0xFFDCE5F1),
    onSurfaceVariant: lightTextMuted,
    outline: lightOutline,
    outlineVariant: Color(0xFFE7EDF6),
    inverseSurface: darkSurface,
    onInverseSurface: darkText,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}
