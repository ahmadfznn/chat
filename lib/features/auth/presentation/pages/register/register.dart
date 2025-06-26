import 'package:chat/features/auth/presentation/pages/register/email.dart';
import 'package:chat/features/auth/presentation/pages/register/name.dart';
import 'package:chat/features/auth/presentation/pages/register/password.dart';
import 'package:chat/features/auth/presentation/pages/register/profile_picture.dart';
import 'package:chat/features/auth/presentation/pages/register/username.dart';
import 'package:chat/controllers/register_controller.dart';
import 'package:chat/components/popup.dart';
import 'package:chat/core/widgets/layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Register extends StatefulWidget {
  const Register({super.key, required this.pageController});
  final PageController pageController;

  @override
  // ignore: library_private_types_in_public_api
  _RegisterState createState() => _RegisterState();
}

Route _goPage(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    opaque: true,
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

class _RegisterState extends State<Register> {
  final RegisterController controller = Get.put(RegisterController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool loading = false;
  bool loadingGoogle = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordControllerConfirmation =
      TextEditingController();

  bool get pwdNotSame =>
      _passwordController.text != _passwordControllerConfirmation.text;

  // Example policy variable, set to true for now
  bool policy = true;

  void _registerUser(BuildContext context, String type) async {
    try {
      if (type == 'credentials') {
        if (mounted) {
          setState(() {
            loading = true;
          });
        }

        if (pwdNotSame) {
          if (mounted) {
            setState(() {
              loading = false;
            });
          }
          // ignore: use_build_context_synchronously
          return Popup().show(context, "Passwords do not match", false);
        }

        String email = _emailController.text;
        var next = await checkAccount(context, email);

        if (next) {
          UserCredential userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.value.text,
          );

          await FirebaseFirestore.instance.collection('users').add({
            "uid": userCredential.user!.uid,
            "photo": null,
            "name": _nameController.text.trim(),
            "nickname": _nameController.text.split(' ')[0],
            "title": "Kak",
            "language": "Indonesia",
            "email": email,
            "telephone_number": null,
            "bio": null,
            "verified": false,
            "agent_name": "Lea",
            "agent_lang": "Indonesia",
            "agent_voice": "female",
            "created_at": Timestamp.now()
          });

          User? user = userCredential.user;
          await signUpSuccess(context, user);
        }
      } else {
        if (mounted) {
          setState(() {
            loadingGoogle = true;
          });
        }

        UserCredential userCredential = await signUpWithGoogle();
        User? user = userCredential.user!;

        var next = await checkAccount(context, user.email!);

        if (next) {
          await FirebaseFirestore.instance.collection('users').add({
            "uid": user.uid,
            "photo": user.photoURL,
            "name": user.displayName,
            "nickname": user.displayName!.split(" ")[0],
            "title": "Kak",
            "language": "Indonesia",
            "email": user.email,
            "telephone_number": user.phoneNumber,
            "bio": null,
            "verified": true,
            "agent_name": "Lea",
            "agent_lang": "Indonesia",
            "agent_voice": "female",
            "created_at": Timestamp.now()
          });

          final String? token = await user.getIdToken();
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("user_id", user.uid);
          await prefs.setString("token", token!);

          if (mounted) {
            setState(() {
              _emailController.clear();
              _nameController.clear();
              _passwordController.clear();
              _passwordControllerConfirmation.clear();
              loading = false;
              loadingGoogle = false;
            });
          }

          await Navigator.pushAndRemoveUntil(
            // ignore: use_build_context_synchronously
            context,
            _goPage(Layout(user: {
              "uid": user.uid,
              "photo": user.photoURL,
              "name": user.displayName,
              "nickname": user.displayName != null
                  ? user.displayName!.split(" ")[0]
                  : "",
              "title": "Kak",
              "language": "Indonesia",
              "email": user.email,
              "telephone_number": user.phoneNumber,
              "bio": null,
              "verified": true,
              "agent_name": "Lea",
              "agent_lang": "Indonesia",
              "agent_voice": "female",
              "created_at": Timestamp.now()
            })),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _passwordController.clear();
          _passwordControllerConfirmation.clear();
          loading = false;
          loadingGoogle = false;
        });
      }
      // ignore: use_build_context_synchronously
      Popup().show(context, e.message!, false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _passwordController.clear();
          _passwordControllerConfirmation.clear();
          loading = false;
          loadingGoogle = false;
        });
      }
      // ignore: use_build_context_synchronously
      Popup().show(context, "An unexpected error occurred", false);
    }
  }

  Future<bool> checkAccount(BuildContext context, String email) async {
    var userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (userQuery.docs.isNotEmpty) {
      setState(() {
        loading = false;
        loadingGoogle = false;
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _passwordControllerConfirmation.clear();
      });

      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      // ignore: use_build_context_synchronously
      Popup().show(context, "Email already in use", false);
      return false;
    } else {
      return true;
    }
  }

  Future<void> signUpSuccess(BuildContext context, User? user) async {
    if (user != null) {
      await user.reload();

      setState(() {
        _emailController.clear();
        _passwordController.clear();
        _passwordControllerConfirmation.clear();
      });

      // You may want to send OTP or navigate to another page here
      setState(() {
        loading = false;
        loadingGoogle = false;
      });

      await Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          _goPage(Container(
              child: Center(
                  child: Text(
                      'Registration Success! Please verify your email.')))));
    } else {
      setState(() {
        _passwordController.clear();
        _passwordControllerConfirmation.clear();
        loading = false;
        loadingGoogle = false;
      });
    }
  }

  Future<UserCredential> signUpWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (controller.page.value > 0) {
            controller.page.value--;
            return false;
          } else {
            return true;
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          body: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.only(top: 50),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9feaeb), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(
                        top: 15, right: 30, bottom: 30, left: 30),
                    child: Column(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Sign up",
                              style: TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              "Let's join with us",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Obx(
                            () {
                              return _getPage(controller.page.value);
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? ",
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400)),
                            GestureDetector(
                              onTap: () {
                                widget.pageController.previousPage(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOutExpo);
                              },
                              child: const Text(
                                "Sign in",
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }

  Widget _getPage(int page) {
    switch (page) {
      case 1:
        return const Username();
      case 2:
        return const Email();
      case 3:
        return const Password();
      case 4:
        return const Name();
      case 5:
        return const ProfilePicture();
      default:
        return const SizedBox();
    }
  }
}
