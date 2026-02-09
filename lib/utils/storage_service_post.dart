import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageServicePost {
  final SupabaseClient supabase = Supabase.instance.client;

  Future uploadPostImage(final File file) async {
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

  Future deletePostImage() async {
    try {
      final res = await supabase
          .from('posts')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .single();
      final fileName = res['image'];
      final filePath = fileName.toString().split('/postsImages/')[1];
      await supabase.storage.from('postsImages').remove([filePath]);
    } catch (e) {
      print(e);
    }
  }
}
