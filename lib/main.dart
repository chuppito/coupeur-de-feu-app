import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/patient_session.dart';
import 'models/protocole.dart';
import 'screens/home_screen.dart';
import 'services/protocole_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PatientSessionAdapter());
  Hive.registerAdapter(ProtocoleAdapter());
  await Hive.openBox<PatientSession>('sessions');
  await Hive.openBox<Protocole>('protocoles');
  await Hive.openBox('app_meta');
  await ProtocoleService.seedNouveautesSiNecessaire();
  runApp(const MyApp()); // Ajout de 'const' ici
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Ajout de 'const' ici
  
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen()); // Ajout de 'const' ici
  }
}