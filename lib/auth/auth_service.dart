import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  Future<void> signOut() async {
    return await _supabase.auth.signOut();
  }

  UserData? getCurrentUserData() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;

    if (user == null) return null;

    return UserData(
      email: user.email,
      name: user.userMetadata?['name'],
      id: user.id,
    );
  }
}

class UserData {
  final String? email;
  final String? name;
  final String? id;

  UserData({this.email, this.name, this.id});
}
