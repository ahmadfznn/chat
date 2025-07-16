import 'dart:ui';

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

class _ChatState extends State<Chat> with TickerProviderStateMixin {
  final ChatController chatController = Get.find();
  late RoomService _roomService;
  late MessageService _messageService;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _roomService = RoomService(widget.user["id"]);
    _roomService.fetchChatRooms(widget.user["id"]);
    _messageService = MessageService("ai_chat", widget.user["id"]);
    _messageService.fetchMessages("ai_chat", widget.user["id"]);

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
    _roomService.dispose();
    _fabController.dispose();
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
                        IconsaxPlusBold.message_add,
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
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _roomService.chatRoomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
                strokeWidth: 3,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "Chat Empty",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            );
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
              color: const Color(0xFF3B82F6),
              child: filteredRooms.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          "No chats found",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // AI Chat Section with Futuristic Style
                        Container(
                          margin: const EdgeInsets.only(
                              bottom: 8, top: 16, left: 16, right: 16),
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
                          child: StreamBuilder<List<MessageModel>>(
                            stream: _messageService.messagesStream,
                            builder: (context, snapshot) {
                              String subtitleText = "No messages yet";
                              if (snapshot.hasData &&
                                  snapshot.data!.isNotEmpty) {
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
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      _goPage(AiChat(user: widget.user)),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // AI Avatar with Gradient
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF3B82F6),
                                                Color(0xFF06B6D4),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(28),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF3B82F6)
                                                    .withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                              BoxShadow(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                blurRadius: 1,
                                                offset: const Offset(0, 1),
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.smart_toy_outlined,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Chat Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "AI Chat",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                subtitleText,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      const Color(0xFF64748B),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Regular Chat List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                                      data: data, user: widget.user)),
                                );
                              }
                            }

                            return Obx(() {
                              return Container(
                                margin: const EdgeInsets.only(
                                    bottom: 8, left: 16, right: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: chatController.selectedChat
                                            .contains(data.id)
                                        ? [
                                            const Color(0x1A3B82F6),
                                            const Color(0x1A06B6D4),
                                          ]
                                        : [
                                            const Color(0x80FFFFFF),
                                            const Color(0x80F8FAFC),
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
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: handleTap,
                                    onLongPress: handleLongPress,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Profile Picture with Online Status
                                          Stack(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  _showProfileDialog(
                                                      context, data);
                                                },
                                                child: Container(
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        _getGradientForUser(
                                                            data.recipientName),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            28),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: _getGradientForUser(
                                                                data.recipientName)
                                                            .colors
                                                            .first
                                                            .withOpacity(0.3),
                                                        blurRadius: 12,
                                                        offset:
                                                            const Offset(0, 4),
                                                      ),
                                                      BoxShadow(
                                                        color: Colors.white
                                                            .withOpacity(0.2),
                                                        blurRadius: 1,
                                                        offset:
                                                            const Offset(0, 1),
                                                        spreadRadius: 0,
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            28),
                                                    child: (data.recipientPhoto !=
                                                                null &&
                                                            data.recipientPhoto!
                                                                .isNotEmpty)
                                                        ? Image.network(
                                                            data.recipientPhoto!,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (context, error,
                                                                    stackTrace) {
                                                              return Container(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Text(
                                                                  data.recipientName
                                                                          .isNotEmpty
                                                                      ? data
                                                                          .recipientName[
                                                                              0]
                                                                          .toUpperCase()
                                                                      : '?',
                                                                  style:
                                                                      const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          )
                                                        : Container(
                                                            alignment: Alignment
                                                                .center,
                                                            child: Text(
                                                              data.recipientName
                                                                      .isNotEmpty
                                                                  ? data
                                                                      .recipientName[
                                                                          0]
                                                                      .toUpperCase()
                                                                  : '?',
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                              // Online Status Indicator
                                              StreamBuilder<
                                                  Map<String, dynamic>>(
                                                stream: StatusService()
                                                    .getUserOnlineStatus(
                                                        data.recipientId),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData) {
                                                    return const SizedBox
                                                        .shrink();
                                                  }
                                                  bool isOnline = snapshot
                                                          .data!['status'] ??
                                                      false;
                                                  if (isOnline) {
                                                    return Positioned(
                                                      bottom: 2,
                                                      right: 2,
                                                      child: Container(
                                                        width: 16,
                                                        height: 16,
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              const LinearGradient(
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                            colors: [
                                                              Color(0xFF10B981),
                                                              Color(0xFF34D399),
                                                            ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          border: Border.all(
                                                            color: Colors.white,
                                                            width: 3,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: const Color(
                                                                      0xFF10B981)
                                                                  .withOpacity(
                                                                      0.3),
                                                              blurRadius: 6,
                                                              offset:
                                                                  const Offset(
                                                                      0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    return const SizedBox
                                                        .shrink();
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 16),
                                          // Chat Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  data.recipientName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                StreamBuilder(
                                                  stream: StatusService()
                                                      .getUserTypingStatus(
                                                          data.id,
                                                          data.recipientId),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      bool isTyping =
                                                          snapshot.data![
                                                                  'status'] ??
                                                              false;
                                                      if (isTyping) {
                                                        return const Text(
                                                          'Typing...',
                                                          style: TextStyle(
                                                            color: Color(
                                                                0xFF10B981),
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        );
                                                      }
                                                    }

                                                    if (data.type == 'text') {
                                                      return Text(
                                                        data.lastMessage ?? '',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Color(0xFF64748B),
                                                          height: 1.4,
                                                        ),
                                                      );
                                                    } else if (data
                                                        .type!.isNotEmpty) {
                                                      return Row(
                                                        children: [
                                                          Icon(
                                                            data.type != 'file'
                                                                ? Icons.photo
                                                                : Icons.folder,
                                                            color: const Color(
                                                                0xFF64748B),
                                                            size: 16,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            data.type == 'image'
                                                                ? '[Image]'
                                                                : data.type ==
                                                                        'video'
                                                                    ? '[Video]'
                                                                    : '[File]',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              color: Color(
                                                                  0xFF64748B),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    } else {
                                                      return const SizedBox
                                                          .shrink();
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Time and Unread Badge
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                data.status != -1
                                                    ? formatTimeTo24Hour(
                                                        data.updatedAt)
                                                    : '',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF94A3B8),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (data.status == 2 &&
                                                  data.unread != 0) ...[
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Color(0xFF3B82F6),
                                                        Color(0xFF06B6D4),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFF3B82F6)
                                                            .withOpacity(0.3),
                                                        blurRadius: 6,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    data.unread.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            });
                          },
                        ),
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

LinearGradient _getGradientForUser(String name) {
  final hash = name.hashCode;
  final gradients = [
    const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    ),
    const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
    ),
    const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
    const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    ),
    const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
    ),
  ];
  return gradients[hash.abs() % gradients.length];
}
