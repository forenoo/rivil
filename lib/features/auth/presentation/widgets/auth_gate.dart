import 'package:flutter/material.dart';
import 'package:rivil/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  final Widget authenticatedRoute;
  final Widget unauthenticatedRoute;
  final SupabaseService supabaseService;

  const AuthGate({
    super.key,
    required this.authenticatedRoute,
    required this.unauthenticatedRoute,
    required this.supabaseService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return snapshot.data!.session != null
            ? authenticatedRoute
            : unauthenticatedRoute;
      },
    );
  }
}
