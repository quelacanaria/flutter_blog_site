import 'package:flutter/material.dart';
import 'package:flutter_blog_site/auth/auth_service.dart';
import 'package:flutter_blog_site/components/navbar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // final authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const Navbar(), body: const Text('Dashboard Page'));
  }
}
