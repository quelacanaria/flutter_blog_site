import 'dart:io';
import 'dart:typed_data';

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
      final parts = fileName.toString().split('/userphotos/');
      final filePath = parts[1];
      await supabase.storage.from('userphotos').remove([filePath]);
    } catch (e) {
      print(e);
    }
  }

  Future<String?> uploadUserImage({File? file, Uint8List? bytes}) async {
    if (file == null && bytes == null) return null;
    final userId = supabase.auth.currentUser!.id;
    final timeStamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$userId-$timeStamp.png';
    try {
      if (bytes != null) {
        await supabase.storage.from('userphotos').uploadBinary(fileName, bytes);
      } else if (file != null) {
        await supabase.storage.from('userphotos').upload(fileName, file);
      }
      final imageUrl = Supabase.instance.client.storage
          .from('userphotos')
          .getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
