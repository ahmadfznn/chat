import 'package:flutter/material.dart';

class DataUsagePage extends StatefulWidget {
  const DataUsagePage({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  DataUsagePageState createState() => DataUsagePageState();
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
      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: Curves.easeInOutExpo));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

class DataUsagePageState extends State<DataUsagePage> {
  bool notifAll = false;

  @override
  void initState() {
    super.initState();
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
        title: Text(
          "Data Usage",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: 1,
        itemBuilder: (context, index) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: Text(
                          "Enable All Notifications",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        tileColor: Colors.white,
                        shape: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        value: notifAll,
                        onChanged:
                            (value) => {
                              setState(() {
                                notifAll = value;
                              }),
                            },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
