import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageServicePost {
  final SupabaseClient supabase = Supabase.instance.client;

  Future uploadPostImage(final File? file) async {
    if (file == null) return null;
    final ext = file.path.split('.').last;
    final fileName =
        '${supabase.auth.currentUser!.id}-${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await supabase.storage.from('postsImages').upload(fileName, file!);
      final imageUrl = supabase.storage
          .from('postsImages')
          .getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print(e);
    }
  }

  Future deleteStoragePostImage(final String postId) async {
    try {
      final res = await supabase
          .from('posts')
          .select()
          .eq('id', postId)
          .single();
      final fileName = res['image'];
      final filePath = fileName.toString().split('/postsImages/')[1];
      await supabase.storage.from('postsImages').remove([filePath]);
    } catch (e) {
      print(e);
    }
  }

  Future deleteStorageCommentImage(final String commentId) async {
    try {
      final res = await supabase
          .from('comments')
          .select()
          .eq('id', commentId)
          .single();
      final fileName = res['image'];
      final filePath = fileName.toString().split('/postsImages/')[1];
      await supabase.storage.from('postsImages').remove([filePath]);
    } catch (e) {
      print(e);
    }
  }

  Future deleteStorageAllCommentImageInASinglePost(final String postId) async {
    try {
      final res = await supabase
          .from('comments')
          .select('image')
          .eq('post_id', postId);

      if (res.isEmpty) return;

      List<String> filePaths = [];

      for (final comment in res) {
        final imageUrl = comment['image'];

        if (imageUrl != null && imageUrl.toString().isNotEmpty) {
          final filePath = imageUrl.toString().split('/postsImages/').last;

          filePaths.add(filePath);
        }
      }
      if (filePaths.isNotEmpty) {
        await supabase.storage.from('postsImages').remove(filePaths);
      }
    } catch (e) {
      print(e);
    }
  }
}
