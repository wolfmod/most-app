import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/theme/most_palette.dart';
import 'package:hiddify/features/app_update/data/self_update_service.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Главный экран.
///
/// Компоновка сознательно отличается от апстрима: там карточка профиля сверху
/// и круглая кнопка по центру. Здесь — вертикальная история сверху вниз:
/// крупный статус, знак-индикатор, карточка сервера и широкая кнопка действия
/// внизу, у большого пальца.
class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final connection = ref.watch(connectionNotifierProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    final status = connection.valueOrNull;
    final isConnected = status?.isConnected ?? false;
    final isBusy = status is Connecting || status is Disconnecting || connection.isLoading;

    // Раз в сутки тихо смотрим, не вышла ли новая версия: магазина у нас нет,
    // человек иначе так и останется на старой сборке.
    useEffect(() {
      Future.microtask(() async {
        final update = await ref.read(selfUpdateServiceProvider.notifier).checkDaily();
        if (update == null || !context.mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Доступна версия ${update.version}'),
            content: const Text('Скачать и установить? Система попросит подтвердить установку.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Позже')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Обновить')),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(selfUpdateServiceProvider.notifier).downloadAndInstall(update);
        }
      });
      return null;
    }, const []);

    final accent = isConnected
        ? MostPalette.connected
        : isBusy
        ? MostPalette.connecting
        : theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(profileName: activeProfile.valueOrNull?.name),
              const Gap(12),
              _StatusHeadline(isConnected: isConnected, isBusy: isBusy, accent: accent),
              const Spacer(),
              _Emblem(accent: accent, active: isConnected, busy: isBusy),
              const Spacer(),
              const _ServerCard(),
              const Gap(16),
              _ActionButton(
                isConnected: isConnected,
                isBusy: isBusy,
                onPressed: () async => ref.read(connectionNotifierProvider.notifier).toggleConnection(),
              ),
              const Gap(12),
              Text(
                isConnected
                    ? 'Весь трафик идёт через выбранный сервер'
                    : 'Нажмите, чтобы включить защищённое соединение',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Gap(8),
              Semantics(
                label: t.pages.home.quickSettings,
                child: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({this.profileName});

  final String? profileName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Assets.images.logo.image(height: 26),
        const Gap(10),
        Text(
          Constants.appName,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .2),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Профили',
          icon: const Icon(Icons.swap_horiz_rounded),
          onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview(),
        ),
        IconButton(
          tooltip: 'Быстрые настройки',
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
        ),
        IconButton(
          tooltip: 'Настройки',
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => context.goNamed('settings'),
        ),
      ],
    );
  }
}

class _StatusHeadline extends StatelessWidget {
  const _StatusHeadline({required this.isConnected, required this.isBusy, required this.accent});

  final bool isConnected;
  final bool isBusy;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = isBusy
        ? 'Подключаемся…'
        : isConnected
        ? 'Соединение защищено'
        : 'Защита выключена';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            const Gap(8),
            Text(
              isConnected ? 'ПОДКЛЮЧЕНО' : (isBusy ? 'ПОДКЛЮЧЕНИЕ' : 'ОТКЛЮЧЕНО'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const Gap(6),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
        ),
      ],
    );
  }
}

/// Знак приложения как индикатор состояния: мягкое свечение вокруг него
/// меняет цвет вместе со статусом. Заменяет собой круглую кнопку апстрима.
class _Emblem extends StatelessWidget {
  const _Emblem({required this.accent, required this.active, required this.busy});

  final Color accent;
  final bool active;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        width: 208,
        height: 208,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accent.withValues(alpha: active ? .55 : .28), width: 1.5),
          gradient: RadialGradient(
            colors: [
              accent.withValues(alpha: active ? .24 : .12),
              accent.withValues(alpha: 0),
            ],
            stops: const [0.5, 1],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 104,
            height: 104,
            child: Opacity(opacity: active ? 1 : .8, child: Assets.images.logo.image()),
          ),
        ),
      ),
    );
  }
}

/// Карточка выбранного сервера. Тап открывает список серверов.
class _ServerCard extends ConsumerWidget {
  const _ServerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final group = ref.watch(proxiesOverviewNotifierProvider).valueOrNull;

    final proxy = activeProxy.valueOrNull;
    final delay = proxy?.urlTestDelay ?? 0;

    // Активным может быть либо конкретный сервер, либо группа-балансировщик.
    // Её техническое имя («balance → round-robin») человеку ничего не говорит,
    // поэтому для группы пишем «Автовыбор», а для сервера — его название.
    final selectedTag = group?.selected ?? '';
    final selected = group?.items.where((e) => e.tag == selectedTag).firstOrNull;

    final isBalancer = (selected?.type ?? '').toLowerCase().contains('balancer') ||
        (selected == null && (proxy?.tagDisplay ?? '').contains('→'));

    final String name;
    if (selected != null && !isBalancer) {
      name = selected.tagDisplay;
    } else if (isBalancer) {
      name = 'Автовыбор сервера';
    } else if (proxy?.tagDisplay.isNotEmpty ?? false) {
      name = proxy!.tagDisplay;
    } else {
      name = 'Сервер не выбран';
    }

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.goNamed('proxies'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.public_rounded, size: 20, color: theme.colorScheme.primary),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      delay > 0 && delay < 65000
                          ? (isBalancer ? 'быстрейший из доступных · $delay мс' : 'отклик $delay мс')
                          : 'нажмите, чтобы выбрать',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Основное действие. Широкая кнопка внизу — попадать по ней одной рукой
/// удобнее, чем по круглой в середине экрана.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.isConnected, required this.isBusy, required this.onPressed});

  final bool isConnected;
  final bool isBusy;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 58,
      child: FilledButton(
        onPressed: isBusy ? null : () async => onPressed(),
        style: FilledButton.styleFrom(
          backgroundColor: isConnected ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primary,
          foregroundColor: isConnected ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        child: isBusy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
            : Text(isConnected ? 'Отключить' : 'Подключить'),
      ),
    );
  }
}
