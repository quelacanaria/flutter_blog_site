import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blog_site/auth/auth_service.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/auth_database_service.dart';
import 'package:flutter_blog_site/utils/comment_database_service.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:flutter_blog_site/utils/storage_service.dart';
import 'package:flutter_blog_site/utils/userphoto_database_service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final authService = AuthService();
  final PostDatabaseService _postDatabaseService = PostDatabaseService();
  final CommentDatabaseService _commentDatabaseService =
      CommentDatabaseService();
  final StorageService _storageService = StorageService();
  final UserphotoDatabaseService _userphotoDatabaseService =
      UserphotoDatabaseService();
  final AuthDatabaseService _authDatabaseService = AuthDatabaseService();
  UserData? currentUser;
  String? imageUserUrl;
  File? _imageFile;
  String? _name;
  String? _email;
  Uint8List? _imageFileWeb;
  bool _isUploading = false;
  bool _isFetching = true;
  bool isEditingName = false;
  bool isEditingEmail = false;
  SupabaseClient supabase = Supabase.instance.client;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  Future fetchProfileImage() async {
    try {
      final res = await _userphotoDatabaseService.viewSingleUserPhoto();
      if (!mounted) return;
      setState(() {
        imageUserUrl = res?['image'];

        _isFetching = false;
      });
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    }
  }

  @override
  void initState() {
    super.initState();
    currentUser = authService.getCurrentUserData();
    if (currentUser != null) {
      setState(() {
        _name = currentUser!.name!;
        _email = currentUser!.email!;
        _nameController.text = _name!;
        _emailController.text = _email!;
      });
    }

    fetchProfileImage();
  }

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      if (kIsWeb) {
        setState(() {
          _imageFile = null;
          _imageFileWeb = bytes;
        });
      } else {
        setState(() {
          _imageFileWeb = null;
          _imageFile = File(image.path);
        });
      }
    }
  }

  Future uploadProfileImage() async {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
    });

    try {
      if (_imageFile != null) {
        if (imageUserUrl != null) {
          await _storageService.removeUserImage();
          final imageUrl = await _storageService.uploadUserImage(
            file: _imageFile!,
          );
          await _userphotoDatabaseService.updateUserPhoto(imageUrl!);
          setState(() {
            imageUserUrl = imageUrl;
          });
        } else {
          final imageUrl = await _storageService.uploadUserImage(
            file: _imageFile!,
          );
          await _userphotoDatabaseService.uploadUserPhoto(imageUrl!);
          setState(() {
            imageUserUrl = imageUrl;
          });
        }
      } else if (_imageFileWeb != null) {
        if (imageUserUrl != null) {
          await _storageService.removeUserImage();
          final imageUrl = await _storageService.uploadUserImage(
            bytes: _imageFileWeb!,
          );
          await _userphotoDatabaseService.updateUserPhoto(imageUrl!);
          setState(() {
            imageUserUrl = imageUrl;
          });
        } else {
          final imageUrl = await _storageService.uploadUserImage(
            bytes: _imageFileWeb!,
          );
          await _userphotoDatabaseService.uploadUserPhoto(imageUrl!);
          setState(() {
            imageUserUrl = imageUrl;
          });
        }
      }

      setState(() {
        _imageFile = null;
        _imageFileWeb = null;
      });
      context.pushReplacement('/settings_page');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Uploaded Successfully')));
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
        context.pushReplacement('/settings_page');
      }
    } catch (e) {
      print(e);
    }
  }

  Future changeName() async {
    final name = _nameController.text;
    try {
      await _authDatabaseService.databaseChangeName(name);
      _postDatabaseService.updateAuthor(name);
      _commentDatabaseService.updateCommentAuthor(name);
      _name = name;
      setState(() {
        isEditingName = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Name Successfully Changed')));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      body: _isFetching
          ? Center(child: const CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
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
                                                child: Image.file(
                                                  _imageFile!,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : _imageFileWeb != null
                                      ? CircleAvatar(
                                          radius: 120,
                                          child: SizedBox(
                                            height: 200,
                                            child: AspectRatio(
                                              aspectRatio: 1,
                                              child: ClipOval(
                                                child: Image.memory(
                                                  _imageFileWeb!,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                ),
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
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Icon(
                                                            Icons.person,
                                                            size: 200,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (imageUserUrl != null)
                                              Positioned(
                                                right: 60,
                                                top: 20,
                                                child: GestureDetector(
                                                  onTap:
                                                      deleteUserDatabaseImage,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                              _imageFileWeb = null;
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
                                    : _imageFileWeb != null
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                              _imageFileWeb = null;
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
                                SizedBox(height: 10),
                                changeNameForm(),
                                SizedBox(height: 5),
                                Text('${_email ?? ''}'),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () =>
                                      context.push('/privatePosts_page'),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget changeNameForm() {
    return isEditingName
        ? Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),

              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isEditingName = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: changeName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text('Update'),
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Text(
                '${_name ?? ''}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Spacer(),
              CircleAvatar(
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      isEditingName = true;
                      isEditingEmail = false;
                    });
                  },
                  icon: Icon(Icons.edit),
                ),
              ),
            ],
          );
  }
}
