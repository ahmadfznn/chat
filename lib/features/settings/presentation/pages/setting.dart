import 'package:chat/components/popup.dart';
import 'package:chat/features/auth/presentation/pages/auth.dart';
import 'package:chat/features/chat/presentation/pages/chat_page.dart';
import 'package:chat/pages/data_usage_page.dart';
import 'package:chat/features/settings/presentation/pages/help_page.dart';
import 'package:chat/features/settings/presentation/pages/notification_page.dart';
import 'package:chat/features/settings/presentation/pages/personalization_page.dart';
import 'package:chat/features/settings/presentation/pages/privacy_page.dart';
import 'package:chat/pages/profile.dart';
import 'package:chat/features/settings/presentation/pages/reset_page.dart';
import 'package:chat/features/settings/presentation/pages/security_page.dart';
import 'package:chat/services/local_database.dart';
import 'package:chat/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Setting extends StatefulWidget {
  const Setting({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  _SettingState createState() => _SettingState();
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

class _SettingState extends State<Setting> {
  final LocalDatabase dbs = LocalDatabase.instance;
  late Map<String, dynamic> user;

  @override
  void initState() {
    super.initState();
    user = Map.from(widget.user);
  }

  Future<void> refreshProfile() async {}

  Future<void> logout(BuildContext context) async {
    await Navigator.of(context).maybePop();
    FlutterSecureStorage storage = FlutterSecureStorage();
    await UserService(widget.user['id'])
        .setUserSignInStatus(widget.user['id'], false);

    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await storage.deleteAll();

    if (mounted) {
      Popup().show(context, "Sign out Successfully", true);
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      await Navigator.pushReplacement(
          context,
          _goPage(const Auth(
            page: 0,
          )));
    }
  }

  void openDialog(BuildContext context, CupertinoAlertDialog dialog) {
    showCupertinoModalPopup(context: context, builder: (context) => dialog);
  }

  void clear() async {
    await dbs.resetDatabase();
  }

  // Helper method to build a styled setting tile
  Widget buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
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
          color: Color(0x33E2E8F0),
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
        onTap: onTap,
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        trailing:
            Icon(Icons.chevron_right_outlined, color: Colors.grey.shade700),
        tileColor: Colors.transparent,
      ),
    );
  }

  // Build a group of setting options from a given list
  Widget buildSettingGroup(String header, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
          child: Text(header, style: TextStyle(color: Colors.grey.shade600)),
        ),
        ...items.map(
          (item) => buildSettingTile(
            icon: item['icon'],
            title: item['title'],
            onTap: item['onTap'],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define groups of settings
    final List<Map<String, dynamic>> accountSettings = [
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notification',
        'onTap': () {
          Navigator.push(context, _goPage(NotificationPage(user: user)));
        },
      },
      {
        'icon': Icons.lock_outline,
        'title': 'Privacy',
        'onTap': () async {
          await Navigator.push(
              context, _goPage(PrivacyPage(user: widget.user)));
        },
      },
      {
        'icon': Icons.shield_outlined,
        'title': 'Security',
        'onTap': () async {
          await Navigator.push(
              context, _goPage(SecurityPage(user: widget.user)));
        },
      },
      {
        'icon': Icons.color_lens_outlined,
        'title': 'Personalization',
        'onTap': () async {
          await Navigator.push(
              context, _goPage(PersonalizationPage(user: widget.user)));
        },
      },
      {
        'icon': Icons.chat_outlined,
        'title': 'Chat',
        'onTap': () async {
          await Navigator.push(context, _goPage(ChatPage(user: widget.user)));
        },
      },
    ];

    final List<Map<String, dynamic>> dataSettings = [
      {
        'icon': Icons.data_exploration_outlined,
        'title': 'Data Usage',
        'onTap': () async {
          await Navigator.push(
              context, _goPage(DataUsagePage(user: widget.user)));
        },
      },
      {
        'icon': Icons.delete_outline_outlined,
        'title': 'Reset Data',
        'onTap': () async {
          await Navigator.push(context, _goPage(ResetPage(user: widget.user)));
        },
      },
    ];

    final List<Map<String, dynamic>> otherSettings = [
      {
        'icon': Icons.help_outline,
        'title': 'Help',
        'onTap': () async {
          await Navigator.push(context, _goPage(HelpPage()));
        },
      },
      {
        'icon': Icons.logout_outlined,
        'title': 'Logout',
        'onTap': () {
          openDialog(
            context,
            CupertinoAlertDialog(
              title: const Text("Logout"),
              content: const Text("Are you sure to logout now?"),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("No"),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    logout(context);
                  },
                  child: const Text("Yes"),
                ),
              ],
            ),
          );
        },
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0xFFf3f4f6),
        leading: IconButton(
          padding: const EdgeInsets.all(5),
          icon: Icon(Icons.chevron_left, size: 30, color: Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 25,
        centerTitle: true,
        title: const Text("Setting",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ),
      body: RefreshIndicator(
        onRefresh: refreshProfile,
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: widget.user['profile_picture'] !=
                                      null
                                  ? NetworkImage(widget.user['profile_picture'])
                                  : const AssetImage("assets/img/user.png")
                                      as ImageProvider,
                              radius: 70,
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: IconButton(
                                onPressed: () async {
                                  var updatedUser = await Navigator.push(
                                      context,
                                      _goPage(Profile(user: widget.user)));
                                  setState(() {
                                    user = updatedUser;
                                  });
                                },
                                icon: const Icon(Icons.edit),
                                iconSize: 25,
                                style: ButtonStyle(
                                  backgroundColor:
                                      const MaterialStatePropertyAll(
                                          Colors.grey),
                                ),
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(widget.user['displayName'] ?? "",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800)),
                        Text("@${widget.user['username']}",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade500)),
                        const SizedBox(height: 5),
                        Text("Mobile Developer | Coding lover | Stay focus",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600))
                      ],
                    ),
                  ),
                  // Build settings groups using the helper method
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        buildSettingGroup("Account", accountSettings),
                        buildSettingGroup("Data & Storage", dataSettings),
                        buildSettingGroup("Other", otherSettings),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
