import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageServicePost {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<String?> uploadPostImage({File? file, Uint8List? bytes}) async {
    if (file == null && bytes == null) return null;
    final userId = supabase.auth.currentUser!.id;
    final timeStamp = DateTime.now().millisecondsSinceEpoch;

    final fileName = '$userId-$timeStamp.png';
    try {
      if (bytes != null) {
        await supabase.storage
            .from('postsImages')
            .uploadBinary(fileName, bytes);
      } else {
        await supabase.storage.from('postsImages').upload(fileName, file!);
      }

      final imageUrl = supabase.storage
          .from('postsImages')
          .getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print(e);
      return null;
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
