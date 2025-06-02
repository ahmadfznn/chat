import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:chat/etc/format_time.dart';
import 'package:chat/models/chat_room_model.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/pages/full_screen_image_viewer.dart';
import 'package:chat/pages/user_profile.dart';
import 'package:chat/pages/video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:chat/services/local_database.dart';
import 'package:chat/services/message_service.dart';
import 'package:chat/services/status_service.dart';
import 'package:chat/controller/route_controller.dart';
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 35, color: Colors.grey[600]),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        leadingWidth: 50,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            _navigateToUserProfile(context, widget.data.recipientId);
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.data.recipientPhoto != null &&
                        widget.data.recipientPhoto!.isNotEmpty
                    ? NetworkImage(widget.data.recipientPhoto!)
                    : AssetImage("assets/img/user.png"),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data.recipientName,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
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
                            style:
                                TextStyle(color: Colors.green, fontSize: 12));
                      }),
                ],
              ),
            ],
          ),
        ),
        actions: selectedMode
            ? [
                IconButton(
                    icon: Icon(Icons.star_outline, color: Colors.green),
                    onPressed: () {}),
                IconButton(
                    icon: Icon(Icons.push_pin, color: Colors.green),
                    onPressed: () {}),
                selectedChat.length == 1
                    ? IconButton(
                        icon: Icon(Icons.info_outline, color: Colors.blue),
                        onPressed: () {})
                    : Container(),
                IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      openDialog(
                        context,
                        CupertinoAlertDialog(
                          title: const Text("Delete Message"),
                          content: const Text(
                              "Are you sure to delete this message?"),
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
                    }),
              ]
            : [
                IconButton(
                    icon: Icon(Icons.phone, color: Colors.blue),
                    onPressed: () {}),
                IconButton(
                    icon: Icon(Icons.video_call, color: Colors.blue),
                    onPressed: () {}),
                IconButton(
                    icon: Icon(Icons.menu, color: Colors.grey),
                    onPressed: () {
                      _showOverlay(context);
                    }),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: messageService.messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Belum ada pesan"));
                }

                var messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollToBottom();
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isMe = message.senderId == widget.user['id'];
                    final bool isFirst = index == 0 ||
                        messages[index - 1].senderId != message.senderId;
                    final bool isLast = index == messages.length - 1 ||
                        messages[index + 1].senderId != message.senderId;

                    return GestureDetector(
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
                                ? Colors.grey.shade300
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5)),
                        margin: EdgeInsets.symmetric(vertical: 1),
                        child: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: IntrinsicWidth(
                              child: _buildMessage(
                                  context, message, isMe, isFirst, isLast)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              children: [
                IconButton(
                    icon: Icon(
                        _emojiShowing
                            ? Icons.keyboard_alt_outlined
                            : Icons.emoji_emotions_outlined,
                        color: Colors.blue),
                    onPressed: toggleEmojiKeyboard),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100]!,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: inputController,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      autocorrect: true,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      onChanged: (value) => onTyping(),
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.attach_file, color: Colors.blue),
                          onPressed: pickMedia,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.all(10),
                  icon: Icon(
                    inputController.text.isNotEmpty && !_isListening
                        ? Icons.send
                        : _isListening
                            ? Icons.mic
                            : Icons.mic_none,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    if (inputController.text.isNotEmpty && !_isListening) {
                      sendMessage();
                    } else {
                      _toggleRecording();
                    }
                  },
                ),
              ],
            ),
          ),
          Offstage(
            offstage: !_emojiShowing,
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
                ),
                skinToneConfig: const SkinToneConfig(),
                categoryViewConfig: const CategoryViewConfig(),
                bottomActionBarConfig: const BottomActionBarConfig(),
                searchViewConfig: const SearchViewConfig(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildMessage(BuildContext context, MessageModel message, bool isMe,
    bool isFirst, bool isLast) {
  if (message.type == "text") {
    return Container(
      padding: EdgeInsets.only(top: 7, bottom: 6, left: 8, right: 8),
      margin: EdgeInsets.symmetric(vertical: 3),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: isMe
              ? const Radius.circular(10)
              : isFirst
                  ? const Radius.circular(10)
                  : Radius.zero,
          topRight: isMe
              ? isFirst
                  ? const Radius.circular(10)
                  : Radius.zero
              : const Radius.circular(10),
          bottomLeft: isMe
              ? const Radius.circular(10)
              : isLast
                  ? const Radius.circular(10)
                  : Radius.zero,
          bottomRight: isMe
              ? isLast
                  ? const Radius.circular(10)
                  : Radius.zero
              : const Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 3),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              message.message,
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black, fontSize: 16),
            ),
          ),
          SizedBox(
            width: 5,
          ),
          Text(
            "${message.timestamp.hour.toString().padLeft(2, '0')}.${message.timestamp.minute.toString().padLeft(2, '0')}",
            style: TextStyle(
                fontSize: 11, color: isMe ? Colors.white70 : Colors.grey[600]),
          ),
          SizedBox(
            width: 1,
          ),
          isMe
              ? Icon(
                  Icons.check,
                  size: 16,
                  shadows: [
                    message.status == 2 || message.status == 3
                        ? Shadow(
                            color: message.status == 3
                                ? Colors.white
                                : Colors.white60,
                            offset: Offset(4, 0))
                        : Shadow(color: Colors.transparent)
                  ],
                  color: message.status == 3 ? Colors.white : Colors.white60,
                )
              : Container()
        ],
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
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: isMe
                ? const Radius.circular(10)
                : isFirst
                    ? const Radius.circular(10)
                    : Radius.zero,
            topRight: isMe
                ? isFirst
                    ? const Radius.circular(10)
                    : Radius.zero
                : const Radius.circular(10),
            bottomLeft: isMe
                ? const Radius.circular(10)
                : isLast
                    ? const Radius.circular(10)
                    : Radius.zero,
            bottomRight: isMe
                ? isLast
                    ? const Radius.circular(10)
                    : Radius.zero
                : const Radius.circular(10),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 3),
          ],
        ),
        child: Stack(
          children: [
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
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: isMe
                ? const Radius.circular(10)
                : isFirst
                    ? const Radius.circular(10)
                    : Radius.zero,
            topRight: isMe
                ? isFirst
                    ? const Radius.circular(10)
                    : Radius.zero
                : const Radius.circular(10),
            bottomLeft: isMe
                ? const Radius.circular(10)
                : isLast
                    ? const Radius.circular(10)
                    : Radius.zero,
            bottomRight: isMe
                ? isLast
                    ? const Radius.circular(10)
                    : Radius.zero
                : const Radius.circular(10),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 3),
          ],
        ),
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
      ),
    );
  } else {
    return SizedBox.shrink();
  }
}
