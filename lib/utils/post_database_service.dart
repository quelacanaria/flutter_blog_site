import 'package:supabase_flutter/supabase_flutter.dart';

class PostDatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;
  Future uploadPosts(
    final String public,
    final String imageUrl,
    final String title,
    final String description,
  ) async {
    await supabase.from('posts').insert({
      'Public': public,
      'image': imageUrl,
      'title': title,
      'description': description,
      'author': supabase.auth.currentUser!.userMetadata?['name'],
      'user_id': supabase.auth.currentUser!.id,
    });
  }

  Future<List<Map<String, dynamic>>> viewAllPosts() async {
    try {
      final res = await supabase.from('posts').select();

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print(e);
      return [];
    }
  }
}
