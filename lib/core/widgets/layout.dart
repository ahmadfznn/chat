import 'dart:ui';

import 'package:chat/components/gradient_text.dart';
import 'package:chat/controllers/call_controller.dart';
import 'package:chat/controllers/chat_controller.dart';
import 'package:chat/controllers/route_controller.dart';
import 'package:chat/controllers/story_controller.dart';
import 'package:chat/features/call/presentation/pages/call.dart';
import 'package:chat/features/chat/presentation/pages/chat.dart';
import 'package:chat/features/settings/presentation/pages/setting.dart';
import 'package:chat/pages/story.dart';
import 'package:chat/services/room_service.dart';
import 'package:chat/services/user_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class Layout extends StatefulWidget {
  const Layout({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  _LayoutState createState() => _LayoutState();
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

class _LayoutState extends State<Layout> {
  final PageController _pageController = PageController(initialPage: 0);
  final ChatController chatController = Get.put(ChatController());
  final StoryController storyController = Get.put(StoryController());
  final CallController callController = Get.put(CallController());
  TextEditingController searchController = TextEditingController();
  List<Widget> page = [];
  bool loading = false;
  late UserService _userService;
  late RoomService _roomService;

  Function deleteFunction = () {};
  Function cancelFunction = () {};
  int _currentIndex = 0;
  int selectedCount = 0;
  bool selectedAll = false;

  List<String> title = [
    "Chat",
    "Story",
    "Call",
  ];

  @override
  void initState() {
    super.initState();
    routeController.currentRoute.value = "/layout";

    // Remove static page list, use direct instantiation in PageView
    searchController.addListener(_onSearchChanged);

    _userService = UserService(widget.user['username']);
    _roomService = RoomService(widget.user['id']);
    _userService.fetchUsers(widget.user['username']);
  }

  @override
  void dispose() {
    super.dispose();

    searchController.dispose();
  }

  void _onSearchChanged() async {
    String searchQuery = searchController.text;

    if (_currentIndex == 0) {
      // Update the chatController's searchQuery for real-time filtering
      chatController.searchQuery.value = searchQuery;
      // RoomService(widget.user['id']).searchRoom(searchQuery); // Not needed for local filtering
    } else if (_currentIndex == 1) {
      // storyController.searchData(searchQuery);
    } else if (_currentIndex == 2) {
      // callController.searchData(searchQuery);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  void _onPageChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  bool _areAllItemsSelected() {
    List<String> data;
    if (_currentIndex == 0) {
      data = chatController.selectedChat;
    } else if (_currentIndex == 1) {
      data = [];
    } else {
      data = [];
    }
    return false;
  }

  void deleteChatRooms() async {
    if (chatController.selectedChat.isNotEmpty) {
      await _roomService.deleteChatRooms(chatController.selectedChat);
      chatController.selectedChat.clear();
      setState(() {
        chatController.showSelect = false.obs;
      });
    }
  }

  void deleteData() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          clipBehavior: Clip.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          titlePadding: const EdgeInsets.only(top: 70, bottom: 10),
          contentPadding: const EdgeInsets.only(bottom: 12),
          actionsPadding: const EdgeInsets.all(0),
          title: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -110,
                child: ElevatedButton(
                  style: const ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.all(25)),
                    shape: WidgetStatePropertyAll(CircleBorder(
                      eccentricity: 0,
                      side: BorderSide(
                        color: Color(0xFFF6BDBD),
                        width: 3,
                      ),
                    )),
                    backgroundColor: WidgetStatePropertyAll(Color(0xFFFB4B4B)),
                  ),
                  onPressed: () {},
                  child: const Icon(
                    IconsaxPlusLinear.trash,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const Text(
                "Delete",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              )
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Are you sure you want to delete ${_areAllItemsSelected() ? "all" : "this"} ${title[_currentIndex]}?",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFC8C8C8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F8),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(10))),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: const ButtonStyle(
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                        backgroundColor:
                            WidgetStatePropertyAll(Color(0xFFD0DEEB)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                            color: Color(0xFF9BA9B9),
                            fontSize: 14,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: FilledButton(
                      style: const ButtonStyle(
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                        backgroundColor:
                            WidgetStatePropertyAll(Color(0xFFFB4B4B)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        deleteFunction();
                      },
                      child: const Text("Yes",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              color: colorScheme.background,
              child: Padding(
                padding: const EdgeInsets.only(right: 0, left: 0, top: 35),
                child: Column(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                        color: Color(0xFFf3f4f6),
                      ))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GradientText(
                            title[_currentIndex],
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.blue, Colors.green],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                              color: colorScheme.onBackground,
                            ),
                          ),
                          Obx(
                            () {
                              bool hasSelected = false;
                              selectedCount = 0;
                              bool hasData = false;

                              if (_currentIndex == 0) {
                                selectedCount =
                                    chatController.selectedChat.length;
                                hasSelected = chatController.showSelect.value;
                                hasData = selectedCount != 0;
                                deleteFunction = () {
                                  // chatController.deleteData(
                                  //   context,
                                  // );
                                  deleteChatRooms();
                                };
                                cancelFunction = () {
                                  chatController.selectedChat.clear();
                                  setState(() {
                                    chatController.showSelect = false.obs;
                                  });
                                  chatController.selectedChat.refresh();
                                };
                              } else if (_currentIndex == 1) {
                                selectedCount = storyController.data
                                    .where((e) => e['selected'])
                                    .length;
                                hasSelected = storyController.showSelect.value;
                                hasData = storyController.data
                                    .any((element) => element['selected']);
                                deleteFunction = () {
                                  if (storyController.data
                                      .any((element) => element['selected'])) {
                                    storyController.deleteData(
                                      context,
                                      storyController.data
                                          .where((e) => e['selected'] == true)
                                          .map((e) => e['id'])
                                          .toList(),
                                    );
                                  }
                                };

                                cancelFunction = () {
                                  for (var e in storyController.data) {
                                    e['selected'] = false;
                                  }
                                  setState(() {
                                    storyController.showSelect = false.obs;
                                  });

                                  storyController.data.refresh();
                                };
                              } else if (_currentIndex == 2) {
                                selectedCount = callController.data
                                    .where((e) => e['selected'])
                                    .length;
                                hasSelected = callController.showSelect.value;
                                hasData = callController.data
                                    .any((element) => element['selected']);
                                deleteFunction = () {
                                  if (callController.data
                                      .any((element) => element['selected'])) {
                                    callController.deleteData(
                                      context,
                                      callController.data
                                          .where((e) => e['selected'])
                                          .map((e) => e['id'])
                                          .toList(),
                                    );
                                  }
                                };

                                cancelFunction = () {
                                  for (var e in callController.data) {
                                    e['selected'] = false;
                                  }
                                  setState(() {
                                    callController.showSelect = false.obs;
                                  });
                                  callController.data.refresh();
                                };
                              }

                              return hasSelected
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Wrap(
                                        direction: Axis.horizontal,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          // Text(
                                          //   "($selectedCount selected)",
                                          //   style: const TextStyle(
                                          //       color: Colors.black,
                                          //       fontSize: 10,
                                          //       fontWeight: FontWeight.w400),
                                          // ),
                                          // const SizedBox(width: 5),
                                          GestureDetector(
                                            onTap: () {
                                              if (hasData) {
                                                deleteData();
                                              }
                                            },
                                            child: const Icon(
                                              IconsaxPlusLinear.trash,
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          GestureDetector(
                                            onTap: () {
                                              cancelFunction();
                                            },
                                            child: Text(
                                              "Cancel",
                                              style: TextStyle(
                                                  color:
                                                      colorScheme.onBackground,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  : Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFF8FAFC),
                                            Color(0xFFE2E8F0)
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                          BoxShadow(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            blurRadius: 1,
                                            offset: const Offset(0, 1),
                                            spreadRadius: 0,
                                          ),
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 1,
                                            offset: const Offset(0, -1),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(23),
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            Navigator.push(
                                                context,
                                                _goPage(Setting(
                                                    user: widget.user)));
                                          },
                                          child: const Icon(
                                            Icons.more_horiz,
                                            color: Color(0xFF64748B),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    );
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.7),
                                const Color(0xFFF8FAFC).withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0).withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: searchController,
                            autofocus: false,
                            cursorColor: const Color(0xFF1E293B),
                            cursorHeight: 20,
                            cursorWidth: 1.5,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                IconsaxPlusLinear.search_normal_1,
                                color: Color(0xFF94A3B8),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              hintText: "Search ${title[_currentIndex]}",
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 16,
                            ),
                            onChanged: (value) {
                              // Handle search
                            },
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.95),
              const Color(0xFFF8FAFC).withOpacity(0.95),
            ],
          ),
          border: Border(
            top: BorderSide(
              color: const Color(0xFFE2E8F0).withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(3, (index) {
                  final isActive = _currentIndex == index;
                  return GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: isActive
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF3B82F6).withOpacity(0.1),
                                  const Color(0xFF06B6D4).withOpacity(0.1),
                                ],
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: Icon(
                              _getIconForIndex(index, _currentIndex),
                              size: 24,
                              color: isActive
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF94A3B8),
                            ),
                            child: Text(title[index]),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChange,
        children: [
          Chat(user: widget.user),
          Story(user: widget.user),
          Call(user: widget.user),
        ],
      ),
    );
  }
}

IconData _getIconForIndex(int index, int currentIndex) {
  switch (index) {
    case 0:
      return currentIndex == index
          ? IconsaxPlusBold.messages_2
          : IconsaxPlusLinear.messages_2;
    case 1:
      return currentIndex == index
          ? IconsaxPlusBold.story
          : IconsaxPlusLinear.story;
    case 2:
      return currentIndex == index
          ? IconsaxPlusBold.call
          : IconsaxPlusLinear.call;
    default:
      return Icons.home_outlined;
  }
}
