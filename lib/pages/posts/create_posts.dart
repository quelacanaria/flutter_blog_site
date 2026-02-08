import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';

class CreatePosts extends StatefulWidget {
  const CreatePosts({super.key});

  @override
  State<CreatePosts> createState() => _CreatePostsState();
}

class _CreatePostsState extends State<CreatePosts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const Navbar(), body: Text('Create Posts'));
  }
}
