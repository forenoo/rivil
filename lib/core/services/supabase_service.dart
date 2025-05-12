import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client;

  SupabaseService({required this.client});

  Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange.map((event) => event.session != null
          ? AuthState.authenticated
          : AuthState.unauthenticated);

  static Future<SupabaseService> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    return SupabaseService(client: Supabase.instance.client);
  }
}

enum AuthState { authenticated, unauthenticated }
