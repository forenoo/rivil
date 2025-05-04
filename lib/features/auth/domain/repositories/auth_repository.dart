import 'package:rivil/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signIn({required String email, required String password});

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    String? avatarUrl = "",
  });

  Future<void> signOut();
}
