import 'package:flutter/material.dart';

class WalletHomeScreen extends StatelessWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallet Home'),
      ),
      body: Center(
        child: Text('Wallet Home Screen'),
      ),
    );
  }
}
