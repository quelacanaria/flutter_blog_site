import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/carousel_all_image.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/pages/posts/view_all_comments.dart';
import 'package:flutter_blog_site/utils/comment_database_service.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:flutter_blog_site/utils/storage_service_post.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ViewSinglePost extends StatefulWidget {
  final String postId;

  const ViewSinglePost({super.key, required this.postId});

  @override
  State<ViewSinglePost> createState() => _ViewSinglePostState();
}

class _ViewSinglePostState extends State<ViewSinglePost> {
  final SupabaseClient supabase = Supabase.instance.client;
  final StorageServicePost _storageServicePost = StorageServicePost();
  final CommentDatabaseService _commentDatabaseService =
      CommentDatabaseService();
  final PostDatabaseService _postDatabaseService = PostDatabaseService();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _updateCommentController =
      TextEditingController();
  late final currentUser = supabase.auth.currentUser;
  List<AssetEntity> _imageFiles = [];
  List<Uint8List> _imageFilesWeb = [];
  File? _imageFilesUpdateComment;
  Uint8List? _imageFilesWebUpdateComment;
  String? _postId;
  String? _author;
  List<String> _imageDatabaseUrl = [];
  String? _imageDatabaseUpdateUrl;
  String? _title;
  String? _description;
  bool _isUploadUpdate = false;
  bool isLoading = true;
  bool _isEditing = false;
  String? _setEditingId;
  List<Map<String, dynamic>> comments = [];

  Future setEditingIdFn(
    final String commentId,
    final String commentText,
    final String? commentImage,
  ) async {
    try {
      setState(() {
        _isEditing = true;
        _setEditingId = commentId;
        _updateCommentController.text = commentText;
        _imageDatabaseUpdateUrl = commentImage;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();

    fetchSinglePost();
    fetchAllCommentsInPost();
  }

  Future fetchSinglePost() async {
    try {
      final post = await _postDatabaseService.databasefetchSinglePost(
        widget.postId,
      );

      setState(() {
        _postId = post['id'];
        _author = post['author'];
        if (post['image'] != null) {
          _imageDatabaseUrl = List<String>.from(jsonDecode(post['image']));
        } else {
          _imageDatabaseUrl = List<String>.from(post['image']);
        }
        _title = post['title'];
        _description = post['description'];

        isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  Future fetchAllCommentsInPost() async {
    try {
      final data = await _commentDatabaseService.databaseFetchAllCommentsInPost(
        widget.postId,
      );
      setState(() {
        comments = data;
      });
    } catch (e) {
      print(e);
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
      } else {}
    } catch (e) {
      print(e);
    }
  }

  Future pickImagesMobile() async {
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
  }

  Future pickImageUpdateComments() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _imageFilesUpdateComment = null;
            _imageFilesWebUpdateComment = bytes;
          });
        } else {
          setState(() {
            _imageFilesWebUpdateComment = null;
            _imageFilesUpdateComment = File(image.path);
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future uploadComment() async {
    if (_isUploadUpdate) return;
    setState(() {
      _isUploadUpdate = true;
    });
    final comment = _commentController.text;
    try {
      if (comment.trim() == '') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('please write a comment!')),
        );
        return;
      }
      List<String> imageUrl = [];
      if (_imageFiles.isNotEmpty) {
        imageUrl = await _storageServicePost.storageUploadMultipleImages(
          assets: _imageFiles,
        );
        await _commentDatabaseService.uploadDatabaseMultipleImageComment(
          comment,
          imageUrl,
          widget.postId,
        );
      }
      if (_imageFilesWeb.isNotEmpty) {
        imageUrl = await _storageServicePost.storageUploadMultipleImages(
          bytesList: _imageFilesWeb,
        );
        await _commentDatabaseService.uploadDatabaseMultipleImageComment(
          comment,
          imageUrl,
          widget.postId,
        );
      }
      if (_imageFiles.isEmpty && _imageFilesWeb.isEmpty) {
        await _commentDatabaseService.uploadDatabaseComment(
          comment,
          widget.postId,
        );
      }

      setState(() {
        _imageFilesUpdateComment = null;
        _commentController.clear();
        _imageFiles = [];
        _imageFilesWeb = [];
      });
      await fetchAllCommentsInPost();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text('Comment Uploaded')));
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isUploadUpdate = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      body: Center(
        child: isLoading
            ? Center(child: const CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  _singlePostAndCommentInput(),
                  const SizedBox(height: 20),
                  // _allCommentsInAPost(),
                  ViewAllComments(
                    allComments: comments,
                    postId: widget.postId,
                    onChange: fetchAllCommentsInPost,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _singlePostAndCommentInput() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 0,
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
                            const CircleAvatar(
                              radius: 25,
                              child: Icon(Icons.person),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              '$_author',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          '$_title',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                          ),
                        ),
                        CarouselImage(All: _imageDatabaseUrl),
                        SizedBox(height: 20),
                        Text('$_description', style: TextStyle(fontSize: 20)),
                        SizedBox(height: 15),
                        const Text('Write a comment: '),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'wow impressive',
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            SizedBox(
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    kIsWeb
                                        ? pickImagesWeb()
                                        : pickImagesMobile();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Icon(Icons.file_present_sharp, size: 40),
                              ),
                            ),
                          ],
                        ),
                        if (_imageFilesWeb.isNotEmpty ||
                            _imageFiles.isNotEmpty) ...[
                          showAllSelectedImages(),
                        ],
                        SizedBox(height: 10),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: uploadComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Comment'),
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
    );
  }

  Widget showAllSelectedImages() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: kIsWeb ? _imageFilesWeb.length : _imageFiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Positioned.fill(
              child: kIsWeb
                  ? Image.memory(_imageFilesWeb[index], fit: BoxFit.cover)
                  : AssetEntityImage(_imageFiles[index], fit: BoxFit.cover),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    kIsWeb
                        ? _imageFilesWeb.removeAt(index)
                        : _imageFiles.removeAt(index);
                  });
                },
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
