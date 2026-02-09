import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future removeUserImage() async {
    try {
      final res = await supabase
          .from('userphoto')
          .select('image')
          .eq('user_id', supabase.auth.currentUser!.id)
          .single();
      final fileName = res['image'];
      final parts = fileName.toString().split('/userPhotos/');
      final filePath = parts[1];
      await supabase.storage.from('userPhotos').remove([filePath]);
    } catch (e) {
      print(e);
    }
  }

  Future uploadUserImage(final File file) async {
    try {
      final ext = file.path.split('.').last;
      final fileName =
          '${supabase.auth.currentUser!.id}-${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage.from('userPhotos').upload(fileName, file!);
      final imageUrl = Supabase.instance.client.storage
          .from('userPhotos')
          .getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print(e);
    }
  }
}
