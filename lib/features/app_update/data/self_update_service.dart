import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'self_update_service.g.dart';

/// Сведения о доступной версии, как их отдаёт сервер.
class AvailableUpdate {
  const AvailableUpdate({required this.version, required this.url, this.notes = ''});

  final String version;
  final String url;
  final String notes;
}

/// Обновление приложения без магазина.
///
/// Приложение раздаётся по ссылке, поэтому проверку и загрузку новой версии
/// делаем сами: сервер отдаёт номер версии по коду доступа, файл скачивается
/// во временную папку, дальше установку подтверждает система.
/// Полностью беззвучно обновиться вне Play нельзя — это ограничение Android.
@Riverpod(keepAlive: true)
class SelfUpdateService extends _$SelfUpdateService with InfraLogger {
  @override
  void build() {}

  static const _channel = MethodChannel("com.hiddify.app/method");
  static const _codeKey = "access_code";

  /// Код доступа сохраняется при вводе — по нему же запрашиваем обновление.
  String? get _accessCode => ref.read(sharedPreferencesProvider).requireValue.getString(_codeKey);

  static const _lastCheckKey = "update_last_check";

  /// Фоновая проверка при запуске: не чаще раза в сутки, чтобы не дёргать
  /// человека и не ходить в сеть на каждом открытии приложения.
  Future<AvailableUpdate?> checkDaily() async {
    final prefs = ref.read(sharedPreferencesProvider).requireValue;
    final last = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < const Duration(hours: 24).inMilliseconds) return null;

    try {
      final update = await check();
      await prefs.setInt(_lastCheckKey, now);
      return update;
    } catch (e) {
      loggy.debug("проверка обновления не удалась: $e");
      return null;
    }
  }

  /// Возвращает сведения о новой версии или null, если обновляться не на что.
  Future<AvailableUpdate?> check() async {
    final code = _accessCode;
    if (code == null || code.isEmpty) {
      loggy.debug("код доступа не сохранён, проверка обновления пропущена");
      return null;
    }

    final response = await Dio().get<Map<String, dynamic>>(
      "${Constants.subscriptionBaseUrl}/version/$code",
      options: Options(receiveTimeout: const Duration(seconds: 20)),
    );
    final data = response.data;
    if (response.statusCode != 200 || data == null) return null;

    final remote = (data["version"] as String? ?? "").trim();
    final url = data["url"] as String? ?? "";
    if (remote.isEmpty || url.isEmpty) return null;

    final current = ref.read(appInfoProvider).requireValue.presentVersion;
    if (!_isNewer(remote, current)) {
      loggy.debug("установлена актуальная версия ($current)");
      return null;
    }

    return AvailableUpdate(version: remote, url: url, notes: data["notes"] as String? ?? "");
  }

  /// Разрешена ли установка обновлений из приложения.
  /// Android спрашивает это отдельно, и упереться в запрет после скачивания
  /// 100+ МБ неприятно — поэтому проверяем заранее.
  Future<bool> canInstall() async {
    try {
      return await _channel.invokeMethod<bool>("can_install_apk") ?? false;
    } catch (_) {
      return true; // на всякий случай не блокируем обновление
    }
  }

  /// Открывает системный экран, где это разрешение выдаётся.
  Future<void> openInstallSettings() async {
    await _channel.invokeMethod("open_install_settings");
  }

  /// Скачивает файл обновления и открывает установку.
  /// [onProgress] — доля загруженного от 0 до 1.
  Future<void> downloadAndInstall(AvailableUpdate update, {void Function(double)? onProgress}) async {
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/most-${update.version}.apk");
    if (await file.exists()) await file.delete();

    await Dio().download(
      update.url,
      file.path,
      options: Options(receiveTimeout: const Duration(minutes: 10)),
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );

    loggy.info("обновление скачано: ${file.path}");
    await _channel.invokeMethod("install_apk", {"path": file.path});
  }

  /// Сравнение вида 1.2.10 против 1.2.9 — по числам, а не по строке.
  static bool _isNewer(String remote, String current) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();

    final r = parts(remote);
    final c = parts(current);
    for (var i = 0; i < (r.length > c.length ? r.length : c.length); i++) {
      final a = i < r.length ? r[i] : 0;
      final b = i < c.length ? c[i] : 0;
      if (a != b) return a > b;
    }
    return false;
  }
}
