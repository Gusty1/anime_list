import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

//無網路螢幕
class NoNetworkScreen extends StatelessWidget {
  const NoNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 80, color: Theme.of(context).colorScheme.error),
              SizedBox(height: 20),
              AutoSizeText(
                '無網路連接',
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.titleLarge?.fontSize ?? 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              AutoSizeText(
                '請檢查您的網路連線狀態',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
