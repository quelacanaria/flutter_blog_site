import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class CommentDatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future uploadDatabaseComment(
    final String comment,
    final String postId,
  ) async {
    try {
      await supabase.from('comments').insert({
        'comment': comment,
        'post_id': postId,
        'author': supabase.auth.currentUser!.userMetadata?['name'],
      });
    } catch (e) {
      print(e);
    }
  }

  Future uploadDatabaseMultipleImageComment(
    final String comment,
    final List<String> imageUrl,
    final String postId,
  ) async {
    try {
      await supabase.from('comments').insert({
        'comment': comment,
        'image': imageUrl,
        'post_id': postId,
        'author': supabase.auth.currentUser!.userMetadata?['name'],
      });
    } catch (e) {
      print(e);
    }
  }

  Future databaseDeleteSingleComment(final String commentId) async {
    try {
      await supabase.from('comments').delete().eq('id', commentId);
    } catch (e) {
      print(e);
    }
  }

  Future deleteDatabaseSinleImageToList(
    String commentImage,
    String commentId,
  ) async {
    try {
      final comment = await supabase
          .from('comments')
          .select('image')
          .eq('id', commentId)
          .maybeSingle();
      if (comment == null || comment['image'] == null) return;
      List<String> images = List<String>.from(jsonDecode(comment['image']));
      images.remove(commentImage);
      await supabase
          .from('comments')
          .update({'image': jsonEncode(images)})
          .eq('id', commentId);
    } catch (e) {
      print(e);
    }
  }

  Future databaseDeleteAllCommentInASinglePost(final String postId) async {
    try {
      await supabase.from('comments').delete().eq('post_id', postId);
    } catch (e) {
      print(e);
    }
  }

  Future databaseUpdateComments(
    final String comment,
    final String commentId,
  ) async {
    try {
      if (comment.isNotEmpty) {
        await supabase
            .from('comments')
            .update({'comment': comment})
            .eq('id', commentId);
      }
    } catch (e) {
      print(e);
    }
  }

  Future dataseUpdateCommentWithImage(
    final List<String> imageUrl,
    final String comment,
    final String commentId,
  ) async {
    await supabase
        .from('comments')
        .update({'image': imageUrl, 'comment': comment})
        .eq('id', commentId);
  }

  Future databaseUpdateDeleteImageComments(
    final String comment,
    final String? imageUrl,
    final String commentId,
  ) async {
    try {
      await supabase
          .from('comments')
          .update({'comment': comment, 'image': imageUrl})
          .eq('id', commentId);
      // ignore: dead_code
    } catch (e) {
      print(e);
    }
  }

  Future<List<Map<String, dynamic>>> databaseFetchAllCommentsInPost(
    final String postId,
  ) async {
    try {
      final res = await supabase
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print(e);
      return [];
    }
  }
}
