import 'dart:io';

import 'package:chat/controllers/user_controller.dart';
import 'package:chat/services/local_database.dart';
import 'package:chat/services/user_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  _ProfileState createState() => _ProfileState();
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

class _ProfileState extends State<Profile> {
  final LocalDatabase dbs = LocalDatabase.instance;
  final UserController userController = UserController();
  TextEditingController nameController = TextEditingController(text: "");
  TextEditingController bioController = TextEditingController(text: "");
  String? picture;
  bool isEditName = false;
  bool isBio = false;

  @override
  void initState() {
    super.initState();

    nameController.value =
        TextEditingValue(text: widget.user['displayName'] ?? "");
    bioController.value = TextEditingValue(text: widget.user['bio'] ?? "");
    picture = widget.user['profile_picture'];
  }

  Future<void> refreshProfile() async {}

  void saveChange() async {
    setState(() {
      widget.user['displayName'] = nameController.text;
      widget.user['bio'] = bioController.text;
    });

    await UserService(widget.user['username']).updateProfile(widget.user['id'],
        {"displayName": nameController.text, "bio": bioController.text});
  }

  void openDialog(BuildContext context, CupertinoAlertDialog dialog) {
    showCupertinoModalPopup(context: context, builder: (context) => dialog);
  }

  void clear() async {
    await dbs.resetDatabase();
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    File? pickedFile = await userController.pickImage(source);
    if (pickedFile != null) {
      await userController.uploadProfilePicture(pickedFile, widget.user['id']);
    }
  }

  Future<void> _deleteProfilePicture() async {
    await userController.deleteProfilePicture(widget.user['id']);
  }

  void showImagePickerBottomSheet(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOption(
                    context, Icons.camera_alt, "Ambil Foto", Colors.blue, () {
                  _pickAndUploadImage(ImageSource.camera);
                }),
                _buildOption(context, Icons.image, "Buka Galeri", Colors.green,
                    () {
                  _pickAndUploadImage(ImageSource.gallery);
                }),
                _buildOption(context, Icons.delete, "Hapus Foto", Colors.red,
                    () {
                  _deleteProfilePicture();
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String label,
      Color color, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 25, color: color),
          ),
          SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
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
            onPressed: () => Navigator.pop(context, widget.user),
          ),
          leadingWidth: 25,
          centerTitle: true,
          title: Text("Profile",
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
                        child: Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                backgroundImage: picture != null
                                    ? NetworkImage(
                                        widget.user['profile_picture'])
                                    : AssetImage("assets/img/user.png"),
                                radius: 70,
                              ),
                              Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: IconButton(
                                    onPressed: () {
                                      showImagePickerBottomSheet(context);
                                    },
                                    icon: Icon(Icons.edit),
                                    iconSize: 25,
                                    style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                            Colors.grey)),
                                    color: Colors.white,
                                  ))
                            ],
                          ),
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your name",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.green),
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: CupertinoTextField(
                                      controller: nameController,
                                      placeholder: "Enter your name.",
                                      enabled: isEditName,
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: isEditName
                                            ? Color(0xFFf9fafb)
                                            : Colors.white,
                                        border: isEditName
                                            ? Border(
                                                bottom: BorderSide(
                                                    color: Colors.blue,
                                                    width: 2))
                                            : null,
                                      )),
                                ),
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isEditName = !isEditName;
                                      });

                                      if (!isEditName) {
                                        saveChange();
                                      }
                                    },
                                    icon: Icon(
                                      isEditName ? Icons.check : Icons.edit,
                                      color: Colors.blue,
                                    ))
                              ],
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              "Bio",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.green),
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: CupertinoTextField(
                                      controller: bioController,
                                      placeholder: "Enter your bio.",
                                      enabled: isBio,
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: isBio
                                            ? Color(0xFFf9fafb)
                                            : Colors.white,
                                        border: isBio
                                            ? Border(
                                                bottom: BorderSide(
                                                    color: Colors.blue,
                                                    width: 2))
                                            : null,
                                      )),
                                ),
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isBio = !isBio;
                                      });

                                      if (!isEditName) {
                                        saveChange();
                                      }
                                    },
                                    icon: Icon(
                                      isBio ? Icons.check : Icons.edit,
                                      color: Colors.blue,
                                    ))
                              ],
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
