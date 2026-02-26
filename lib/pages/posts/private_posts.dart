import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/carousel_all_image.dart';
import 'package:flutter_blog_site/components/date_time.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:flutter_blog_site/utils/userphoto_database_service.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivatePosts extends StatefulWidget {
  const PrivatePosts({super.key});

  @override
  State<PrivatePosts> createState() => _PrivatePostsState();
}

class _PrivatePostsState extends State<PrivatePosts> {
  final PostDatabaseService _postDatabaseService = PostDatabaseService();
  final UserphotoDatabaseService _userphotoDatabaseService =
      UserphotoDatabaseService();
  List<Map<String, dynamic>> posts = [];
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  String? postData;

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

  Future fetchPrivatePosts() async {
    try {
      final data = await _postDatabaseService.viewAllPrivatePosts();
      setState(() {
        posts = data;
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      fetchPrivatePosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Card(
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
                      const Text(
                        'View All Private Posts',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          isLoading
              ? const Center(child: CircularProgressIndicator())
              : posts.isEmpty
              ? Center(child: const Text('No fetch Posts'))
              : Expanded(
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final imageUrl = post['user_image'];

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.grey[200],
                                        child: ClipOval(
                                          child: imageUrl != null
                                              ? CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      const Icon(Icons.person),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          const Icon(
                                                            Icons.person,
                                                          ),
                                                )
                                              : const Icon(Icons.person),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        post['author'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (post['user_id'] ==
                                          supabase.auth.currentUser!.id)
                                        PopupMenuButton<int>(
                                          offset: const Offset(0, 50),
                                          icon: const CircleAvatar(
                                            radius: 18,
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
                                          onSelected: (value) async {
                                            if (value == 0) {
                                              final res = await context.push(
                                                '/updatePosts_page/${post['id']}',
                                              );
                                              if (res == true) {
                                                fetchPrivatePosts();
                                              }
                                            }

                                            if (value == 1) {
                                              final res = await await context.push(
                                                '/deletePosts_page/${post['id']}',
                                              );
                                              if (res == true) {
                                                fetchPrivatePosts();
                                              }
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                  Text(
                                    DateTimeHelper.timeAgo(post['created_at']),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    post['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 8),
                                  displayAllImageInAPost(post),
                                  const SizedBox(height: 10),
                                  Text(
                                    post['description'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),

                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () => context.push(
                                      '/viewSinglePost_page/${post['id']}',
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(Icons.comment_outlined),
                                            SizedBox(width: 6),
                                            Text("Comment"),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget displayAllImageInAPost(final post) {
    if (post['image'] == null) return const SizedBox.shrink();
    List<String> images;
    if (post['image'] is String) {
      images = List<String>.from(jsonDecode(post['image']));
    } else {
      images = List<String>.from(post['image']);
    }
    if (images.isEmpty) return const SizedBox.shrink();

    return CarouselImage(All: images);
  }
}
