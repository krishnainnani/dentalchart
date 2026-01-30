import 'package:flutter/material.dart';
import 'features/patient_intake/patient_list_screen.dart';

void main() {
  runApp(const DentistApp());
}

class DentistApp extends StatelessWidget {
  const DentistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dental Chart Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PatientListScreen(),
    );
  }
}
