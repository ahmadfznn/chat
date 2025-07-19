import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:chat/core/utils/format_time.dart';
import 'package:chat/models/chat_room_model.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/pages/full_screen_image_viewer.dart';
import 'package:chat/pages/user_profile.dart';
import 'package:chat/pages/video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:chat/services/local_database.dart';
import 'package:chat/features/chat/data/datasources/message_service.dart';
import 'package:chat/services/status_service.dart';
import 'package:chat/controllers/route_controller.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DetailChat extends StatefulWidget {
  const DetailChat({super.key, required this.data, required this.user});
  final ChatRoomModel data;
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  _DetailChatState createState() => _DetailChatState();
}

Route openImage(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    opaque: false,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final scaleTween = Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutExpo));
      final opacityTween = Tween<double>(begin: 0.8, end: 1.0);

      return FadeTransition(
        opacity: animation.drive(opacityTween),
        child: ScaleTransition(
          scale: animation.drive(scaleTween),
          child: child,
        ),
      );
    },
  );
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

class _DetailChatState extends State<DetailChat> with WidgetsBindingObserver {
  final StatusService _statusService = StatusService();
  TextEditingController inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _emojiShowing = false;
  final FocusNode _focusNode = FocusNode();
  late MessageService messageService;
  bool _isTyping = false;
  List<String> selectedChat = [];
  bool selectedMode = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String selectedLanguage = 'id_ID';
  Timer? _stopTimer;

