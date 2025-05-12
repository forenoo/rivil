import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rivil/app.dart';
import 'package:rivil/core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final supabaseService = await SupabaseService.initialize();

  runApp(RivilApp(supabaseService: supabaseService));
}
