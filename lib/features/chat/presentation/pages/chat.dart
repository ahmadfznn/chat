import 'package:chat/controllers/chat_controller.dart';
import 'package:chat/core/utils/format_time.dart';
import 'package:chat/features/chat/data/datasources/message_service.dart';
import 'package:chat/features/chat/presentation/pages/ai_chat.dart';
import 'package:chat/models/chat_room_model.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/features/chat/presentation/pages/detail_chat.dart';
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
  late MessageService _messageService;

  @override
  void initState() {
    super.initState();
    _roomService = RoomService(widget.user["id"]);
    _roomService.fetchChatRooms(widget.user["id"]);
    _messageService = MessageService("ai_chat", widget.user["id"]);
    _messageService.fetchMessages("ai_chat", widget.user["id"]);
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

  void _showProfileDialog(BuildContext context, ChatRoomModel data) {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: (data.recipientPhoto != null &&
                          data.recipientPhoto!.isNotEmpty)
                      ? NetworkImage(data.recipientPhoto!)
                      : const AssetImage("assets/img/user.png")
                          as ImageProvider,
                ),
                const SizedBox(height: 16),
                Text(
                  data.recipientName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ProfileDialogAction(
                      icon: Icons.call,
                      label: "Call",
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _ProfileDialogAction(
                      icon: Icons.videocam,
                      label: "Video Call",
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _ProfileDialogAction(
                      icon: Icons.person,
                      label: "View Profile",
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToUserProfile(context, data.recipientId);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          _goPage(Friend(user: widget.user)),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const CircleBorder(),
        child: Icon(IconsaxPlusBold.message_add, size: 30),
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _roomService.chatRoomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2FBEFF)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chat Empty"));
          }
          List<ChatRoomModel> chatRooms = snapshot.data!;
          return Obx(() {
            String search =
                chatController.searchQuery.value.trim().toLowerCase();
            List<ChatRoomModel> filteredRooms = search.isEmpty
                ? chatRooms
                : chatRooms
                    .where((room) =>
                        room.recipientName.toLowerCase().contains(search))
                    .toList();
            return RefreshIndicator(
              onRefresh: _refreshChat,
              color: const Color(0xFF2FBEFF),
              child: filteredRooms.isEmpty
                  ? const Center(child: Text("No chats found"))
                  : Column(
                      children: [
                        // Fixed: Use a defined service for messages, using a local MessageService instance
                        StreamBuilder<List<MessageModel>>(
                          stream: _messageService.messagesStream,
                          builder: (context, snapshot) {
                            String subtitleText = "No messages yet";
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              final lastMessage = snapshot.data!.last;
                              if (lastMessage.type == "text") {
                                subtitleText = lastMessage.message;
                              } else if (lastMessage.type == "image") {
                                subtitleText = "[Image]";
                              } else if (lastMessage.type == "video") {
                                subtitleText = "[Video]";
                              } else if (lastMessage.type == "file") {
                                subtitleText = "[File]";
                              } else {
                                subtitleText = "[${lastMessage.type}]";
                              }
                            }
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 7, horizontal: 10),
                              leading: GestureDetector(
                                onTap: () {},
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      backgroundImage: const AssetImage(
                                          "assets/img/user.png"),
                                      radius: 25,
                                    ),
                                  ],
                                ),
                              ),
                              horizontalTitleGap: 10,
                              title: Text(
                                "AI Chat",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colorScheme.onSurface),
                              ),
                              subtitle: Text(
                                subtitleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7)),
                              ),
                              onLongPress: () {},
                              onTap: () {
                                Navigator.push(
                                  context,
                                  _goPage(AiChat(user: widget.user)),
                                );
                              },
                            );
                          },
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredRooms.length,
                          itemBuilder: (context, index) {
                            var data = filteredRooms[index];
                            void handleLongPress() {
                              if (!chatController.showSelect.value) {
                                chatController.showSelect.value = true;
                                chatController.selectedChat.add(data.id);
                              }
                            }

                            void handleTap() {
                              if (chatController.selectedChat
                                  .contains(data.id)) {
                                chatController.selectedChat.remove(data.id);
                                if (chatController.selectedChat.isEmpty) {
                                  chatController.showSelect.value = false;
                                }
                              } else if (chatController.showSelect.value) {
                                chatController.selectedChat.add(data.id);
                              } else {
                                Navigator.push(
                                    context,
                                    _goPage(DetailChat(
                                        data: data, user: widget.user)));
                              }
                            }

                            return Obx(() {
                              return ListTile(
                                key: ValueKey(data.id),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 7, horizontal: 10),
                                leading: GestureDetector(
                                  onTap: () {
                                    _showProfileDialog(context, data);
                                  },
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.white,
                                        backgroundImage: (data.recipientPhoto !=
                                                    null &&
                                                data.recipientPhoto!.isNotEmpty)
                                            ? NetworkImage(data.recipientPhoto!)
                                            : const AssetImage(
                                                "assets/img/user.png"),
                                        radius: 25,
                                      ),
                                      StreamBuilder<Map<String, dynamic>>(
                                          stream: StatusService()
                                              .getUserOnlineStatus(
                                                  data.recipientId),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return Positioned(
                                                bottom: 2,
                                                right: 2,
                                                child: Container(),
                                              );
                                            }
                                            bool isOnline =
                                                snapshot.data!['status'] ??
                                                    false;
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
                                                          color: Colors.white,
                                                          width: 1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7)),
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
                                tileColor: chatController.selectedChat
                                        .contains(data.id)
                                    // ignore: deprecated_member_use
                                    ? colorScheme.primaryContainer
                                        .withOpacity(0.5)
                                    : colorScheme.surface,
                                title: Text(
                                  data.recipientName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.onSurface),
                                ),
                                subtitle: StreamBuilder(
                                    stream: StatusService().getUserTypingStatus(
                                        data.id, data.recipientId),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return data.type == 'text'
                                            ? Text(
                                                data.lastMessage ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        colorScheme.onSurface),
                                              )
                                            : data.type!.isNotEmpty
                                                ? Row(
                                                    children: [
                                                      Icon(
                                                        data.type != 'file'
                                                            ? Icons.photo
                                                            : Icons.folder,
                                                        color: colorScheme
                                                            .onSurface
                                                            // ignore: deprecated_member_use
                                                            .withOpacity(0.6),
                                                      )
                                                    ],
                                                  )
                                                : Container();
                                      }
                                      bool isTyping =
                                          snapshot.data!['status'] ?? false;
                                      if (isTyping) {
                                        return Text(
                                          'Typing...',
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 14),
                                        );
                                      } else {
                                        return data.type == 'text'
                                            ? Text(
                                                data.lastMessage ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        colorScheme.onSurface),
                                              )
                                            : data.type!.isNotEmpty
                                                ? Row(
                                                    children: [
                                                      Icon(
                                                        data.type != 'file'
                                                            ? Icons.photo
                                                            : Icons.folder,
                                                        color: colorScheme
                                                            .onSurface
                                                            // ignore: deprecated_member_use
                                                            .withOpacity(0.6),
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
                                                WidgetStatePropertyAll(
                                                    colorScheme.primary),
                                            shape: WidgetStatePropertyAll(
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50))),
                                            padding: WidgetStatePropertyAll(
                                                EdgeInsets.zero),
                                          ),
                                          onPressed: () {},
                                          child: Text(data.unread.toString()),
                                        ),
                                      )
                                    : Text(
                                        data.status != -1
                                            ? formatTimeTo24Hour(data.updatedAt)
                                            : '',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurface),
                                      ),
                                onLongPress: handleLongPress,
                                onTap: handleTap,
                              );
                            });
                          },
                        )
                      ],
                    ),
            );
          });
        },
      ),
    );
  }
}

class _ProfileDialogAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileDialogAction(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            radius: 28,
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
