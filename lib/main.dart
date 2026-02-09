import 'package:flutter/material.dart';
import 'package:flutter_blog_site/pages/login_page.dart';
import 'package:flutter_blog_site/pages/posts/create_posts.dart';
import 'package:flutter_blog_site/pages/posts/delete_posts.dart';
import 'package:flutter_blog_site/pages/posts/private_posts.dart';
import 'package:flutter_blog_site/pages/posts/update_posts.dart';
import 'package:flutter_blog_site/pages/posts/view_posts.dart';
import 'package:flutter_blog_site/pages/profile_page.dart';
import 'package:flutter_blog_site/pages/register_page.dart';
import 'package:flutter_blog_site/pages/settings_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    anonKey: dotenv.env['FLUTTER_PUBLIC_ANON_KEY']!,
    url: dotenv.env['FLUTTER_PUBLIC_SUPABASE_URL']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Supabase.instance.client.auth.currentUser != null
          ? '/dashboard_page'
          : '/',
      routes: {
        '/': (context) => LoginPage(),
        '/createAccount_page': (context) => const RegisterPage(),
        '/dashboard_page': (context) => DashboardPage(),
        '/createPosts_page': (context) => const CreatePosts(),
        '/deletePosts_page': (context) => const DeletePosts(),
        '/updatePosts_page': (context) => const UpdatePosts(),
        '/viewPosts_page': (context) => const ViewPosts(),
        '/settings_page': (context) => const SettingsPage(),
        '/privatePosts_page': (context) => const PrivatePosts(),
      },
    );
  }
}
