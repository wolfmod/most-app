import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/features/app_update/data/self_update_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Пункт «Проверить обновления» в разделе «О программе».
///
/// Приложение раздаётся ссылкой, магазина нет — поэтому проверяем и скачиваем
/// новую версию сами, а установку подтверждает система.
class UpdateTile extends HookConsumerWidget {
  const UpdateTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = useState(false);
    final progress = useState<double?>(null);

    Future<void> run() async {
      if (busy.value) return;
      busy.value = true;
      progress.value = null;

      final messenger = ScaffoldMessenger.of(context);
      try {
        final update = await ref.read(selfUpdateServiceProvider.notifier).check();

        if (update == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Установлена последняя версия'), duration: Duration(seconds: 3)),
          );
          return;
        }

        if (!context.mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Доступна версия ${update.version}'),
            content: Text(
              update.notes.isNotEmpty
                  ? update.notes
                  : 'Скачать обновление и установить? Система попросит подтвердить установку.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Позже')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Обновить')),
            ],
          ),
        );
        if (confirmed != true) return;

        // Без разрешения установка сорвётся уже после загрузки — спросим сразу
        if (!await ref.read(selfUpdateServiceProvider.notifier).canInstall()) {
          if (!context.mounted) return;
          final go = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Нужно разрешение'),
              content: const Text(
                'Android разрешает установку обновлений только с вашего согласия. '
                'Откройте настройки и включите установку для этого приложения, затем вернитесь назад.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Открыть настройки')),
              ],
            ),
          );
          if (go == true) {
            await ref.read(selfUpdateServiceProvider.notifier).openInstallSettings();
          }
          return;
        }

        await ref
            .read(selfUpdateServiceProvider.notifier)
            .downloadAndInstall(update, onProgress: (value) => progress.value = value);
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Не удалось обновить: $e'), duration: const Duration(seconds: 5)),
        );
      } finally {
        busy.value = false;
        progress.value = null;
      }
    }

    return ListTile(
      title: const Text('Проверить обновления'),
      subtitle: busy.value && progress.value != null
          ? Text('Загружено ${((progress.value ?? 0) * 100).toStringAsFixed(0)}%')
          : null,
      trailing: busy.value
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4, value: progress.value),
            )
          : const Icon(FluentIcons.arrow_sync_24_regular),
      onTap: run,
    );
  }
}
