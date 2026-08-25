import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/cadran.dart';
import 'models/patient_session.dart';
import 'models/protocole.dart';
import 'screens/patients_screen.dart';
import 'services/protocole_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PatientSessionAdapter());
  Hive.registerAdapter(ProtocoleAdapter());
  Hive.registerAdapter(CadranAdapter());
  await Hive.openBox<PatientSession>('sessions');
  await Hive.openBox<Protocole>('protocoles');
  await Hive.openBox<Cadran>('cadrans');
  await Hive.openBox('app_meta');
  await ProtocoleService.seedNouveautesSiNecessaire();
  runApp(const MyApp()); // Ajout de 'const' ici
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));

    return MaterialApp(
      title: "Coupeur de Feu",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      home: const PatientsScreen(),
    );
  }
}