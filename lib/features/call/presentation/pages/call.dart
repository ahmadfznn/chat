import 'dart:ui';

import 'package:chat/pages/friend.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class Call extends StatefulWidget {
  const Call({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  _CallState createState() => _CallState();
}

Route _goPage(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    opaque: false,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: Curves.easeInOutExpo));
      final offsetAnimation = animation.drive(tween);
      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

class _CallState extends State<Call> with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  final List<Map<String, dynamic>> callList = [
    {
      'name': 'Alice',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'name': 'Bob',
      'date': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'name': 'Charlie',
      'date': DateTime.now().subtract(const Duration(days: 3, hours: 5)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: GestureDetector(
        onTapDown: (_) => _fabController.forward(),
        onTapUp: (_) => _fabController.reverse(),
        onTapCancel: () => _fabController.reverse(),
        onTap: () => Navigator.push(
          context,
          _goPage(Friend(user: widget.user)),
        ),
        child: AnimatedBuilder(
          animation: _fabAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _fabAnimation.value,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00D4FF),
                      Color(0xFF0099CC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.white.withOpacity(0.1),
                      child: Icon(
                        IconsaxPlusBold.call_add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(top: 16),
        itemCount: callList.length,
        itemBuilder: (context, index) {
          final call = callList[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x80FFFFFF),
                  Color(0x80F8FAFC),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0x33E2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(call['name']),
              subtitle: Text(_formatDate(call['date'])),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Handle options here
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
