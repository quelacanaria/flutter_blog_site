import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';

class PrivatePosts extends StatefulWidget {
  const PrivatePosts({super.key});

  @override
  State<PrivatePosts> createState() => _PrivatePostsState();
}

class _PrivatePostsState extends State<PrivatePosts> {
  @override
  Widget build(BuildContext context) {
    return (Scaffold(
      appBar: const Navbar(),
      body: const Text('Private Posts'),
    ));
  }
}
