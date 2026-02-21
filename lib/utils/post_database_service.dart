import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostDatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;
  //single Image
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

  Future databaseUploadPosts(
    final String public,
    final List<String> imageUrl,
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

  Future updateAuthor(String newUsername) async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      await supabase
          .from('posts')
          .update({'author': newUsername})
          .eq('user_id', user.id);
    } catch (e) {
      print(e);
    }
  }

  Future dataseUpdatePostWithImage(
    final String public,
    final List<String> imageUrl,
    final String title,
    final String description,
    final String postId,
  ) async {
    await supabase
        .from('posts')
        .update({
          'Public': public,
          'image': imageUrl,
          'title': title,
          'description': description,
        })
        .eq('id', postId);
  }

  Future updatePost(
    final String public,
    final String title,
    final String description,
    final String postId,
  ) async {
    await supabase
        .from('posts')
        .update({'Public': public, 'title': title, 'description': description})
        .eq('id', postId);
  }

  Future deleteDatabaseSinleImageToList(String postImage, String postId) async {
    try {
      final post = await supabase
          .from('posts')
          .select('image')
          .eq('id', postId)
          .maybeSingle();
      if (post == null || post['image'] == null) return;
      List<String> images = List<String>.from(jsonDecode(post['image']));
      images.remove(postImage);
      await supabase
          .from('posts')
          .update({'image': jsonEncode(images)})
          .eq('id', postId);
    } catch (e) {
      print(e);
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
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future databasefetchSinglePost(final postId) async {
    try {
      final res = await supabase
          .from('posts')
          .select()
          .eq('id', postId)
          .single();
      return res;
    } catch (e) {
      print(e);
      return null;
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
