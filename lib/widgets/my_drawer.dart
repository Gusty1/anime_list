import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants.dart';

//我的抽屜導航widget
class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Drawer(
      child: ListView(
        // 修改 padding 屬性，在頂部添加狀態列高度的內距
        padding: EdgeInsets.only(top: mediaQuery.padding.top), // 只在頂部添加內距
        children: <Widget>[
          // 各個導航項目
          ListTile(
            leading: Icon(Icons.home),
            title: Text(
              '首頁',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              GoRouter.of(context).go(homeRoute);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(
              favoriteTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              GoRouter.of(context).go(favoriteRoute);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text(
              settingsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              GoRouter.of(context).go(settingsRoute);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
