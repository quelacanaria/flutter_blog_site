import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';

class DeletePosts extends StatefulWidget {
  const DeletePosts({super.key});

  @override
  State<DeletePosts> createState() => _DeletePostsState();
}

class _DeletePostsState extends State<DeletePosts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const Navbar(), body: Text('Delete Posts'));
  }
}
