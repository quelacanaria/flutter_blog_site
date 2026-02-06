import 'package:flutter/material.dart';
import 'package:flutter_blog_site/auth/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    anonKey: dotenv.env['FLUTTER_PUBLIC_ANON_KEY']!,
    url: dotenv.env['FLUTTER_PUBLIC_SUPABASE_URL']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: AuthGate());
  }
}
