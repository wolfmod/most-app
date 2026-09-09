import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/features/app_update/widget/update_tile.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AboutPage extends HookConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final appInfo = ref.watch(appInfoProvider).requireValue;

    final conditionalTiles = [
      // Обновляемся не через магазин, а со своего сервера — по коду доступа.
      if (PlatformUtils.isAndroid) const UpdateTile(),
      if (PlatformUtils.isDesktop)
        ListTile(
          title: Text(t.pages.about.openWorkingDir),
          trailing: const Icon(FluentIcons.open_folder_24_regular),
          onTap: () async {
            final path = ref.watch(appDirectoriesProvider).requireValue.workingDir.uri;
            await UriUtils.tryLaunch(path);
          },
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.about.title),
        actions: [
          PopupMenuButton(
            icon: Icon(AdaptiveIcon(context).more),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: Text(t.common.addToClipboard),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: appInfo.format()));
                  },
                ),
              ];
            },
          ),
          const Gap(8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.images.logo.image(width: 64, height: 64),
                  const Gap(16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.common.appTitle, style: Theme.of(context).textTheme.titleLarge),
                      const Gap(4),
                      Text("${t.common.version} ${appInfo.presentVersion}"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ...conditionalTiles,
              if (conditionalTiles.isNotEmpty) const Divider(),
              // Атрибуция апстрима — требование лицензии Hiddify.
              ListTile(
                title: const Text('Основано на Hiddify'),
                subtitle: const Text(Constants.upstreamUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(FluentIcons.open_24_regular),
                onTap: () async {
                  await UriUtils.tryLaunch(Uri.parse(Constants.upstreamUrl));
                },
              ),
              ListTile(
                title: Text(t.pages.about.privacyPolicy),
                trailing: const Icon(FluentIcons.open_24_regular),
                onTap: () async {
                  await UriUtils.tryLaunch(Uri.parse(Constants.privacyPolicyUrl));
                },
              ),
              ListTile(
                title: Text(t.pages.about.sourceCode),
                trailing: const Icon(FluentIcons.open_24_regular),
                onTap: () async {
                  await UriUtils.tryLaunch(Uri.parse(Constants.githubUrl));
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
