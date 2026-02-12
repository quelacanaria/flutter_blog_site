import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewPosts extends StatefulWidget {
  const ViewPosts({super.key});

  @override
  State<ViewPosts> createState() => _ViewPostsState();
}

class _ViewPostsState extends State<ViewPosts> {
  final PostDatabaseService _postDatabaseService = PostDatabaseService();
  List<Map<String, dynamic>> posts = [];
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  String? postData;
  Future fetchPosts() async {
    try {
      final data = await _postDatabaseService.viewAllPosts();
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
      fetchPosts();
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
                        'View All Posts',
                        style: TextStyle(
                          color: Colors.indigo,
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
                                      const CircleAvatar(
                                        radius: 18,
                                        child: Icon(Icons.person),
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
                                              final res =
                                                  await Navigator.pushNamed(
                                                    context,
                                                    '/updatePosts_page',
                                                    arguments: post,
                                                  );
                                              if (res == true) {
                                                fetchPosts();
                                              }
                                            }

                                            if (value == 1) {
                                              final res =
                                                  await Navigator.pushNamed(
                                                    context,
                                                    '/deletePosts_page',
                                                    arguments: post,
                                                  );
                                              if (res == true) {
                                                fetchPosts();
                                              }
                                            }
                                          },
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  Text(
                                    post['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 8),
                                  if (post['image'] != null)
                                    Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 200,
                                          maxHeight: 300,
                                        ),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  post['image'],
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Text(
                                    post['description'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),

                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/viewSinglePost_page',
                                      arguments: post,
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
}
