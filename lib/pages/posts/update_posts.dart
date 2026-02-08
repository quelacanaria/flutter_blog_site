import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';

class UpdatePosts extends StatefulWidget {
  const UpdatePosts({super.key});

  @override
  State<UpdatePosts> createState() => _UpdatePostsState();
}

class _UpdatePostsState extends State<UpdatePosts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const Navbar(), body: Text('Update Posts'));
  }
}
