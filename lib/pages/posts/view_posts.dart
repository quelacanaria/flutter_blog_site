import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';

class ViewPosts extends StatefulWidget {
  const ViewPosts({super.key});

  @override
  State<ViewPosts> createState() => _ViewPostsState();
}

class _ViewPostsState extends State<ViewPosts> {
  final PostDatabaseService _postDatabaseService = PostDatabaseService();
  List<Map<String, dynamic>> posts = [];
  String? postData;
  Future fetchPosts() async {
    final data = await _postDatabaseService.viewAllPosts();
    setState(() {
      posts = data;
    });
  }

  @override
  void initState() {
    setState(() {
      fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const Navbar(), body: Text(''));
  }
}
