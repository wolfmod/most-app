import 'package:dartx/dartx.dart';

enum Environment {
  prod,
  dev;

  // This environment variable is set in the 'windows-release-zip' command
  static const isPortable = bool.fromEnvironment("portable");
}

enum Release {
  general("general"),
  // This environment variable is set in the 'android-release-aab' command
  googlePlay("google-play");

  const Release(this.key);

  final String key;

  // Обновляемся своим механизмом (SelfUpdateService), апстримовый выключен
  bool get allowCustomUpdateChecker => false;

  static Release read() =>
      Release.values.firstOrNullWhere((e) => e.key == const String.fromEnvironment("release")) ?? Release.general;
}
