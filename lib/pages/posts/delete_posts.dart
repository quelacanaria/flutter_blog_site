import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/comment_database_service.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:flutter_blog_site/utils/storage_service_post.dart';
import 'package:go_router/go_router.dart';

class DeletePosts extends StatefulWidget {
  final String postId;
  const DeletePosts({super.key, required this.postId});

  @override
  State<DeletePosts> createState() => _DeletePostsState();
}

class _DeletePostsState extends State<DeletePosts> {
  final CommentDatabaseService _commentDatabaseService =
      CommentDatabaseService();
  final StorageServicePost _storageServicePost = StorageServicePost();
  final PostDatabaseService _postDatabaseService = PostDatabaseService();
  String? _title;
  String? _imageDatabaseUrl;
  String? _description;
  String? _postId;

  @override
  void initState() {
    super.initState();
    fetchSinglePost();
  }

  Future fetchSinglePost() async {
    try {
      final post = await _postDatabaseService.databasefetchSinglePost(
        widget.postId,
      );
      if (post != null) {
        setState(() {
          _title = post['title'];
          _imageDatabaseUrl = post['image'];
          _description = post['description'];
          _postId = post['id'];
        });
      }
    } catch (e) {
      print(e) {}
    }
  }

  Future deletePost() async {
    try {
      await _storageServicePost.deleteStorageAllCommentImageInASinglePost(
        _postId!,
      );
      await _commentDatabaseService.databaseDeleteAllCommentInASinglePost(
        _postId!,
      );
      await _storageServicePost.deleteStoragePostImage(_postId!);
      await _postDatabaseService.deleteDatabaseSinglePost(_postId!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Post Deleted')));
        Navigator.pop(context, true);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
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
                      Center(
                        child: const Text(
                          'Are you sure you want to delete this post?',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                      SizedBox(height: 10),
                      Text(
                        '$_title',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                      SizedBox(height: 10),
                      _imageDatabaseUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _imageDatabaseUrl!,
                                height: 400,
                                fit: BoxFit.fill,
                              ),
                            )
                          : SizedBox(height: 0),
                      SizedBox(height: 15),
                      Text('$_description', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 15),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => context.pop(),
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
                            onPressed: deletePost,
                            child: Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
