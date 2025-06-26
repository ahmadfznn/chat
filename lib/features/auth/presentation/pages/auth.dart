import 'package:flutter/material.dart';
import 'package:chat/features/auth/presentation/pages/login.dart';
import 'package:chat/features/auth/presentation/pages/register/register.dart';

class Auth extends StatefulWidget {
  const Auth({super.key, required this.page});
  final int? page;

  @override
  // ignore: library_private_types_in_public_api
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  late final PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.page ?? 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      key: _scaffoldKey,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Login(pageController: _pageController),
          Register(
            pageController: _pageController,
          ),
        ],
      ),
    );
  }
}
