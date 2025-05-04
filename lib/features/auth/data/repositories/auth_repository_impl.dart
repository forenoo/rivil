import 'package:rivil/core/services/supabase_service.dart';
import 'package:rivil/features/auth/domain/repositories/auth_repository.dart';
import 'package:rivil/features/auth/data/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseService _supabaseService;

  AuthRepositoryImpl(this._supabaseService);

  @override
  Future<UserModel?> signIn(
      {required String email, required String password}) async {
    try {
      final response = await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return UserModel(
          id: response.user!.id,
          email: response.user!.email!,
          name: response.user!.userMetadata?['name'] as String?,
          avatarUrl: response.user!.userMetadata?['avatar_url'] as String?,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  @override
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    String? avatarUrl = "",
  }) async {
    try {
      final response = await _supabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'avatar_url': avatarUrl},
      );

      if (response.user != null) {
        return UserModel(
          id: response.user!.id,
          email: response.user!.email!,
          name: name,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabaseService.client.auth.signOut();
  }
}
