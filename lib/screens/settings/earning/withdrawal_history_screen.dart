import 'package:flutter/material.dart';

class WithdrawalHistoryScreen extends StatelessWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Withdrawal Request'),
      ),
      body: Center(
        child: Text('Withdrawal Request Screen'),
      ),
    );
  }
}
