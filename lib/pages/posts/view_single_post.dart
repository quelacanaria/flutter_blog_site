import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/comment_database_service.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:flutter_blog_site/utils/storage_service_post.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  File? _imageFile;
  Uint8List? _imageFileWeb;
  File? _imageFileUpdateComment;
  Uint8List? _imageFileWebUpdateComment;
  String? _postId;
  String? _author;
  String? _imageDatabaseUrl;
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
        _imageDatabaseUrl = post['image'];
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
      final res = await _commentDatabaseService.databaseFetchAllCommentsInPost(
        widget.postId,
      );
      setState(() {
        comments = res;
      });
    } catch (e) {
      print(e);
    }
  }

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

  Future pickImageUpdateComments() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _imageFileUpdateComment = null;
            _imageFileWebUpdateComment = bytes;
          });
        } else {
          setState(() {
            _imageFileWebUpdateComment = null;
            _imageFileUpdateComment = File(image.path);
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
      if (_imageFile != null) {
        final res = await _storageServicePost.uploadPostImage(
          file: _imageFile!,
        );
        await _commentDatabaseService.uploadDatabaseComment(
          comment,
          res,
          _postId!,
        );
      } else if (_imageFileWeb != null) {
        final res = await _storageServicePost.uploadPostImage(
          bytes: _imageFileWeb!,
        );
        await _commentDatabaseService.uploadDatabaseComment(
          comment,
          res,
          _postId!,
        );
      } else {
        await _commentDatabaseService.uploadDatabaseComment(
          comment,
          null,
          _postId!,
        );
      }
      setState(() {
        _imageFileUpdateComment = null;
        _commentController.clear();
        _imageFile = null;
        _imageFileWeb = null;
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

  Future deleteSingleComment(final String commentId) async {
    try {
      await _storageServicePost.deleteStorageCommentImage(commentId);
      await _commentDatabaseService.databaseDeleteSingleComment(commentId);
      await fetchAllCommentsInPost();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text('Comment deleted')));
      }
    } catch (e) {
      print(e);
    }
  }

  Future updateComment(final String commentId) async {
    final comment = _updateCommentController.text;
    try {
      await _storageServicePost.deleteStorageCommentImage(commentId);
      if (_imageFile != null) {
        final res = await _storageServicePost.uploadPostImage(
          file: _imageFileUpdateComment,
        );
        await _commentDatabaseService.databaseUpdateComments(
          comment,
          res,
          commentId,
        );
      } else {
        final res = await _storageServicePost.uploadPostImage(
          bytes: _imageFileWebUpdateComment,
        );
        await _commentDatabaseService.databaseUpdateComments(
          comment,
          res,
          commentId,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text('Comment Updated')));
      }
      setState(() {
        _imageFileWebUpdateComment = null;
        _imageFileUpdateComment = null;
        _isEditing = false;
      });
      await fetchAllCommentsInPost();
    } catch (e) {
      print(e);
    }
  }

  Future updateDeleteImageComment(final String commentId) async {
    final comment = _updateCommentController.text;
    try {
      await _storageServicePost.deleteStorageCommentImage(commentId);
      await _commentDatabaseService.databaseUpdateDeleteImageComments(
        comment,
        null,
        commentId,
      );
      await fetchAllCommentsInPost();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text('Image deleted')));
      }
      setState(() {
        _isEditing = false;
      });
      await fetchAllCommentsInPost();
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
                  _allCommentsInAPost(),
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
                        if (_imageDatabaseUrl != null) ...[
                          SizedBox(height: 5),
                          Image.network(_imageDatabaseUrl!, height: 400),
                        ],
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
                                onPressed: pickImage,
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
                        if (_imageFile != null) ...[
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _imageFile!,
                                    width: 80,
                                    height: 70,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                Positioned(
                                  left: 52,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _imageFile = null;
                                      });
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
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_imageFileWeb != null) ...[
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _imageFileWeb!,
                                    width: 80,
                                    height: 70,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                Positioned(
                                  left: 52,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _imageFileWeb = null;
                                      });
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
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          SizedBox(height: 0),
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

  Widget _allCommentsInAPost() {
    if (comments.isEmpty) {
      return const Center(child: Text('No comments yet'));
    }
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
                child: Column(
                  children: comments.map((comment) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
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
                                  '${comment['author']}',
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
                                      PopupMenuItem(
                                        value: 0,
                                        child: const Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 1,
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 0) {
                                        setEditingIdFn(
                                          comment['id'],
                                          comment['comment'],
                                          comment['image'],
                                        );
                                      }

                                      if (value == 1) {
                                        deleteSingleComment(comment['id']);
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                            if (_isEditing &&
                                _setEditingId == comment['id']) ...[
                              SizedBox(height: 10),
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
                                      onPressed: pickImageUpdateComments,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.file_present_sharp,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_imageFileUpdateComment != null) ...[
                                SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _imageFileUpdateComment!,
                                          width: 80,
                                          height: 70,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      Positioned(
                                        left: 52,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _imageFileUpdateComment = null;
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.6,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (_imageFileWebUpdateComment !=
                                  null) ...[
                                SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          _imageFileWebUpdateComment!,
                                          width: 80,
                                          height: 70,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      Positioned(
                                        left: 52,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _imageFileWebUpdateComment = null;
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.6,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (_imageDatabaseUpdateUrl != null) ...[
                                SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _imageDatabaseUpdateUrl!,
                                          width: 80,
                                          height: 70,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      Positioned(
                                        left: 52,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              updateDeleteImageComment(
                                                comment['id'],
                                              );
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else
                                SizedBox(height: 0),

                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = false;
                                          _imageFileUpdateComment = null;
                                          _imageFileWebUpdateComment = null;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.indigo,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          updateComment(comment['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Update'),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              if (comment['image'] != null) ...[
                                SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Image.network(
                                    comment['image'],
                                    height: 100,
                                  ),
                                ),
                              ],
                              SizedBox(height: 10),
                              Text(
                                '${comment['comment']}',
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
