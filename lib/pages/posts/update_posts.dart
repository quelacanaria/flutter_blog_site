import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:flutter_blog_site/utils/storage_service_post.dart';
import 'package:image_picker/image_picker.dart';

class UpdatePosts extends StatefulWidget {
  const UpdatePosts({super.key});

  @override
  State<UpdatePosts> createState() => _UpdatePostsState();
}

class _UpdatePostsState extends State<UpdatePosts> {
  final PostDatabaseService _postDatabaseService = PostDatabaseService();
  final StorageServicePost _storageServicePost = StorageServicePost();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _public;
  String? _databasePostImageUrl;
  String? _author;
  File? _imageFile;
  bool _isUpdating = false;
  String? _postId;

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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final post =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (post != null) {
        setState(() {
          _titleController.text = post['title'];
          _descriptionController.text = post['description'];
          _public = post['Public'];
          _author = post['author'];
          _databasePostImageUrl = post['image'];
          _postId = post['id'];
        });
      }
    });
  }

  Future updatePost() async {
    if (_isUpdating) return;
    setState(() {
      _isUpdating = true;
    });
    final public = _public;
    final title = _titleController.text;
    final description = _descriptionController.text;
    try {
      if (title.trim() == '' || description.trim() == '') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('title and description are required!!')),
        );
        return;
      }
      await _storageServicePost.deleteStoragePostImage(_postId!);
      final res = await _storageServicePost.uploadPostImage(_imageFile);
      await _postDatabaseService.updatePost(
        public!,
        res,
        title,
        description,
        _postId!,
      );
      if (res != null) {
        setState(() {
          _databasePostImageUrl = res;
          _imageFile = null;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Updated successfull')));
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future deletePostImage() async {
    try {
      await _storageServicePost.deleteStoragePostImage(_postId!);
      await _postDatabaseService.deleteDatabasePostImage(_postId!);
      setState(() {
        _databasePostImageUrl = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Post Image Deleted!')));
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
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 25, child: Icon(Icons.person)),
                      const SizedBox(width: 20),
                      Text(
                        _author ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),
                  RadioListTile<String>(
                    title: Text('public'),
                    value: 'public',
                    groupValue: _public,
                    onChanged: (value) {
                      setState(() {
                        _public = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('Private'),
                    value: 'private',
                    groupValue: _public,
                    onChanged: (value) {
                      setState(() {
                        _public = value;
                      });
                    },
                  ),
                  const Text(
                    'Image: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_databasePostImageUrl != null) ...[
                    if (_imageFile != null) ...[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(height: 10),
                          Image.file(_imageFile!, height: 400),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => {
                                setState(() {
                                  _imageFile = null;
                                }),
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(height: 10),
                          Image.network(_databasePostImageUrl!, height: 400),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: deletePostImage,
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
                    ],
                  ] else ...[
                    _imageFile != null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(height: 10),
                              Image.file(_imageFile!, height: 400),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => {
                                    setState(() {
                                      _imageFile = null;
                                    }),
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text('No Image Uploaded'),
                  ],
                  ElevatedButton(
                    onPressed: pickImage,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text('Choose Photo'),
                  ),
                  const Text(
                    'Title: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  const Text(
                    'Description: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: updatePost,
                        child: Text('Update'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
