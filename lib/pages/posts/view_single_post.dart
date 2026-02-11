import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/comment_database_service.dart';
import 'package:flutter_blog_site/utils/storage_service_post.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewSinglePost extends StatefulWidget {
  const ViewSinglePost({super.key});

  @override
  State<ViewSinglePost> createState() => _ViewSinglePostState();
}

class _ViewSinglePostState extends State<ViewSinglePost> {
  final SupabaseClient supabase = Supabase.instance.client;
  final StorageServicePost _storageServicePost = StorageServicePost();
  final CommentDatabaseService _commentDatabaseService =
      CommentDatabaseService();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _updateCommentController =
      TextEditingController();
  late final currentUser = supabase.auth.currentUser;
  File? _imageFile;
  File? _imageFileUpdateComment;
  String? _postId;
  String? _author;
  String? _imageDatabaseUrl;
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
  ) async {
    try {
      setState(() {
        _isEditing = true;
        _setEditingId = commentId;
        _updateCommentController.text = commentText;
      });
    } catch (e) {
      print(e);
    }
  }

  Future fetchAllCommentsInPost() async {
    try {
      final res = await _commentDatabaseService.databaseFetchAllCommentsInPost(
        _postId!,
      );
      setState(() {
        comments = res;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final post =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (post != null) {
        setState(() {
          _postId = post['id'];
          _author = post['author'];
          _imageDatabaseUrl = post['image'];
          _title = post['title'];
          _description = post['description'];

          isLoading = false;
        });
        await fetchAllCommentsInPost();
      }
    });
  }

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

  Future pickImageUpdateComments() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFileUpdateComment = File(image.path);
        });
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
        final res = await _storageServicePost.uploadPostImage(_imageFile!);
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
        _commentController.clear();
        _imageFile = null;
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
      final res = await _storageServicePost.uploadPostImage(
        _imageFileUpdateComment!,
      );
      await _commentDatabaseService.databaseUpdateComments(
        comment,
        res,
        commentId,
      );
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                  '$_author',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              '$_title',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30),
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
    );
  }

  Widget _allCommentsInAPost() {
    if (comments.isEmpty) {
      return const Center(child: Text('No comments yet'));
    }
    return Column(
      children: comments.map((comment) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          PopupMenuItem(value: 0, child: const Text('Edit')),
                          PopupMenuItem(value: 1, child: const Text('Delete')),
                        ],
                        onSelected: (value) {
                          if (value == 0) {
                            setEditingIdFn(comment['id'], comment['comment']);
                          }

                          if (value == 1) {
                            deleteSingleComment(comment['id']);
                          }
                        },
                      ),
                    ],
                  ],
                ),
                if (_isEditing && _setEditingId == comment['id']) ...[
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
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Icon(Icons.file_present_sharp, size: 40),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
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
                          onPressed: () => updateComment(comment['id']),
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
                ] else ...[
                  if (comment['image'] != null) ...[
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Image.network(comment['image'], height: 100),
                    ),
                  ],
                  SizedBox(height: 10),
                  Text('${comment['comment']}', style: TextStyle(fontSize: 15)),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
