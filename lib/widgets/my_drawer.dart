import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:anime_list/constants.dart';

/// 左側抽屜導航元件
///
/// 包含 App 名稱標題頭部和首頁、收藏、設定三個導航入口。
class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          // 抽屜頂部標題區
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primaryContainer, colorScheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.movie_filter,
                    size: 48,
                    color: colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    appTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '探索每季新番動畫',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 導航項目
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text('首頁', style: Theme.of(context).textTheme.titleMedium),
            onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).go(homeRoute);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: Text(
              favoriteTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).go(favoriteRoute);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(
              settingsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).go(settingsRoute);
            },
          ),
        ],
      ),
    );
  }
}
