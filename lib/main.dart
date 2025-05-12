import 'package:flutter/material.dart';
import 'package:rivil/app.dart';
import 'package:rivil/core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseService = await SupabaseService.initialize();

  runApp(RivilApp(supabaseService: supabaseService));
}
