import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';

class ViewSinglePost extends StatefulWidget {
  const ViewSinglePost({super.key});

  @override
  State<ViewSinglePost> createState() => _ViewSinglePostState();
}

class _ViewSinglePostState extends State<ViewSinglePost> {
  @override
  Widget build(BuildContext context) {
    final post =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return Scaffold(
      appBar: const Navbar(),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 25, child: Icon(Icons.person)),
                      const SizedBox(width: 20),
                      Text(
                        post['author'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    post['title'],
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30),
                  ),
                  if (post['image'] != null) ...[
                    SizedBox(height: 5),
                    Image.network(post['image'], height: 400),
                  ],
                  SizedBox(height: 20),
                  Text(post['description'], style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