  @override
  void initState() {
    super.initState();
    routeController.currentRoute.value = "/detailChat";

    messageService = MessageService(widget.data.id, widget.user['id']);
    messageService.fetchMessages(widget.data.id, widget.user['id']);
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _emojiShowing = false;
        });
      }
    });

    // _scrollController.addListener(() {
    //   if (_scrollController.position.pixels ==
    //       _scrollController.position.minScrollExtent) {
    //     messageService.fetchMessages(widget.data.id, isInitialLoad: false);
    //   }
    // });

    _initSpeech();

    inputController.addListener(() {
      setState(() {});
    });

    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) _scrollToBottom();
    });
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      // ignore: avoid_print
      onStatus: (status) => print("Status: $status"),
      // ignore: avoid_print
      onError: (error) => print("Error: $error"),
    );
    if (!available) {
      setState(() {
        inputController.text = "Speech recognition tidak tersedia.";
      });
    }
  }

  void _toggleRecording() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: selectedLanguage,
          onResult: (result) {
            setState(() {
              inputController.text = result.recognizedWords;
              inputController.selection = TextSelection.fromPosition(
                TextPosition(offset: inputController.text.length),
              );
            });
            _resetStopTimer();
          },
        );
      } else {
        setState(() {
          inputController.text = "Tidak dapat mengakses mikrofon!";
        });
      }
    }
  }

  void _resetStopTimer() {
    _stopTimer?.cancel();
    _stopTimer = Timer(Duration(seconds: 3), () {
      _stopSpeechRecognition();
    });
  }

  void _stopSpeechRecognition() {
    _speech.stop();
    setState(() => _isListening = false);
    _stopTimer?.cancel();
  }

  @override
  void dispose() {
    _speech.stop();

    inputController.dispose();
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // _scrollController.dispose();
    messageService.dispose();
    super.dispose();
  }

  void toggleEmojiKeyboard() {
    if (_emojiShowing) {
      setState(() {
        _emojiShowing = false;
      });
      _focusNode.requestFocus();
    } else {
      if (_focusNode.hasFocus) {
        FocusScope.of(context).unfocus();
        Future.delayed(Duration(milliseconds: 100), () {
          setState(() {
            _emojiShowing = true;
          });
        });
      } else {
        setState(() {
          _emojiShowing = true;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void onTyping() {
    if (!_isTyping) {
      _isTyping = true;
      _statusService.setTypingStatus(widget.data.id, true);
    }

    Future.delayed(Duration(seconds: 3), () {
      _isTyping = false;
    });
  }

  void sendMessage() async {
    final res = await messageService.sendMessage({
      "roomId": widget.data.id,
      "userId": widget.user['id'],
      "receiverId": widget.data.recipientId,
      "message": inputController.text.trim(),
      "type": "text"
    });

    if (res) {
      inputController.clear();
      _scrollToBottom();
    }
  }

  void pickMedia() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.image, color: Colors.blue),
            title: Text("Pilih Gambar"),
            onTap: () async {
              Navigator.pop(context);
              final ImagePicker picker = ImagePicker();
              XFile? image =
                  await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                sendFile(image.path, "image");
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.video_library, color: Colors.red),
            title: Text("Pilih Video"),
            onTap: () async {
              Navigator.pop(context);
              final ImagePicker picker = ImagePicker();
              XFile? video =
                  await picker.pickVideo(source: ImageSource.gallery);
              if (video != null) {
                sendFile(video.path, "video");
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.insert_drive_file, color: Colors.grey),
            title: Text("Pilih File"),
            onTap: () async {
              Navigator.pop(context);
              FilePickerResult? result = await FilePicker.platform.pickFiles();
              if (result != null && result.files.single.path != null) {
                sendFile(result.files.single.path!, "file");
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> sendFile(String filePath, String fileType) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef =
        FirebaseStorage.instance.ref().child("chat_files/$fileName");

    UploadTask uploadTask = storageRef.putFile(File(filePath));

    String? thumbnailPath;
    if (fileType == "video") {
      thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: filePath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 200,
        quality: 50,
      );
    }

    MessageModel tempMessage = MessageModel(
      id: fileName,
      roomId: widget.data.id,
      senderId: widget.user['id'],
      receiverId: widget.data.recipientId,
      message: "",
      type: fileType,
      localPath: filePath,
      thumbnailPath: thumbnailPath,
      timestamp: DateTime.now(),
      status: 0,
      uploadProgress: 0.0,
    );

    messageService.addLocalMessage(tempMessage);

    TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
    String fileUrl = await snapshot.ref.getDownloadURL();

    await messageService.sendMessage({
      "id": fileName,
      "roomId": widget.data.id,
      "userId": widget.user['id'],
      "receiverId": widget.data.recipientId,
      "message": fileUrl,
      "type": fileType,
      "localPath": filePath,
    });

    _scrollToBottom();
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

  void deleteChat() async {
    final res = await messageService.deleteChat(
        widget.data.id, selectedChat, widget.user['id']);
    if (res) {
      setState(() {
        selectedChat.clear();
        selectedMode = false;
      });
    }
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
                      Icons.menu,
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

  Stream<Map<String, dynamic>> combineStreams(
      Stream<Map<String, dynamic>> stream1,
      Stream<Map<String, dynamic>> stream2) {
    return Rx.combineLatest2(
        stream1,
        stream2,
        (a, b) => {
              "status": a['status'],
              "lastSeen": a['lastSeen'],
              "typing": b['status']
            });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.98),
                Color(0xFFF8FAFC).withOpacity(0.98),
              ],
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE2E8F0).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        leading: Container(
          margin: EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Color(0xFFF8FAFC).withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    blurRadius: 0,
                    offset: Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: Color(0xFF475569),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        leadingWidth: 50,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            _navigateToUserProfile(context, widget.data.recipientId);
          },
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFEC4899),
                          Color(0xFFF472B6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFEC4899).withOpacity(0.25),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 0,
                          offset: Offset(0, 1),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: widget.data.recipientPhoto != null &&
                              widget.data.recipientPhoto!.isNotEmpty
                          ? Image.network(
                              widget.data.recipientPhoto!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFEC4899),
                                        Color(0xFFF472B6),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.data.recipientName[0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFEC4899),
                                    Color(0xFFF472B6),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  widget.data.recipientName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF10B981),
                            Color(0xFF34D399),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data.recipientName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    StreamBuilder<Map<String, dynamic>>(
                      stream: combineStreams(
                        StatusService()
                            .getUserOnlineStatus(widget.data.recipientId),
                        StatusService().getUserTypingStatus(
                            widget.data.id, widget.data.recipientId),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container();
                        }

                        bool isOnline = snapshot.data!['status'] ?? false;
                        bool isTyping = snapshot.data!['typing'] ?? false;
                        dynamic lastSeen = snapshot.data!['lastSeen'];

                        return Text(
                          isTyping
                              ? "Typing..."
                              : isOnline
                                  ? "Online"
                                  : "Last seen ${formatTimeTo24Hour(lastSeen)}",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: selectedMode
            ? [
                _buildActionButton(
                  icon: Icons.star_outline,
                  color: Color(0xFFEC4899),
                  onPressed: () {},
                ),
                _buildActionButton(
                  icon: Icons.push_pin,
                  color: Color(0xFF10B981),
                  onPressed: () {},
                ),
                if (selectedChat.length == 1)
                  _buildActionButton(
                    icon: Icons.info_outline,
                    color: Color(0xFF3B82F6),
                    onPressed: () {},
                  ),
                _buildActionButton(
                  icon: Icons.delete,
                  color: Color(0xFFEF4444),
                  onPressed: () {
                    openDialog(
                      context,
                      CupertinoAlertDialog(
                        title: const Text("Delete Message"),
                        content:
                            const Text("Are you sure to delete this message?"),
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
                              Navigator.of(context).pop();
                              deleteChat();
                            },
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(width: 8),
              ]
            : [
                _buildActionButton(
                  icon: Icons.phone,
                  color: Color(0xFF10B981),
                  backgroundColor: Color(0xFF10B981).withOpacity(0.1),
                  onPressed: () {},
                ),
                _buildActionButton(
                  icon: Icons.video_call,
                  color: Color(0xFF3B82F6),
                  backgroundColor: Color(0xFF3B82F6).withOpacity(0.1),
                  onPressed: () {},
                ),
                _buildActionButton(
                  icon: Icons.menu,
                  color: Color(0xFF475569),
                  onPressed: () {
                    _showOverlay(context);
                  },
                ),
                SizedBox(width: 16),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF8FAFC),
                    Color(0xFFE2E8F0),
                    Color(0xFFF1F5F9),
                    Color(0xFFE0F2FE),
                    Color(0xFFF0F9FF),
                    Color(0xFFFEFCE8),
                  ],
                  stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                ),
              ),
              child: StreamBuilder<List<MessageModel>>(
                stream: messageService.messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Color(0xFFF8FAFC).withOpacity(0.95),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 32,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Color(0xFFF8FAFC).withOpacity(0.95),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 32,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          "Belum ada pesan",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }

                  var messages = snapshot.data!;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollToBottom();
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(24),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      bool isMe = message.senderId == widget.user['id'];
                      final bool isFirst = index == 0 ||
                          messages[index - 1].senderId != message.senderId;
                      final bool isLast = index == messages.length - 1 ||
                          messages[index + 1].senderId != message.senderId;

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        margin: EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onLongPress: () {
                            setState(() {
                              if (selectedChat.contains(message.id)) {
                                selectedChat.remove(message.id);
                                if (selectedChat.isEmpty) {
                                  selectedMode = false;
                                }
                              } else {
                                if (selectedChat.isEmpty) {
                                  selectedMode = true;
                                }
                                selectedChat.add(message.id);
                              }
                            });
                          },
                          onTap: () {
                            setState(() {
                              if (selectedMode &&
                                  !selectedChat.contains(message.id)) {
                                selectedChat.add(message.id);
                              } else if (selectedChat.contains(message.id)) {
                                selectedChat.remove(message.id);
                                if (selectedChat.isEmpty) {
                                  selectedMode = false;
                                }
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedChat.contains(message.id)
                                  ? Color(0xFFE2E8F0).withOpacity(0.7)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: selectedChat.contains(message.id)
                                ? EdgeInsets.all(8)
                                : EdgeInsets.zero,
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(maxWidth: 280),
                                child: _buildFuturisticMessage(
                                    context, message, isMe, isFirst, isLast),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.98),
                  Color(0xFFF8FAFC).withOpacity(0.98),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE2E8F0).withOpacity(0.2),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: 24),
                _buildInputAction(
                  icon: _emojiShowing
                      ? Icons.keyboard_alt_outlined
                      : Icons.emoji_emotions_outlined,
                  onPressed: toggleEmojiKeyboard,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Color(0xFFF8FAFC).withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Color(0xFFE2E8F0).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: inputController,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 1,
                      keyboardType: TextInputType.multiline,
                      autocorrect: true,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (value) => onTyping(),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        suffixIcon: _buildInputAction(
                          icon: Icons.attach_file,
                          onPressed: pickMedia,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                _buildInputAction(
                  icon: inputController.text.isNotEmpty && !_isListening
                      ? Icons.send
                      : _isListening
                          ? Icons.mic
                          : Icons.mic_none,
                  onPressed: () {
                    if (inputController.text.isNotEmpty && !_isListening) {
                      sendMessage();
                    } else {
                      _toggleRecording();
                    }
                  },
                  isSpecial: inputController.text.isNotEmpty || _isListening,
                ),
                SizedBox(width: 24),
              ],
            ),
          ),
          Offstage(
            offstage: !_emojiShowing,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.98),
                    Color(0xFFF8FAFC).withOpacity(0.98),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE2E8F0).withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: EmojiPicker(
                textEditingController: inputController,
                scrollController: _scrollController,
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  viewOrderConfig: const ViewOrderConfig(),
                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax: 28 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.2
                            : 1.0),
                    backgroundColor: Colors.transparent,
                  ),
                  skinToneConfig: const SkinToneConfig(),
                  categoryViewConfig: const CategoryViewConfig(
                    backgroundColor: Colors.transparent,
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    backgroundColor: Colors.transparent,
                  ),
                  searchViewConfig: const SearchViewConfig(
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildFuturisticMessage(BuildContext context, MessageModel message,
    bool isMe, bool isFirst, bool isLast) {
  return Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: isMe
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B82F6).withOpacity(0.9),
                Color(0xFF06B6D4).withOpacity(0.9),
              ],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF06B6D4).withOpacity(0.9),
                Color(0xFF3B82F6).withOpacity(0.9),
              ],
            ),
      borderRadius: BorderRadius.circular(24).copyWith(
        bottomLeft: isMe ? Radius.circular(24) : Radius.circular(8),
        bottomRight: isMe ? Radius.circular(8) : Radius.circular(24),
      ),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 32,
          offset: Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          child: _buildMessage(context, message, isMe, isFirst, isLast),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isMe) ...[
                SizedBox(width: 6),
                Icon(
                  Icons.done_all,
                  size: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

// Helper method to build input action buttons
Widget _buildInputAction({
  required IconData icon,
  required VoidCallback onPressed,
  bool isSpecial = false,
}) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isSpecial
            ? [
                Color(0xFFEC4899).withOpacity(0.1),
                Color(0xFFF472B6).withOpacity(0.1),
              ]
            : [
                Colors.white.withOpacity(0.8),
                Color(0xFFF8FAFC).withOpacity(0.8),
              ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSpecial ? Color(0xFFEC4899) : Color(0xFF475569),
          ),
        ),
      ),
    ),
  );
}

