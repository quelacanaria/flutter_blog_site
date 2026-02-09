import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:flutter_blog_site/utils/storage_service_post.dart';
import 'package:image_picker/image_picker.dart';

class CreatePosts extends StatefulWidget {
  const CreatePosts({super.key});

  @override
  State<CreatePosts> createState() => _CreatePostsState();
}

class _CreatePostsState extends State<CreatePosts> {
  final StorageServicePost _storageServicePost = StorageServicePost();
  final PostDatabaseService _postDatabaseService = PostDatabaseService();
  bool _isPosting = false;
  String _postState = 'public';
  File? _imageFile;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future createPosts() async {
    if (_isPosting) return;
    setState(() {
      _isPosting = true;
    });
    final public = _postState;
    final title = _titleController.text;
    final description = _descriptionController.text;
    try {
      final res = await _storageServicePost.uploadPostImage(_imageFile!);
      await _postDatabaseService.uploadPosts(public, res, title, description);
      _titleController.clear();
      _descriptionController.clear();
      _imageFile = null;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Post Successfull')));
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RadioListTile<String>(
              title: Text('public'),
              value: 'public',
              groupValue: _postState,
              onChanged: (value) {
                setState(() {
                  _postState = 'public';
                });
              },
            ),

            RadioListTile<String>(
              title: Text('private'),
              value: 'private',
              groupValue: _postState,
              onChanged: (value) {
                setState(() {
                  _postState = 'private';
                });
              },
            ),
            Text('Image: ', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            _imageFile != null
                ? Stack(
                    children: [
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.zero,
                          image: DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _imageFile = null;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Text('No Image Uploaded'),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickImage,
              child: Text('Choose Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
            ),
            SizedBox(height: 10),
            Text('Title: ', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Description: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: createPosts,
              child: Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
