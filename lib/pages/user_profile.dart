import 'dart:ui';

import 'package:chat/models/user_model.dart';
import 'package:chat/features/call/presentation/pages/call_screen.dart';
import 'package:chat/features/chat/presentation/pages/detail_chat.dart';
import 'package:chat/features/call/data/datasources/agora_service.dart';
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
  _UserProfileState createState() => _UserProfileState();
}

Route _goPage(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    opaque: false,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: Curves.easeInOutCubic));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

class _UserProfileState extends State<UserProfile>
    with TickerProviderStateMixin {
  late RoomService _roomService;
  late UserService _userService;
  UserModel? userData;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  bool isPinned = false;

  @override
  void initState() {
    super.initState();
    _roomService = RoomService(widget.user['id']);
    _userService = UserService(widget.user['username']);
    setState(() {
      userData = widget.data;
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _roomService.dispose();
    _userService.dispose();
    super.dispose();
  }

  Future<void> refreshProfile() async {}

  Future<void> openRoom() async {
    Map<String, dynamic> res =
        await _roomService.openRoom(widget.user['id'], widget.data.id);
    if (res['status']) {
      Navigator.pop(context);
      await Navigator.push(
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
              onTap: () => _overlayEntry.remove(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuOption(
                      icon: IconsaxPlusLinear.trash,
                      label: 'Clear Chat',
                      onTap: () {
                        _overlayEntry.remove();
                        openDialog(
                          context,
                          CupertinoAlertDialog(
                            title: const Text("Clear Chat"),
                            content:
                                const Text("Are you sure to clear this chat?"),
                            actions: [
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                onPressed: () => Navigator.of(context).pop(),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry);
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey[700], size: 20),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeumorphicButton({
    required Widget child,
    required VoidCallback onPressed,
    Color? backgroundColor,
    EdgeInsets? padding,
    double? width,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        width: width,
        padding: padding ?? EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              offset: Offset(4, 4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return _buildNeumorphicButton(
      onPressed: onPressed,
      padding: EdgeInsets.all(16),
      child: Icon(
        icon,
        color: iconColor ?? Colors.grey[600],
        size: 24,
      ),
    );
  }

  Widget _buildStatusIndicator(bool isOnline) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isOnline ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: isOnline
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSharedSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.share, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Shared',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSharedItem(Icons.group, '3 Groups'),
                SizedBox(width: 12),
                _buildSharedItem(Icons.description, '12 Files'),
                SizedBox(width: 12),
                _buildSharedItem(Icons.image, '28 Photos'),
                SizedBox(width: 12),
                _buildSharedItem(Icons.audiotrack, '5 Audio'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedItem(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.push_pin, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Text(
                'Pin Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => setState(() => isPinned = !isPinned),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isPinned ? Colors.blue : Colors.grey[300],
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedAlign(
                duration: Duration(milliseconds: 300),
                alignment:
                    isPinned ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          child: _buildNeumorphicButton(
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.all(8),
            child: Icon(Icons.chevron_left, size: 24, color: Colors.grey[600]),
          ),
        ),
        leadingWidth: 56,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.blue, Colors.purple],
          ).createShader(bounds),
          child: Text(
            "Profile",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            child: _buildNeumorphicButton(
              onPressed: () => _showOverlay(context),
              padding: EdgeInsets.all(8),
              child: Icon(Icons.more_vert, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshProfile,
        color: Colors.blue,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 20),
                // Profile Section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.3),
                                  Colors.purple.withOpacity(0.3)
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: widget.data.profilePicture !=
                                          null &&
                                      widget.data.profilePicture!.isNotEmpty
                                  ? NetworkImage(widget.data.profilePicture!)
                                  : AssetImage("assets/img/user.png"),
                              radius: 60,
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: StreamBuilder<Map<String, dynamic>>(
                              stream: StatusService()
                                  .getUserOnlineStatus(widget.data.id),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return Container();
                                bool isOnline =
                                    snapshot.data!['status'] ?? false;
                                return _buildStatusIndicator(isOnline);
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ).createShader(bounds),
                        child: Text(
                          userData!.name ?? "",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "@${userData!.username}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Mobile Developer | Coding lover | Stay focus",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Action Buttons
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildNeumorphicButton(
                          onPressed: openRoom,
                          backgroundColor: Colors.blue,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(IconsaxPlusLinear.messages_2,
                                  color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Message",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      _buildActionButton(
                        icon: userData!.isFriend
                            ? Icons.person_outline
                            : Icons.person_add_alt,
                        onPressed: changeFriendship,
                      ),
                      SizedBox(width: 16),
                      _buildActionButton(
                        icon: Icons.phone_outlined,
                        onPressed: () async {
                          await initiateCall(widget.user['id'], userData!.id);
                        },
                      ),
                      SizedBox(width: 16),
                      _buildActionButton(
                        icon: Icons.video_call_outlined,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Glowing Divider
                Container(
                  height: 2,
                  margin: EdgeInsets.symmetric(horizontal: 48),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.blue,
                        Colors.transparent
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                SizedBox(height: 24),
                // Pin Section
                _buildPinSection(),
                SizedBox(height: 24),
                // Shared Section
                _buildSharedSection(),
                SizedBox(height: 24),
                // Last Seen
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, color: Colors.grey[400], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Last seen 2 hours ago',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
