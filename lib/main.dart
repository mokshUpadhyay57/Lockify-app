import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:lockify/services/auth/auth_gate.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
   
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AuthGate(),  // 
      // home: LoginScreen(), // for developement purposes
      debugShowCheckedModeBanner: false,
    );
  }
}


