import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Первый экран: пользователь вводит код доступа, приложение само забирает
/// настройки с сервера подписки и дальше обновляет их само.
///
/// Заменяет вводный экран апстрима (выбор региона + условия использования):
/// регион у нас всегда один, а условия — не наши.
class AccessCodePage extends HookConsumerWidget {
  const AccessCodePage({super.key});

  /// Код → полный адрес подписки. Полную ссылку тоже принимаем: удобно на отладке
  /// и на случай, если доступ выдали ссылкой.
  static String? buildSubscriptionUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    // код из панели — 32 знака hex; допускаем ввод с пробелами и в любом регистре
    final code = value.replaceAll(RegExp(r'[\s-]'), '').toLowerCase();
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(code)) return null;

    return '${Constants.subscriptionBaseUrl}/sub/$code';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = useTextEditingController();
    final isBusy = useState(false);
    final error = useState<String?>(null);

    Future<void> submit() async {
      if (isBusy.value) return;

      final url = buildSubscriptionUrl(controller.text);
      if (url == null) {
        error.value = 'Проверьте код: он состоит из 32 знаков — цифры и буквы a-f.';
        return;
      }

      isBusy.value = true;
      error.value = null;
      try {
        // Приложение делается под Россию — регион задаём сразу,
        // без обращения к внешним гео-сервисам.
        await ref.read(ConfigOptions.region.notifier).update(Region.ru);

        await ref.read(addProfileNotifierProvider.notifier).addClipboard(url);
        if (ref.read(addProfileNotifierProvider).hasError) {
          error.value = 'Не получилось загрузить настройки. Проверьте код и связь с интернетом.';
          return;
        }

        // Профиль должен стать активным сразу, иначе на главном экране нечего подключать.
        if (await ref.read(activeProfileProvider.future) == null) {
          final profiles = await ref.read(profilesNotifierProvider.future);
          if (profiles.isNotEmpty) {
            await ref.read(profilesNotifierProvider.notifier).selectActiveProfile(profiles.first.id);
          }
        }

        // код нужен и дальше: по нему приложение проверяет обновления
        final code = controller.text.trim().replaceAll(RegExp(r'[\s-]'), '').toLowerCase();
        if (RegExp(r'^[a-f0-9]{32}$').hasMatch(code)) {
          await ref.read(sharedPreferencesProvider).requireValue.setString('access_code', code);
        }

        await ref.read(Preferences.introCompleted.notifier).update(true);
      } finally {
        isBusy.value = false;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    Constants.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Gap(10),
                  Text(
                    'Введите код доступа — остальное приложение настроит само.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Gap(32),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !isBusy.value,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    style: const TextStyle(fontFamily: 'monospace', letterSpacing: .5),
                    decoration: InputDecoration(
                      labelText: 'Код доступа',
                      hintText: 'например, 4f2c…',
                      errorText: error.value,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: 'Вставить',
                        icon: const Icon(Icons.content_paste),
                        onPressed: isBusy.value
                            ? null
                            : () async {
                                final data = await Clipboard.getData(Clipboard.kTextPlain);
                                if (data?.text != null) {
                                  controller.text = data!.text!.trim();
                                  error.value = null;
                                }
                              },
                      ),
                    ),
                  ),
                  const Gap(20),
                  FilledButton(
                    onPressed: isBusy.value ? null : submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: isBusy.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('Подключить'),
                  ),
                  const Gap(24),
                  Text(
                    'Код выдаёт тот, кто открывал вам доступ. '
                    'После подключения настройки обновляются автоматически.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
