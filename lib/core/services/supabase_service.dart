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
      url: 'https://smuuulmlgwrdjibmghwv.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNtdXV1bG1sZ3dyZGppYm1naHd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY5MzA2NjUsImV4cCI6MjA2MjUwNjY2NX0.u9I4Qqlu3hfbua8X3-leCiThwOMIyXJMdlNuhDZn79w',
    );

    return SupabaseService(client: Supabase.instance.client);
  }
}

enum AuthState { authenticated, unauthenticated }
