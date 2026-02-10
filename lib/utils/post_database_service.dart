import 'package:supabase_flutter/supabase_flutter.dart';

class PostDatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;
  Future uploadPosts(
    final String public,
    final String? imageUrl,
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

  Future updatePost(
    final String public,
    final String? imageUrl,
    final String title,
    final String description,
    final String postId,
  ) async {
    if (imageUrl != null) {
      await supabase
          .from('posts')
          .update({
            'Public': public,
            'image': imageUrl,
            'title': title,
            'description': description,
          })
          .eq('id', postId);
    } else {
      await supabase
          .from('posts')
          .update({
            'Public': public,
            'title': title,
            'description': description,
          })
          .eq('id', postId);
    }
  }

  Future deleteDatabasePostImage(final String postId) async {
    try {
      await supabase.from('posts').update({'image': null}).eq('id', postId);
    } catch (e) {
      print(e);
    }
  }

  Future deleteDatabaseSinglePost(final String postId) async {
    try {
      await supabase.from('posts').delete().eq('id', postId);
    } catch (e) {
      print(e);
    }
  }

  Future<List<Map<String, dynamic>>> viewAllPosts() async {
    try {
      final res = await supabase
          .from('posts')
          .select()
          .eq('Public', 'public')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> viewAllPrivatePosts() async {
    try {
      final res = await supabase
          .from('posts')
          .select()
          .eq('Public', 'private')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> viewAllPostsWithPhotos() async {
    try {
      final res = await supabase
          .from('posts')
          .select('*, userphoto:userphoto(user_id,image)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print(e);
      return [];
    }
  }
}
