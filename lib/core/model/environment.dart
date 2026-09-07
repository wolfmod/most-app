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

  // Проверка обновлений выключена, пока нет своего репозитория с релизами.
  // TODO: вернуть `this == general`, когда появится форк и релизы через GitHub Actions.
  bool get allowCustomUpdateChecker => false;

  static Release read() =>
      Release.values.firstOrNullWhere((e) => e.key == const String.fromEnvironment("release")) ?? Release.general;
}
