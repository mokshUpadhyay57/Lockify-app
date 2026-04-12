import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';


class ChannelSummaryScreen extends StatelessWidget {
  const ChannelSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Channels on Lockify', style: TextStyle(fontSize: 18)),
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Center(
        child: Text('Channels Summary Screen'),
      ),
    );
  }
}