// Helper method to format time
String _formatTime(DateTime timestamp) {
  final now = DateTime.now();
  final messageTime = timestamp;

  if (now.day == messageTime.day &&
      now.month == messageTime.month &&
      now.year == messageTime.year) {
    return "${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}";
  }

  return "${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}";
}

Widget _buildMessage(BuildContext context, MessageModel message, bool isMe,
    bool isFirst, bool isLast) {
  if (message.type == "text") {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Text(
        message.message,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  } else if (message.type == "image") {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          openImage(
            FullScreenImageViewer(
                imageUrl: message.localPath ?? message.message),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:
            message.localPath != null && File(message.localPath!).existsSync()
                ? Opacity(
                    opacity: message.status == 0 ? 0.5 : 1,
                    child: Image.file(
                      File(message.localPath!),
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.network(
                    message.message,
                    fit: BoxFit.cover,
                  ),
      ),
    );
  } else if (message.type == "video") {
    return GestureDetector(
      onTap: () {
        // Navigator.push(
        //   context,
        //   openImage(
        //     FullScreenImageViewer(
        //         imageUrl: message.localPath ?? message.message),
        //   ),
        // );
      },
      child: Stack(
        children: [
          message.thumbnailPath != null
              ? Opacity(
                  opacity: message.status == 0 ? 0.5 : 1,
                  child: Image.file(
                    File(message.thumbnailPath!),
                    fit: BoxFit.cover,
                  ),
                )
              : VideoPlayer(
                  videoUrl: message.localPath != null
                      ? message.localPath!
                      : message.message),
          message.status == 0
              ? Positioned(
                  bottom: 5,
                  right: 5,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              : Positioned(
                  bottom: 5,
                  right: 5,
                  child: Text(
                    "${message.timestamp.hour.toString().padLeft(2, '0')}.${message.timestamp.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
        ],
      ),
    );
  } else {
    return SizedBox.shrink();
  }
}

Widget _buildActionButton({
  required IconData icon,
  required Color color,
  Color? backgroundColor,
  required VoidCallback onPressed,
}) {
  return Container(
    margin: EdgeInsets.only(right: 8, top: 8, bottom: 8),
    child: Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: backgroundColor != null
                ? [
                    backgroundColor,
                    backgroundColor.withOpacity(0.8),
                  ]
                : [
                    Colors.white.withOpacity(0.8),
                    Color(0xFFF8FAFC).withOpacity(0.8),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              blurRadius: 0,
              offset: Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 20,
            color: color,
          ),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ),
    ),
  );
}
