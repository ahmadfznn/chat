import 'package:flutter/material.dart';
import 'package:chat/services/local_database.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  ResetPageState createState() => ResetPageState();
}

Route _goPage(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    opaque: false,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
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

class ResetPageState extends State<ResetPage> {
  bool resetting = false;

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Data Reset'),
        content: Text('This will delete all offline data (chats, users, settings) from your device. This action cannot be undone. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Reset', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() { resetting = true; });
      await LocalDatabase.instance.resetDatabase();
      setState(() { resetting = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All offline data has been reset.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: Color(0xFFf3f4f6),
        leading: IconButton(
          padding: EdgeInsets.all(5),
          icon: Icon(Icons.chevron_left, size: 30, color: Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 25,
        centerTitle: true,
        title: Text("Reset Data",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_forever, color: Colors.red, size: 60),
              SizedBox(height: 20),
              Text(
                'Reset All Offline Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'This will delete all chats, users, and settings stored locally on your device. This cannot be undone.',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.delete, color: Colors.white),
                label: Text('Reset Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(double.infinity, 48),
                ),
                onPressed: resetting ? null : _resetData,
              ),
              if (resetting) ...[
                SizedBox(height: 20),
                CircularProgressIndicator(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
