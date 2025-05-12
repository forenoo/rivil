import 'package:rivil/features/auth/data/models/user_model.dart';
import 'package:rivil/features/auth/data/models/user_profile_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signIn({required String email, required String password});

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    String? avatarUrl = "",
  });

  Future<void> signOut();

  Future<UserProfileModel?> getUserProfile(String userId);

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates);
}
