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
      url: 'https://gvegwmkvdgjftisfndbr.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2ZWd3bWt2ZGdqZnRpc2ZuZGJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYyMzExMDksImV4cCI6MjA2MTgwNzEwOX0.Yldl9oGJDzZEcGgtrJBhLS-BU5bKFQoHIht1-F-sHxk',
    );

    return SupabaseService(client: Supabase.instance.client);
  }
}

enum AuthState { authenticated, unauthenticated }
