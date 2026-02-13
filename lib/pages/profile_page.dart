import 'package:flutter/material.dart';
import 'package:flutter_blog_site/auth/auth_service.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // final authService = AuthService();
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome ${supabase.auth.currentUser!.userMetadata?['name']}',
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 2),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'To empower individuals to share their stories, ideas, and expertise with the world by providing an intuitive, accessible, and engaging platform for blogging.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 40,
                width: 120,
                child: ElevatedButton(
                  onPressed: () => context.push('/createPosts_page'),
                  child: Text('Create'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
