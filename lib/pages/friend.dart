import 'package:chat/controllers/chat_controller.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/features/chat/presentation/pages/detail_chat.dart';
import 'package:chat/pages/user_profile.dart';
import 'package:chat/services/room_service.dart';
import 'package:chat/services/user_service.dart';
import 'package:flutter/material.dart';

class Friend extends StatefulWidget {
  const Friend({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  _FriendState createState() => _FriendState();
}

Route _goPage(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
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

class _FriendState extends State<Friend> {
  ChatController chatController = ChatController();
  TextEditingController searchController = TextEditingController();
  late UserService _userService;
  late RoomService _roomService;

  @override
  void initState() {
    super.initState();
    _roomService = RoomService(widget.user['id']);
    _userService = UserService(widget.user['username']);
    _userService.fetchUsers(widget.user['username']);
  }

  @override
  void dispose() {
    _roomService.dispose();
    _userService.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> changeFriendship(String userId) async {
    await _userService.toggleFriendship(widget.user, userId);
  }

  Future<void> _refreshUser() async {
    _userService.fetchUsers(widget.user['username']);
  }

  Future<void> openRoom(String id) async {
    Map<String, dynamic> res =
        await _roomService.openRoom(widget.user['id'], id);
    if (res['status']) {
      Navigator.pop(context);
      await Navigator.push(
        context,
        _goPage(DetailChat(data: res['data'], user: widget.user)),
      );
    }
  }

  void _navigateToUserProfile(BuildContext context, UserModel user) async {
    await Navigator.push(
      context,
      _goPage(
        UserProfile(
          data: user,
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(top: 35),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFf3f4f6),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                          const Text(
                            "Friend",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Updated search input using TextField with layout.dart style
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          hintText: "Search friend",
                          filled: true,
                          fillColor: const Color(0xFFf9fafb),
                          contentPadding: const EdgeInsets.all(15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: StreamBuilder<List<UserModel>>(
          stream: _userService.userStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2FBEFF)),
              );
            }
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading users"));
            }
            List<UserModel> users = snapshot.data ?? [];
            return RefreshIndicator(
              onRefresh: _refreshUser,
              color: Colors.white,
              child: users.isEmpty
                  ? ListView.builder(
                      itemCount: 1,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.65,
                          child: const Center(child: Text("Users Empty")),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        var user = users[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                            key: ValueKey(user.id),
                            minVerticalPadding: 10,
                            onTap: () {
                              openRoom(user.id);
                            },
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 7, horizontal: 10),
                            leading: GestureDetector(
                              onTap: () {
                                _navigateToUserProfile(context, user);
                              },
                              child: user.profilePicture != null &&
                                      user.profilePicture!.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(user.profilePicture!),
                                      radius: 25,
                                    )
                                  : Image.asset("assets/img/user.png"),
                            ),
                            title: Text(
                              user.name ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              user.bio ?? "",
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: FilledButton(
                              onPressed: () {
                                changeFriendship(user.id);
                              },
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                  !user.isFriend ? Colors.blue : Colors.red,
                                ),
                                foregroundColor:
                                    MaterialStateProperty.all(Colors.white),
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.all(0),
                                ),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              child: SizedBox(
                                width: 150,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.group,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      !user.isFriend
                                          ? "Add Friend"
                                          : "Remove Friend",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}
