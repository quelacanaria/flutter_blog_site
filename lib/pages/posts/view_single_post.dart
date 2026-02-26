import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/carousel_all_image.dart';
import 'package:flutter_blog_site/components/date_time.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/pages/posts/view_all_comments.dart';
import 'package:flutter_blog_site/utils/comment_database_service.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:flutter_blog_site/utils/storage_service_post.dart';
import 'package:flutter_blog_site/utils/userphoto_database_service.dart';
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
  final UserphotoDatabaseService _userphotoDatabaseService =
      UserphotoDatabaseService();
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
  String? _created_At;
  String? user_id;
  bool _isUploadUpdate = false;
  bool isLoading = true;
  bool _isEditing = false;
  bool _isDeleting = false;
  String? _setDeletingId;
  String? _setEditingId;
  String? _deletingComment;
  late final _user_image;
  List<Map<String, dynamic>> comments = [];

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

      if (post != null) {
        setState(() {
          _author = post['author'];
          if (post['image'] != null) {
            _imageDatabaseUrl = List<String>.from(jsonDecode(post['image']));
          } else {
            _imageDatabaseUrl = List<String>.from(post['image']);
          }
          _title = post['title'];
          _description = post['description'];
          _created_At = post['created_at'];
          user_id = post['user_id'];
          _user_image = post['user_image'];
          isLoading = false;
        });
      }
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

  Future<String?> fetchAllUserPhoto(String userId) async {
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

  void setEditingIdFn(
    final String commentId,
    final String commentText,
    final List<String> commentImage,
  ) {
    setState(() {
      _isEditing = true;
      _setEditingId = commentId;
      _updateCommentController.text = commentText;
      _imageCommentDatabaseUrl = commentImage;
      _setDeletingId = null;
    });
  }

  void setDeletingIdFn(
    final String commentId,
    final String commentText,
    final List<String> commentImage,
  ) {
    setState(() {
      _isDeleting = true;
      _setDeletingId = commentId;
      _deletingComment = commentText;
      _imageCommentDatabaseUrl = commentImage;
      _setEditingId = null;
    });
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

  Future deleteComment() async {
    final String commentId = _setDeletingId!;
    List<String> imageUrl = _imageCommentDatabaseUrl;

    try {
      print(imageUrl);
      if (imageUrl.isNotEmpty) {
        await _storageServicePost.deleteListOfImageInComment(imageUrl);
      }
      await _commentDatabaseService.databaseDeleteSingleComment(commentId);
      fetchAllCommentsInPost();
      setState(() {
        _setDeletingId = null;
        images = [];
      });
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
      if (_setEditingId != null) {
        await _commentDatabaseService.deleteDatabaseSinleImageToList(
          url,
          _setEditingId!,
        );
      } else if (_setDeletingId != null) {
        await _commentDatabaseService.deleteDatabaseSinleImageToList(
          url,
          _setDeletingId!,
        );
      }

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
      setState(() {
        _setEditingId = null;
        images = [];
      });
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
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[200],
                              child: ClipOval(
                                child: _user_image != null
                                    ? CachedNetworkImage(
                                        imageUrl: _user_image,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Icon(Icons.person),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.person),
                                      )
                                    : const Icon(Icons.person),
                              ),
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
                        const SizedBox(height: 12),
                        Text(
                          DateTimeHelper.timeAgo(_created_At),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
                    displayAllUserPhoto(comment),
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
                            if (comment['image'] != null &&
                                comment['image'].toString().isNotEmpty) {
                              images = List<String>.from(
                                jsonDecode(comment['image']),
                              );
                            }
                            setDeletingIdFn(
                              comment['id'],
                              comment['comment'],
                              images,
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
                Text(
                  DateTimeHelper.timeAgo(comment['created_at']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_setEditingId == comment['id']) ...[
                  showEditingForm(),
                ] else if (_setDeletingId == comment['id']) ...[
                  deletingModal(),
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

  Widget displayAllUserPhoto(final comment) {
    return FutureBuilder<String?>(
      future: fetchAllUserPhoto(comment['user_id']),
      builder: (context, snapshot) {
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   return const CircleAvatar(
        //     radius: 20,
        //     child: const CircularProgressIndicator(strokeWidth: 2),
        //   );
        // }
        if (snapshot.hasData && snapshot.data != null) {
          return CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(snapshot.data!),
          );
        }
        return CircleAvatar(radius: 20, child: Icon(Icons.person));
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
        return Stack(
          children: [
            Positioned(
              child: Center(
                child: Image.network(imageUrl[index], fit: BoxFit.cover),
              ),
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
                        images = [];
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
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

  Widget deletingModal() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to delete this comment?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              showAllImages(),
              SizedBox(height: 15),
              Text('${_deletingComment ?? ''}'),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _setDeletingId = null;
                          images = [];
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => deleteComment(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
