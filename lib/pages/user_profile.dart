import 'dart:ui';

import 'package:chat/models/user_model.dart';
import 'package:chat/pages/call_screen.dart';
import 'package:chat/pages/detail_chat.dart';
import 'package:chat/services/agora_service.dart';
import 'package:chat/services/room_service.dart';
import 'package:chat/services/status_service.dart';
import 'package:chat/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key, required this.data, required this.user});
  final UserModel data;
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  _UserProfileState createState() => _UserProfileState();
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

class _UserProfileState extends State<UserProfile> {
  late RoomService _roomService;
  late UserService _userService;
  UserModel? userData;

  @override
  void initState() {
    super.initState();
    _roomService = RoomService(widget.user['id']);
    _userService = UserService(widget.user['username']);
    setState(() {
      userData = widget.data;
    });
  }

  @override
  void dispose() {
    _roomService.dispose();
    _userService.dispose();
    super.dispose();
  }

  Future<void> refreshProfile() async {}

  Future<void> openRoom() async {
    Map<String, dynamic> res =
        await _roomService.openRoom(widget.user['id'], widget.data.id);
    if (res['status']) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      await Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        _goPage(DetailChat(data: res['data'], user: widget.user)),
      );
    }
  }

  Future<void> changeFriendship() async {
    await _userService.toggleFriendship(widget.user, widget.data.id);

    setState(() {
      userData = userData!.copyWith(isFriend: !userData!.isFriend);
    });
  }

  Future<void> initiateCall(String fromUserId, String toUserId) async {
    final channelName = '$fromUserId\_$toUserId';

    await FirebaseFirestore.instance.collection('calls').doc(toUserId).set({
      'from': fromUserId,
      'channel': channelName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await AgoraService.init(channelName, "");

    await Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      _goPage(CallScreen(
        channelName: channelName,
        token: "",
      )),
    );
  }

  void openDialog(BuildContext context, CupertinoAlertDialog dialog) {
    showCupertinoModalPopup(context: context, builder: (context) => dialog);
  }

  late OverlayEntry _overlayEntry;

  void _showOverlay(BuildContext context) {
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _overlayEntry.remove();
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 2,
                  sigmaY: 2,
                ),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          Positioned(
            top: 49.5,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      _overlayEntry.remove();
                    },
                    child: Icon(
                      Icons.settings,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(5),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _overlayEntry.remove();

                              openDialog(
                                context,
                                CupertinoAlertDialog(
                                  title: const Text("Clear Chat"),
                                  content: const Text(
                                      "Are you sure to clear this chat?"),
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
                                      onPressed: () {},
                                      child: const Text("Yes"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(
                                  left: 20, right: 20, top: 7, bottom: 15),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    IconsaxPlusLinear.trash,
                                    color: Colors.black,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text('Clear Chat'),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry);
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
            icon: Icon(Icons.chevron_left, size: 30, color: Colors.grey[600]),
            onPressed: () {
              // Navigator.pop(context);
              print("Hello");
            },
          ),
          leadingWidth: 50,
          centerTitle: true,
          title: Text("Profile",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          actions: [
            IconButton(
                icon: Icon(Icons.settings, color: Colors.blue),
                onPressed: () {
                  _showOverlay(context);
                }),
          ],
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
                                  backgroundImage: widget.data.profilePicture !=
                                              null &&
                                          widget.data.profilePicture!.isNotEmpty
                                      ? NetworkImage(
                                          widget.data.profilePicture!)
                                      : AssetImage("assets/img/user.png"),
                                  radius: 70,
                                ),
                                StreamBuilder<Map<String, dynamic>>(
                                    stream: StatusService()
                                        .getUserOnlineStatus(widget.data.id),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: Container(),
                                        );
                                      }

                                      bool isOnline =
                                          snapshot.data!['status'] ?? false;
                                      if (isOnline) {
                                        return Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                                color: Colors.green,
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
                                                borderRadius:
                                                    BorderRadius.circular(11)),
                                          ),
                                        );
                                      } else {
                                        return Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: Container(),
                                        );
                                      }
                                    })
                              ],
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Text(userData!.name ?? "",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800)),
                            Text("@${userData!.username}",
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
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: FilledButton(
                                  onPressed: openRoom,
                                  style: ButtonStyle(
                                      backgroundColor:
                                          WidgetStatePropertyAll(Colors.blue),
                                      foregroundColor:
                                          WidgetStatePropertyAll(Colors.white),
                                      padding: WidgetStatePropertyAll(
                                          EdgeInsets.all(15)),
                                      shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)))),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        IconsaxPlusLinear.messages_2,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        "Message",
                                        style: TextStyle(fontSize: 16),
                                      )
                                    ],
                                  )),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            IconButton(
                                padding: EdgeInsets.all(15),
                                style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Colors.grey[300],
                                    ),
                                    shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)))),
                                onPressed: changeFriendship,
                                icon: Icon(userData!.isFriend
                                    ? Icons.person_outline
                                    : Icons.person_add_alt)),
                            SizedBox(
                              width: 10,
                            ),
                            IconButton(
                                padding: EdgeInsets.all(15),
                                style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Colors.grey[300],
                                    ),
                                    shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)))),
                                onPressed: () async {
                                  await initiateCall(
                                      widget.user['id'], userData!.id);
                                },
                                icon: Icon(Icons.phone_outlined)),
                            SizedBox(
                              width: 10,
                            ),
                            IconButton(
                                padding: EdgeInsets.all(15),
                                style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Colors.grey[300],
                                    ),
                                    shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)))),
                                onPressed: () {},
                                icon: Icon(Icons.video_call_outlined)),
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
