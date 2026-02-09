import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blog_site/auth/auth_service.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/storage_service.dart';
import 'package:flutter_blog_site/utils/userphoto_database_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final authService = AuthService();
  final StorageService _storageService = StorageService();
  final UserphotoDatabaseService _userphotoDatabaseService =
      UserphotoDatabaseService();
  UserData? currentUser;
  String? imageUserUrl;
  File? _imageFile;
  bool _isUploading = false;
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> fetchProfileImage() async {
    try {
      final res = await _userphotoDatabaseService.viewSingleUserPhoto();
      setState(() {
        imageUserUrl = res['image'];
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

  Future uploadProfileImage() async {
    if (_imageFile == null || _isUploading) return;
    setState(() {
      _isUploading = true;
    });

    try {
      final imageUrl = await _storageService.uploadUserImage(_imageFile!);
      if (imageUserUrl != null) {
        await _storageService.removeUserImage();
        await _userphotoDatabaseService.updateUserPhoto(imageUrl);
      } else {
        await _userphotoDatabaseService.uploadUserPhoto(imageUrl);
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
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future deleteUserDatabaseImage() async {
    try {
      await _storageService.removeUserImage();
      await _userphotoDatabaseService.deleteUserPhoto();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('successfully deleted')));
        Navigator.pushReplacementNamed(context, '/settings_page');
      }
    } catch (e) {
      print(e);
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
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 120,
                            child: SizedBox(
                              height: 200,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: ClipOval(
                                  child: imageUserUrl != null
                                      ? Image.network(
                                          imageUserUrl!,
                                          height: 200,
                                        )
                                      : Icon(Icons.person, size: 200),
                                ),
                              ),
                            ),
                          ),
                          if (imageUserUrl != null)
                            Positioned(
                              right: 60,
                              top: 20,
                              child: GestureDetector(
                                onTap: deleteUserDatabaseImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
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
