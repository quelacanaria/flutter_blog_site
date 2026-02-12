import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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
  Uint8List? _imageFileWeb;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
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
      if (title.trim() == '' || description.trim() == '') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Title and Description is required!!')),
        );
        return;
      }
      if (_imageFile != null) {
        final res = await _storageServicePost.uploadPostImage(
          file: _imageFile!,
        );
        await _postDatabaseService.uploadPosts(public, res, title, description);
      } else if (_imageFileWeb != null) {
        final res = await _storageServicePost.uploadPostImage(
          bytes: _imageFileWeb!,
        );
        await _postDatabaseService.uploadPosts(public, res, title, description);
      } else {
        await _postDatabaseService.uploadPosts(
          public,
          null,
          title,
          description,
        );
      }
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
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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
                          Text(
                            'Image: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),

                          if (_imageFileWeb != null) ...[
                            Stack(
                              children: [
                                Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.zero,
                                    image: DecorationImage(
                                      image: MemoryImage(_imageFileWeb!),
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
                                        _imageFileWeb = null;
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
                            ),
                          ] else if (_imageFile != null) ...[
                            Stack(
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
                            ),
                          ] else
                            const Text('No image uploaded'),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: pickImage,
                            child: Text('Choose Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Title: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                          SizedBox(height: 20),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: createPosts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: Text('Create'),
                            ),
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
}
