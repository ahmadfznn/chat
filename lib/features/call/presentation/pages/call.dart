import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class Call extends StatefulWidget {
  const Call({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  _CallState createState() => _CallState();
}

class _CallState extends State<Call> {
  // Sample call data; replace with your actual data source
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

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint("Camera button pressed");
        },
        backgroundColor: const Color(0xFF2fbffb),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: Icon(IconsaxPlusBold.call, size: 30),
      ),
      body: ListView.builder(
        itemCount: callList.length,
        itemBuilder: (context, index) {
          final call = callList[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(call['name']),
            subtitle: Text(_formatDate(call['date'])),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Handle options here
              },
            ),
          );
        },
      ),
    );
  }
}
