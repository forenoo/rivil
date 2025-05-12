import 'package:rivil/core/services/supabase_service.dart';
import 'package:rivil/features/auth/domain/repositories/auth_repository.dart';
import 'package:rivil/features/auth/data/models/user_model.dart';
import 'package:rivil/features/auth/data/models/user_profile_model.dart';

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
        // Get user profile from the user_profile table using user_id
        final profileResponse = await _supabaseService.client
            .from('user_profile')
            .select()
            .eq('user_id', response.user!.id)
            .single();

        final profile = UserProfileModel.fromJson(profileResponse);

        return UserModel(
          id: response.user!.id,
          email: response.user!.email!,
          name: profile.fullName ?? profile.username,
          avatarUrl: profile.avatarUrl,
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
      );

      if (response.user != null) {
        // Create user profile in the user_profile table using user_id
        await _supabaseService.client.from('user_profile').insert({
          'user_id': response.user!.id,
          'email': email,
          'full_name': name,
          'username': name.toLowerCase().replaceAll(' ', '_'),
          'avatar_url': avatarUrl,
        });

        // Get the created profile
        final profileResponse = await _supabaseService.client
            .from('user_profile')
            .select()
            .eq('user_id', response.user!.id)
            .single();

        final profile = UserProfileModel.fromJson(profileResponse);

        return UserModel(
          id: response.user!.id,
          email: response.user!.email!,
          name: profile.fullName ?? profile.username,
          avatarUrl: profile.avatarUrl,
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

  @override
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('user_profile')
          .select()
          .eq('user_id', userId)
          .single();

      return UserProfileModel.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      await _supabaseService.client
          .from('user_profile')
          .update(updates)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}
