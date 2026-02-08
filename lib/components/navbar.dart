import 'package:flutter/material.dart';
import 'package:flutter_blog_site/auth/auth_service.dart';
import 'package:flutter_blog_site/pages/posts/create_posts.dart';
import 'package:flutter_blog_site/pages/posts/view_posts.dart';
import 'package:flutter_blog_site/pages/profile_page.dart';

class Navbar extends StatefulWidget implements PreferredSizeWidget {
  const Navbar({super.key});
  @override
  State<Navbar> createState() => _NavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NavbarState extends State<Navbar> {
  final authService = AuthService();
  UserData? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = authService.getCurrentUserData();
  }

  void logout() async {
    await authService.signOut();
    setState(() {
      currentUser = null;
    });
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Blog Site',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      actions: [
        if (currentUser != null) ...[
          IconButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard_page',
              (route) => false,
            ),
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
              child: Icon(Icons.home),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/viewPosts_page',
              (route) => false,
            ),
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
              child: Icon(Icons.newspaper),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/createPosts_page',
              (route) => false,
            ),
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
              child: Icon(Icons.add),
            ),
          ),

          PopupMenuButton<int>(
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
              child: Icon(Icons.person),
            ),
            offset: const Offset(0, 50),
            color: Colors.indigo,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                child: Text(
                  '${currentUser!.name}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: 1,
                child: Text(
                  'Settings',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
            onSelected: (value) => {
              if (value == 0)
                {}
              else if (value == 1)
                {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/settings_page',
                    (route) => false,
                  ),
                }
              else if (value == 2)
                {logout()}
              else
                {},
            },
          ),
        ],
      ],
    );
  }
}
