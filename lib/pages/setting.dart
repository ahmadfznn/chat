import 'package:chat/components/popup.dart';
import 'package:chat/pages/auth/auth.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:chat/pages/data_usage_page.dart';
import 'package:chat/pages/help_page.dart';
import 'package:chat/pages/notification_page.dart';
import 'package:chat/pages/personalization_page.dart';
import 'package:chat/pages/privacy_page.dart';
import 'package:chat/pages/profile.dart';
import 'package:chat/pages/reset_page.dart';
import 'package:chat/pages/security_page.dart';
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
      // ignore: use_build_context_synchronously
      Popup().show(context, "Sign out Successfully", true);
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      await Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
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
          title: Text("Setting",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
        body: RefreshIndicator(
          onRefresh: refreshProfile,
          child: ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(20),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                      widget.user['profile_picture'] != null
                                          ? NetworkImage(
                                              widget.user['profile_picture'])
                                          : AssetImage("assets/img/user.png"),
                                  radius: 70,
                                ),
                                Positioned(
                                    bottom: 5,
                                    right: 5,
                                    child: IconButton(
                                      onPressed: () async {
                                        var updatedUser = await Navigator.push(
                                            context,
                                            _goPage(
                                                Profile(user: widget.user)));
                                        setState(() {
                                          user = updatedUser;
                                        });
                                      },
                                      icon: Icon(Icons.edit),
                                      iconSize: 25,
                                      style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                  Colors.grey)),
                                      color: Colors.white,
                                    ))
                              ],
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Text(widget.user['displayName'] ?? "",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800)),
                            Text("@${widget.user['username']}",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade500)),
                            SizedBox(
                              height: 5,
                            ),
                            Text("Mobile Developer | Coding lover | Stay focus",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.shade600))
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                "Account",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.notifications_outlined,
                                color: Colors.blue,
                              ),
                              title: Text(
                                "Notification",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              trailing: Icon(Icons.chevron_right_outlined,
                                  color: Colors.grey.shade700),
                              tileColor: Colors.white,
                              onTap: () {
                                Navigator.push(context,
                                    _goPage(NotificationPage(user: user)));
                              },
                              shape: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey.shade300)),
                            ),
                            ListTile(
                              onTap: () async {
                                await Navigator.push(context,
                                    _goPage(PrivacyPage(user: widget.user)));
                              },
                              leading: Icon(
                                Icons.lock_outline,
                                color: Colors.blue,
                              ),
                              title: Text(
                                "Privacy",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              trailing: Icon(Icons.chevron_right_outlined,
                                  color: Colors.grey.shade700),
                              tileColor: Colors.white,
                              shape: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey.shade300)),
                            ),
                            ListTile(
                              onTap: () async {
                                await Navigator.push(context,
                                    _goPage(SecurityPage(user: widget.user)));
                              },
                              leading: Icon(
                                Icons.shield_outlined,
                                color: Colors.blue,
                              ),
                              title: Text(
                                "Security",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              trailing: Icon(Icons.chevron_right_outlined,
                                  color: Colors.grey.shade700),
                              tileColor: Colors.white,
                              shape: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey.shade300)),
                            ),
                            ListTile(
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    _goPage(PersonalizationPage(
                                        user: widget.user)));
                              },
                              leading: Icon(
                                Icons.color_lens_outlined,
                                color: Colors.blue,
                              ),
                              title: Text(
                                "Personalization",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              trailing: Icon(Icons.chevron_right_outlined,
                                  color: Colors.grey.shade700),
                              tileColor: Colors.white,
                              shape: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey.shade300)),
                            ),
                            ListTile(
                              onTap: () async {
                                await Navigator.push(context,
                                    _goPage(ChatPage(user: widget.user)));
                              },
                              leading: Icon(
                                Icons.chat_outlined,
                                color: Colors.blue,
                              ),
                              title: Text(
                                "Chat",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              trailing: Icon(Icons.chevron_right_outlined,
                                  color: Colors.grey.shade700),
                              tileColor: Colors.white,
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                "Data & Storage",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            ListTile(
                              onTap: () async {
                                await Navigator.push(context,
                                    _goPage(DataUsagePage(user: widget.user)));
                              },
                              leading: Icon(
                                Icons.data_exploration_outlined,
                                color: Colors.blue,
                              ),
                              title: Text(
                                "Data Usage",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              trailing: Icon(Icons.chevron_right_outlined,
                                  color: Colors.grey.shade700),
                              tileColor: Colors.white,
                              shape: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey.shade300)),
                            ),
                            ListTile(
                              onTap: () async {
                                await Navigator.push(context,
                                    _goPage(ResetPage(user: widget.user)));
                              },
                              leading: Icon(
                                Icons.delete_outline_outlined,
                                color: Colors.blue,
                              ),
                              title: Text(
                                "Reset Data",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              trailing: Icon(Icons.chevron_right_outlined,
                                  color: Colors.grey.shade700),
                              tileColor: Colors.white,
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                "Other",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            ListTile(
                              onTap: () async {
                                await Navigator.push(
                                    context, _goPage(HelpPage()));
                              },
                              leading: Icon(
                                Icons.help_outline,
                                color: Colors.blue,
                              ),
                              title: Text(
                                "Help",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              trailing: Icon(Icons.chevron_right_outlined,
                                  color: Colors.grey.shade700),
                              tileColor: Colors.white,
                              shape: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey.shade300)),
                            ),
                            ListTile(
                              onTap: () {
                                openDialog(
                                  context,
                                  CupertinoAlertDialog(
                                    title: const Text("Logout"),
                                    content: const Text(
                                        "Are you sure to logout now?"),
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
                              leading: Icon(
                                Icons.logout_outlined,
                                color: Colors.blue,
                              ),
                              title: Text(
                                "Logout",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              trailing: Icon(Icons.chevron_right_outlined,
                                  color: Colors.grey.shade700),
                              tileColor: Colors.white,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }),
        ));
  }
}
