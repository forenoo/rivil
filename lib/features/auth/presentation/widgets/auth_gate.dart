import 'package:flutter/material.dart';
import 'package:rivil/core/services/supabase_service.dart';

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
    return StreamBuilder<AuthState>(
      stream: supabaseService.authStateChanges,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final authState = snapshot.data!;
        return authState == AuthState.authenticated
            ? authenticatedRoute
            : unauthenticatedRoute;
      },
    );
  }
}
