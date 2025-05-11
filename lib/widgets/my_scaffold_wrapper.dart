import 'package:flutter/material.dart';
import './my_drawer.dart'; // 導入你的 MyDrawer

class MyScaffoldWrapper extends StatelessWidget {
  final String title; // 畫面的標題
  final Widget body; // 畫面的主要內容

  const MyScaffoldWrapper({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        // 右邊按鈕設定
        // actions: <Widget>[],
      ),
      drawer: MyDrawer(),
      body: body, // 將傳入的 body Widget 放在 Scaffold 的 body 中
    );
  }
}
