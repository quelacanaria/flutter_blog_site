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
  List<AssetEntity> _imageFileUpdate = [];
  List<Uint8List> _imageWebUpdate = [];
  String? _author;
  List<String> _imageDatabaseUrl = [];
  List<String> _imageCommentDatabaseUrl = [];
  List<String> images = [];
  String? _title;
  String? _description;
  bool _isUploadUpdate = false;
  bool isLoading = true;
  bool _isEditing = false;
  String? _setEditingId;
  List<Map<String, dynamic>> comments = [];

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

  Future pickUpdateImagesMobile() async {
    final List<AssetEntity>? image = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: 20,
        selectedAssets: _imageFileUpdate,
        requestType: RequestType.image,
      ),
    );
    if (image != null) {
      setState(() {
        _imageFileUpdate = image;
      });
    }
  }

  Future pickUpdateImagesWeb() async {
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
            _imageWebUpdate.addAll(webImages);
          });
        }
      } else {}
    } catch (e) {
      print(e);
    }
  }

  Future setEditingIdFn(
    final String commentId,
    final String commentText,
    final List<String> commentImage,
  ) async {
    try {
      setState(() {
        _isEditing = true;
        _setEditingId = commentId;
        _updateCommentController.text = commentText;
        _imageCommentDatabaseUrl = commentImage;
      });
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

  Future deleteComment(final comment) async {
    if (comment == null) return;

    final String commentId = comment['id'];
    List<String> imageUrl = [];
    setState(() {
      if (comment['image'] != null && comment['image'].toString().isNotEmpty) {
        imageUrl = List<String>.from(jsonDecode(comment['image']));
      }
    });

    try {
      print(imageUrl);
      if (imageUrl.isNotEmpty) {
        await _storageServicePost.deleteListOfImageInComment(imageUrl);
      }
      await _commentDatabaseService.databaseDeleteSingleComment(commentId);
      fetchAllCommentsInPost();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Successfully deleted')));
      }
    } catch (e) {
      print(e);
    }
  }

  Future deleteSingleImageInList(String url) async {
    try {
      await _storageServicePost.storageDeleteSingleImageInTheList(url);
      await _commentDatabaseService.deleteDatabaseSinleImageToList(
        url,
        _setEditingId!,
      );
      fetchAllCommentsInPost();
      setState(() {
        _imageCommentDatabaseUrl.remove(url);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text('Image deleted')));
      }
    } catch (e) {
      print(e);
    }
  }

  Future updateComment() async {
    final comment = _updateCommentController.text;
    try {
      if (comment.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('please write a comment!!')));
        return;
      }
      if (_imageWebUpdate.isNotEmpty || _imageFileUpdate.isNotEmpty) {
        List<String> finalImageList = [];
        finalImageList.addAll(_imageCommentDatabaseUrl);
        List<String> imagesUpdatePost = [];
        if (_imageFileUpdate.isNotEmpty) {
          imagesUpdatePost = await _storageServicePost
              .storageUploadMultipleImages(assets: _imageFileUpdate);
        }
        if (_imageWebUpdate.isNotEmpty) {
          imagesUpdatePost = await _storageServicePost
              .storageUploadMultipleImages(bytesList: _imageWebUpdate);
        }
        finalImageList.addAll(imagesUpdatePost);
        await _commentDatabaseService.dataseUpdateCommentWithImage(
          finalImageList,
          comment,
          _setEditingId!,
        );
        setState(() {
          _imageCommentDatabaseUrl = finalImageList;
          _imageFileUpdate = [];
          _imageWebUpdate = [];
        });
      } else {
        await _commentDatabaseService.databaseUpdateComments(
          comment,
          _setEditingId!,
        );
      }
      fetchAllCommentsInPost();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text('Updated Successfully')));
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
        child: isLoading
            ? Center(child: const CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  _singlePostAndCommentInput(),
                  const SizedBox(height: 20),
                  commentContainer(),
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
        crossAxisCount: 5,
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

  Widget commentContainer() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(children: [showAllComments()]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget showAllComments() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      child: Icon(Icons.person, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${comment['author'] ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    if (currentUser != null &&
                        comment['author'] ==
                            currentUser!.userMetadata?['name']) ...[
                      PopupMenuButton<int>(
                        offset: const Offset(0, 50),
                        icon: const CircleAvatar(
                          radius: 20,
                          child: Icon(Icons.more_vert),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 0, child: const Text('Edit')),
                          PopupMenuItem(value: 1, child: const Text('Delete')),
                        ],
                        onSelected: (value) async {
                          if (value == 0) {
                            if (comment['image'] != null &&
                                comment['image'].toString().isNotEmpty) {
                              images = List<String>.from(
                                jsonDecode(comment['image']),
                              );
                            }
                            setEditingIdFn(
                              comment['id'],
                              comment['comment'],
                              images,
                            );
                          }

                          if (value == 1) {
                            await deleteComment(comment);
                          }
                        },
                      ),
                    ],
                  ],
                ),
                if (_setEditingId == comment['id']) ...[
                  showEditingForm(),
                ] else ...[
                  if (comment['image'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: displayImage(
                        List<String>.from(jsonDecode(comment['image'])),
                      ),
                    ),
                  SizedBox(height: 10),
                  Text(
                    '${comment['comment'] ?? ''} ',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget displayImage(final List<String> imageUrl) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: imageUrl.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Positioned(
              child: Image.network(imageUrl[index], fit: BoxFit.cover),
            ),
          ],
        );
      },
    );
  }

  Widget showEditingForm() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            showAllImages(),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _updateCommentController,
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
                            ? pickUpdateImagesWeb()
                            : pickUpdateImagesMobile();
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
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _setEditingId = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => updateComment(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget showAllImages() {
    final totalCount =
        _imageCommentDatabaseUrl.length +
        (kIsWeb ? _imageWebUpdate.length : _imageFileUpdate.length);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        /// 🔹 DATABASE IMAGES FIRST
        if (index < _imageCommentDatabaseUrl.length) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  _imageCommentDatabaseUrl[index],
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () =>
                      deleteSingleImageInList(_imageCommentDatabaseUrl[index]),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black.withOpacity(0.6),
                    child: const Icon(
                      Icons.delete,
                      size: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        /// 🔹 NEW FILE IMAGES
        final fileIndex = index - _imageCommentDatabaseUrl.length;

        return Stack(
          children: [
            Positioned.fill(
              child: kIsWeb
                  ? Image.memory(_imageWebUpdate[fileIndex], fit: BoxFit.cover)
                  : AssetEntityImage(
                      _imageFileUpdate[fileIndex],
                      fit: BoxFit.cover,
                    ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    kIsWeb
                        ? _imageWebUpdate.removeAt(fileIndex)
                        : _imageFileUpdate.removeAt(fileIndex);
                  });
                },
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black.withOpacity(0.6),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
