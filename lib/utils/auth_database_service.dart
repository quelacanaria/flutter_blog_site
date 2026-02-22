import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, String> userNameCache = {};

  Future databaseChangeName(final String name) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.auth.updateUser(UserAttributes(data: {'name': name}));
    } catch (e) {
      print(e);
    }
  }

  Future<String> fetchAuthorName(String userId) async {
    if (userNameCache.containsKey(userId)) {
      return userNameCache[userId]!;
    }

    try {
      final res = await supabase.auth.admin.getUserById(userId);
      final name = res.user?.userMetadata?['name'] ?? 'Unknown';
      userNameCache[userId] = name; // cache it
      return name;
    } catch (e) {
      print(e);
      return 'Unknown';
    }
  }
}
