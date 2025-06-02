import 'package:chat/controller/chat_controller.dart';
import 'package:chat/etc/format_time.dart';
import 'package:chat/models/chat_room_model.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/pages/detail_chat.dart';
import 'package:chat/pages/friend.dart';
import 'package:chat/pages/user_profile.dart';
import 'package:chat/services/local_database.dart';
import 'package:chat/services/room_service.dart';
import 'package:chat/services/status_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class Chat extends StatefulWidget {
  const Chat({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  _ChatState createState() => _ChatState();
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

class _ChatState extends State<Chat> with WidgetsBindingObserver {
  final ChatController chatController = Get.find();
  late RoomService _roomService;

  @override
  void initState() {
    super.initState();
    _roomService = RoomService(widget.user["id"]);
    _roomService.fetchChatRooms(widget.user["id"]);
  }

  @override
  void dispose() {
    _roomService.dispose();
    super.dispose();
  }

  Future<void> _refreshChat() async {
    _roomService.fetchChatRooms(widget.user["id"]);
  }

  void _navigateToUserProfile(BuildContext context, String userId) async {
    LocalDatabase db = LocalDatabase.instance;
    UserModel? user = await db.getUserById(userId);

    if (user != null) {
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        _goPage(
          UserProfile(
            data: user,
            user: widget.user,
          ),
        ),
      );
    } else {
      // ignore: avoid_print
      print("User tidak ditemukan di database lokal");
    }
  }

  void openProfilePicture(BuildContext context, ChatRoomModel data) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: 200,
            height: 270,
            child: Image.asset(
              "assets/img/user.png",
              fit: BoxFit.cover,
              width: 200,
              height: 200,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          _goPage(Friend(user: widget.user)),
        ),
        backgroundColor: const Color(0xFF2fbffb),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: Icon(IconsaxPlusBold.message_add, size: 30),
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _roomService.chatRoomsStream,
        builder: (context, snapshot) {
          print("StreamBuilder triggered. Data: ${snapshot.data}");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2FBEFF)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chat Empty"));
          }

          List<ChatRoomModel> chatRooms = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshChat,
            color: const Color(0xFF2FBEFF),
            child: ListView.builder(
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                var data = chatRooms[index];

                void handleLongPress() {
                  if (!chatController.showSelect.value) {
                    chatController.showSelect.value = true;
                    chatController.selectedChat.add(data.id);
                  }
                }

                void handleTap() {
                  if (chatController.selectedChat.contains(data.id)) {
                    chatController.selectedChat.remove(data.id);
                    if (chatController.selectedChat.isEmpty) {
                      chatController.showSelect.value = false;
                    }
                  } else if (chatController.showSelect.value) {
                    chatController.selectedChat.add(data.id);
                  } else {
                    Navigator.push(context,
                        _goPage(DetailChat(data: data, user: widget.user)));
                  }
                }

                return Obx(() {
                  return ListTile(
                    key: ValueKey(data.id),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                    leading: GestureDetector(
                      onTap: () {
                        // _navigateToUserProfile(context, data.recipientId);
                        openProfilePicture(context, data);
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            backgroundImage: (data.recipientPhoto != null &&
                                    data.recipientPhoto!.isNotEmpty)
                                ? NetworkImage(data.recipientPhoto!)
                                : AssetImage("assets/img/user.png"),
                            radius: 25,
                          ),
                          StreamBuilder<Map<String, dynamic>>(
                              stream: StatusService()
                                  .getUserOnlineStatus(data.recipientId),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(),
                                  );
                                }

                                bool isOnline =
                                    snapshot.data!['status'] ?? false;
                                if (isOnline) {
                                  return Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                          color: Colors.green,
                                          border: Border.all(
                                              color: Colors.white, width: 1),
                                          borderRadius:
                                              BorderRadius.circular(7)),
                                    ),
                                  );
                                } else {
                                  return Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(),
                                  );
                                }
                              })
                        ],
                      ),
                    ),
                    horizontalTitleGap: 10,
                    tileColor: chatController.selectedChat.contains(data.id)
                        ? Colors.grey[300]
                        : Colors.white,
                    title: Text(
                      data.recipientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: StreamBuilder(
                        stream: StatusService()
                            .getUserTypingStatus(data.id, data.recipientId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return data.type == 'text'
                                ? Text(
                                    data.lastMessage ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  )
                                : data.type!.isNotEmpty
                                    ? Row(
                                        children: [
                                          Icon(
                                            data.type != 'file'
                                                ? Icons.photo
                                                : Icons.folder,
                                            color: Colors.grey.shade600,
                                          )
                                        ],
                                      )
                                    : Container();
                          }

                          bool isTyping = snapshot.data!['status'] ?? false;

                          if (isTyping) {
                            return Text(
                              'Typing...',
                              style: const TextStyle(
                                  color: Colors.green, fontSize: 14),
                            );
                          } else {
                            return data.type == 'text'
                                ? Text(
                                    data.lastMessage ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  )
                                : data.type!.isNotEmpty
                                    ? Row(
                                        children: [
                                          Icon(
                                            data.type != 'file'
                                                ? Icons.photo
                                                : Icons.folder,
                                            color: Colors.grey.shade600,
                                          )
                                        ],
                                      )
                                    : Container();
                          }
                        }),
                    trailing: data.status == 2 && data.unread != 0
                        ? SizedBox(
                            width: 30,
                            height: 30,
                            child: FilledButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStatePropertyAll(Colors.blue),
                                shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(50))),
                                padding:
                                    WidgetStatePropertyAll(EdgeInsets.zero),
                              ),
                              onPressed: () {},
                              child: Text(data.unread.toString()),
                            ),
                          )
                        : Text(
                            data.status != -1
                                ? formatTimeTo24Hour(data.updatedAt)
                                : '',
                            style: const TextStyle(fontSize: 14),
                          ),
                    onLongPress: handleLongPress,
                    onTap: handleTap,
                  );
                });
              },
            ),
          );
        },
      ),
    );
  }
}
