import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';

class ViewPosts extends StatefulWidget {
  const ViewPosts({super.key});

  @override
  State<ViewPosts> createState() => _ViewPostsState();
}

class _ViewPostsState extends State<ViewPosts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const Navbar(), body: Text('View Posts'));
  }
}
