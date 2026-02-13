import 'package:supabase_flutter/supabase_flutter.dart';

class UserphotoDatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future uploadUserPhoto(final String imageUrl) async {
    try {
      await supabase.from('userphoto').insert({
        'image': imageUrl,
        'user_id': supabase.auth.currentUser!.id,
      });
    } catch (e) {
      print(e);
    }
  }

  Future updateUserPhoto(final String imageUrl) async {
    try {
      await supabase
          .from('userphoto')
          .update({'image': imageUrl})
          .eq('user_id', supabase.auth.currentUser!.id);
    } catch (e) {
      print(e);
    }
  }

  Future deleteUserPhoto() async {
    try {
      await supabase
          .from('userphoto')
          .delete()
          .eq('user_id', supabase.auth.currentUser!.id);
    } catch (e) {
      print(e);
    }
  }

  Future viewSingleUserPhoto() async {
    try {
      final res = await supabase
          .from('userphoto')
          .select('image')
          .eq('user_id', supabase.auth.currentUser!.id)
          .single();
      return res;
    } catch (e) {
      print(e);
    }
  }

  Future databaseViewAllUsersPhoto(final String userId) async {
    try {
      final res = await supabase
          .from('userphoto')
          .select('image')
          .eq('user_id', userId)
          .maybeSingle();
      return res?['image'];
    } catch (e) {
      return null;
    }
  }
}
