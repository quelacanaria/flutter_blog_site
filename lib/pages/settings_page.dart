import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blog_site/auth/auth_service.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final authService = AuthService();
  UserData? currentUser;
  String? imageUrl1;
  File? _imageFile;
  bool _isUploading = false;
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> fetchProfileImage() async {
    try {
      final res = await supabase
          .from('userphoto')
          .select('image')
          .eq('user_id', supabase.auth.currentUser!.id)
          .single();

      setState(() {
        imageUrl1 = res['image'];
      });
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    currentUser = authService.getCurrentUserData();
    fetchProfileImage();
  }

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future remove() async {
    try {
      final res = await supabase
          .from('userphoto')
          .select('image')
          .eq('user_id', supabase.auth.currentUser!.id)
          .single();
      final fileName = res['image'];
      final parts = fileName.toString().split('/postsImages/');
      final filePath = parts[1];
      await supabase.storage.from('postsImages').remove([filePath]);
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  Future uploadProfileImage() async {
    if (_imageFile == null || _isUploading) return;
    setState(() {
      _isUploading = true;
    });

    // final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = _imageFile!.path.split('.').last;
    final fileName =
        '${supabase.auth.currentUser!.id}-${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await supabase.storage.from('postsImages').upload(fileName, _imageFile!);
      final imageUrl = Supabase.instance.client.storage
          .from('postsImages')
          .getPublicUrl(fileName);
      if (imageUrl1 != null) {
        remove();
        await supabase
            .from('userphoto')
            .update({'image': imageUrl})
            .eq('user_id', supabase.auth.currentUser!.id);
      } else {
        await supabase.from('userphoto').insert({
          'image': imageUrl,
          'user_id': supabase.auth.currentUser!.id,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Uploaded Successfully')));
        Navigator.pushReplacementNamed(context, '/settings_page');
      }
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (currentUser != null)
                _imageFile != null
                    ? CircleAvatar(
                        radius: 120,
                        child: SizedBox(
                          height: 200,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipOval(
                              child: Image.file(_imageFile!, height: 200),
                            ),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 120,
                        child: SizedBox(
                          height: 200,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipOval(
                              child: imageUrl1 != null
                                  ? Image.network(imageUrl1!, height: 200)
                                  : Image.asset(
                                      'assets/images/changePic.jpg',
                                      height: 200,
                                    ),
                            ),
                          ),
                        ),
                      ),
              SizedBox(height: 10),
              _imageFile != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: uploadProfileImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text('Update'),
                        ),
                        SizedBox(width: 30),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _imageFile = null;
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text('Cancel'),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text('Choose Image'),
                    ),
              Text(
                '${currentUser!.name}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${currentUser!.email}'),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/privatePosts_page',
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Text('Manage Private Posts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
