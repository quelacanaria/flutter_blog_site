import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

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

  // dart format off
  Future<List<String>> storageUploadMultipleImages({List<AssetEntity>? assets, List<Uint8List>? bytesList}) async {
    if ((assets == null || assets.isEmpty) && (bytesList == null || bytesList.isEmpty)) return [];
    final userId = supabase.auth.currentUser!.id;
    List<String> imageUrls = [];
    try {
      if(bytesList != null){
        for(var bytes in bytesList){
           final fileName = '$userId-${DateTime.now().microsecondsSinceEpoch}.png';
          await supabase.storage.from('postsImages').uploadBinary(fileName, bytes);
          final url = supabase.storage.from('postsImages').getPublicUrl(fileName);

          imageUrls.add(url);
        }
      }

      if(assets != null){
        for(var asset in assets){
          final fileData = await asset.file;

           if(fileData != null){
            final fileName = '$userId-${DateTime.now().microsecondsSinceEpoch}.png';
          await supabase.storage.from('postsImages').upload(fileName, fileData);
          final url = supabase.storage.from('postsImages').getPublicUrl(fileName);
           imageUrls.add(url);
           }

         
        }
      }

      return imageUrls;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future deleteListOfImageInPost(List<String> imageUrls)async{
    if(imageUrls.isEmpty) return;
    try{
      final paths = imageUrls.map((url){
        final uri = Uri.parse(url);
        return uri.pathSegments.sublist(5).join('/');
      }).toList();

      await supabase.storage.from('postsImages').remove(paths);

    }catch(e){
      print(e);
    }
  }

  Future deleteListOfImageInComment(List<String> imageUrls)async{
    if(imageUrls.isEmpty) return;
    try{
      final paths = imageUrls.map((url){
        final uri = Uri.parse(url);
        return uri.pathSegments.sublist(5).join('/');
      }).toList();

      await supabase.storage.from('postsImages').remove(paths);

    }catch(e){
      print(e);
    }
  }

  Future storageDeleteSingleImageInTheList(final String imageUrlIndex)async{
    try{
      if(imageUrlIndex.isEmpty)return;
      final uri = Uri.parse(imageUrlIndex);
      final path = uri.pathSegments.sublist(5).toList();

      await supabase.storage.from('postsImages').remove(path);
    }catch(e){
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

  Future<void> deleteStorageAllCommentImageInASinglePost(String postId) async {
  try {
    // 1️⃣ Fetch all comments for the post
    final comments = await supabase
        .from('comments')
        .select('id, image')
      .eq('post_id', postId);  // assuming you have a post_id column

    // 2️⃣ Delete images for each comment
    for (final comment in comments) {
      final commentId = comment['id'] as String;
      final imageData = comment['image'];

      if (imageData != null && imageData.toString().isNotEmpty) {
        final List<dynamic> images = jsonDecode(imageData);
        
        final filePaths = images.map<String>((url) {
          return url.split('/postsImages/')[1];
        }).toList();

        await supabase.storage
            .from('postsImages')
            .remove(filePaths);
      }
    }

    // 3️⃣ Delete all comments from DB (optional - depends on your cascade rules)
    await supabase
        .from('comments')
        .delete()
        .eq('post_id', postId);

  } catch (e) {
    print(e);
  }
}
}
