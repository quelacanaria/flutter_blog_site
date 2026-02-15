import 'package:flutter/material.dart';
import 'package:flutter_blog_site/pages/login_page.dart';
import 'package:flutter_blog_site/pages/posts/create_posts.dart';
import 'package:flutter_blog_site/pages/posts/delete_posts.dart';
import 'package:flutter_blog_site/pages/posts/private_posts.dart';
import 'package:flutter_blog_site/pages/posts/update_posts.dart';
import 'package:flutter_blog_site/pages/posts/view_all_posts.dart';
import 'package:flutter_blog_site/pages/posts/view_single_post.dart';
import 'package:flutter_blog_site/pages/profile_page.dart';
import 'package:flutter_blog_site/pages/register_page.dart';
import 'package:flutter_blog_site/pages/settings_page.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy());
  await Supabase.initialize(
    url: 'https://jwvmwlyhexouldycjwno.supabase.co',
    anonKey: 'sb_publishable_SCcJ8CnZRzO6NVqxW13jhQ_BEw9r8TW',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supabase = Supabase.instance.client;

    // dart format off
    final GoRouter router = GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
      redirect: (context, state){
        final session = supabase.auth.currentSession;
    final loggingIn = state.matchedLocation == '/';

    if (session == null && !loggingIn) {
      return '/';
    }

    if (session != null && loggingIn) {
      return '/dashboard_page';
    }

    return null;
       
      },
      routes:[
      GoRoute(path: '/', builder: (context, state) => LoginPage()),
      GoRoute(path: '/createAccount_page', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/dashboard_page', builder: (context, state) => DashboardPage()),
      GoRoute(path: '/createPosts_page', builder: (context, state) => const CreatePosts()),
      GoRoute(path: '/deletePosts_page/:id', builder: (context, state) {
        final postId = state.pathParameters['id']!;
        return DeletePosts(postId: postId);}),
      GoRoute(path: '/updatePosts_page/:id', builder: (context, state) {
        final postId = state.pathParameters['id']!;
        return UpdatePosts(postId: postId);
      },),
      GoRoute(path: '/viewPosts_page', builder: (context, state) => const ViewPosts()),
      GoRoute(path: '/settings_page', builder: (context, state) => SettingsPage()),
      GoRoute(path: '/privatePosts_page', builder: (context, state) => PrivatePosts()),
      GoRoute(path: '/viewSinglePost_page/:id', builder: (context, state) {
        final postId = state.pathParameters['id']!;
        return ViewSinglePost(postId: postId);
      }) 
    ]);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig:router
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((event) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}