import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/date_time.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:flutter_blog_site/utils/storage_service_post.dart';
import 'package:flutter_blog_site/utils/userphoto_database_service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class UpdatePosts extends StatefulWidget {
  final String postId;
  const UpdatePosts({super.key, required this.postId});

  @override
  State<UpdatePosts> createState() => _UpdatePostsState();
}

class _UpdatePostsState extends State<UpdatePosts> {
  final PostDatabaseService _postDatabaseService = PostDatabaseService();
  final StorageServicePost _storageServicePost = StorageServicePost();
  final UserphotoDatabaseService _userphotoDatabaseService =
      UserphotoDatabaseService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  String? _public;
  List<String> _databasePostImageUrl = [];
  String? _author;
  List<AssetEntity> _imageFiles = [];
  List<Uint8List> _imageFilesWeb = [];
  bool _isUpdating = false;
  String? _postId;
  String? user_id;
  String? _created_at;
  bool isLoading = true;

  Future<String?> FetchAllUserPhoto(String userId) async {
    try {
      final data = await _userphotoDatabaseService.databaseViewAllUsersPhoto(
        userId,
      );
      return data;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future pickImagesWeb() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        if (kIsWeb) {
          List<Uint8List> webImages = [];
          for (var image in images) {
            final bytes = await image.readAsBytes();
            webImages.add(bytes);
          }
          setState(() {
            _imageFilesWeb.addAll(webImages);
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future pickImagesMobile() async {
    try {
      final List<AssetEntity>? image = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 20,
          selectedAssets: _imageFiles,
          requestType: RequestType.image,
        ),
      );
      if (image != null) {
        setState(() {
          _imageFiles = image;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPost();
  }

  Future fetchPost() async {
    try {
      final post = await _postDatabaseService.databasefetchSinglePost(
        widget.postId,
      );
      setState(() {
        _titleController.text = post['title'];
        _descriptionController.text = post['description'];
        _public = post['Public'];
        _author = post['author'];
        _postId = post['id'];
        user_id = post['user_id'];
        _created_at = post['created_at'];
        if (post['image'] != null) {
          _databasePostImageUrl = List<String>.from(jsonDecode(post['image']));
        } else {
          _databasePostImageUrl = List<String>.from(post['image']);
        }
        isLoading = false;
      });
    } catch (e) {
      print(e);
    }
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
      if (_imageFiles.isNotEmpty || _imageFilesWeb.isNotEmpty) {
        List<String> finalImageList = [];
        finalImageList.addAll(_databasePostImageUrl);
        List<String> imagesUpdatePost = [];
        await _storageServicePost.deleteStoragePostImage(_postId!);
        if (_imageFiles.isNotEmpty) {
          imagesUpdatePost = await _storageServicePost
              .storageUploadMultipleImages(assets: _imageFiles);
        } else {
          imagesUpdatePost = await _storageServicePost
              .storageUploadMultipleImages(bytesList: _imageFilesWeb);
        }
        finalImageList.addAll(imagesUpdatePost);
        await _postDatabaseService.dataseUpdatePostWithImage(
          public!,
          finalImageList,
          title,
          description,
          _postId!,
        );
      } else {
        await _postDatabaseService.updatePost(
          public!,
          title,
          description,
          _postId!,
        );
      }
      fetchPost();
      setState(() {
        _imageFiles = [];
        _imageFilesWeb = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Updated successful')));
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future deleteSingleImageInList(String url) async {
    try {
      await _storageServicePost.storageDeleteSingleImageInTheList(url);
      await _postDatabaseService.deleteDatabaseSinleImageToList(
        url,
        widget.postId,
      );
      fetchPost();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text('Image deleted')));
      }
    } catch (e) {
      print(e);
    }
  }

  Future deletePostImage() async {
    try {
      await _storageServicePost.deleteStoragePostImage(_postId!);
      await _postDatabaseService.deleteDatabasePostImage(_postId!);
      // setState(() {
      //   _databasePostImageUrl = null;
      // });
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
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
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    FutureBuilder<String?>(
                                      future: FetchAllUserPhoto(user_id!),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircleAvatar(
                                            radius: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          );
                                        }

                                        if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          return CircleAvatar(
                                            radius: 20,
                                            backgroundImage: NetworkImage(
                                              snapshot.data!,
                                            ),
                                          );
                                        }

                                        return const CircleAvatar(
                                          radius: 20,
                                          child: Icon(Icons.person),
                                        );
                                      },
                                    ),
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
                                SizedBox(height: 5),
                                Text(
                                  DateTimeHelper.timeAgo(_created_at),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
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
                                  title: Text('private'),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10),
                                    if (_databasePostImageUrl.isNotEmpty ||
                                        _imageFiles.isNotEmpty ||
                                        _imageFilesWeb.isNotEmpty)
                                      showAllImages()
                                    else
                                      const Text('No Image Uploaded'),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (kIsWeb) {
                                      pickImagesWeb();
                                    } else {
                                      pickImagesMobile();
                                    }
                                  },
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
                                      onPressed: () => context.pop(true),
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget showAllImages() {
    final totalCount =
        _databasePostImageUrl.length +
        (kIsWeb ? _imageFilesWeb.length : _imageFiles.length);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        /// 🔹 DATABASE IMAGES FIRST
        if (index < _databasePostImageUrl.length) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  _databasePostImageUrl[index],
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () =>
                      deleteSingleImageInList(_databasePostImageUrl[index]),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.black.withOpacity(0.6),
                    child: const Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        /// 🔹 NEW FILE IMAGES
        final fileIndex = index - _databasePostImageUrl.length;

        return Stack(
          children: [
            Positioned.fill(
              child: kIsWeb
                  ? Image.memory(_imageFilesWeb[fileIndex], fit: BoxFit.cover)
                  : AssetEntityImage(_imageFiles[fileIndex], fit: BoxFit.cover),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    kIsWeb
                        ? _imageFilesWeb.removeAt(fileIndex)
                        : _imageFiles.removeAt(fileIndex);
                  });
                },
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.black.withOpacity(0.6),
                  child: const Icon(Icons.close, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
