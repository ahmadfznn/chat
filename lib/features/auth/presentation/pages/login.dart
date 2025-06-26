import 'package:chat/core/widgets/layout.dart';
import 'package:chat/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:chat/features/auth/presentation/pages/forgot_password.dart';
import 'package:chat/features/auth/presentation/pages/otp.dart';
import 'package:chat/components/popup.dart';
import 'package:chat/controllers/auth_controller.dart';

class Login extends StatefulWidget {
  const Login({super.key, required this.pageController});
  final PageController pageController;

  @override
  // ignore: library_private_types_in_public_api
  _LoginState createState() => _LoginState();
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

class _LoginState extends State<Login> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;
  bool loading = false;
  bool loadingGoogle = false;
  bool showPwd = false;
  bool remember = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    _emailFocusNode.addListener(() {
      setState(() {});
    });

    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login(String provider) async {
    if (provider != 'google' &&
        (_emailController.text.isEmpty || _passwordController.text.isEmpty)) {
      Popup().show(context, "Please fill all the fields", false);
      return;
    }

    Map<String, dynamic> res;
    if (provider == 'credentials') {
      res = await AuthController().login(
          context,
          {
            "email": _emailController.text,
            "password": _passwordController.text,
          },
          provider);
    } else {
      res = await AuthController().login(context, {}, "google");
    }

    if (res['user'] != null) {
      await Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        _goPage(Layout(
          user: res['user'],
        )),
        (route) => false,
      );
    }
  }

  void openDialog(BuildContext context, CupertinoAlertDialog dialog) {
    showCupertinoModalPopup(context: context, builder: (context) => dialog);
  }

  Future<void> _showEmailVerificationDialog(
      BuildContext context, User user) async {
    openDialog(
      context,
      CupertinoAlertDialog(
        title: const Text("Account verification"),
        content: const Text("Please verify your account first to continue"),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();

              AuthController().sendOtp(context, user.email!);
              Navigator.push(
                  // ignore: use_build_context_synchronously
                  context,
                  _goPage(
                      Otp(user: user, email: user.email!, type: "register")));
            },
            child: const Text("Send Otp"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 100),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9feaeb), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.center,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(
                  width: double.infinity,
                  child: Image(image: AssetImage("assets/img/logo-auth.png"))),
              Container(
                color: Colors.white,
                height: MediaQuery.of(context).size.height - 213,
                padding: const EdgeInsets.only(
                    top: 15, right: 30, bottom: 30, left: 30),
                child: Column(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Sign in",
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Hi, Welcomeback 👋",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Email or Username",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    CupertinoTextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      placeholder: "Input your email or username",
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      autofocus: true,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _emailFocusNode.hasFocus
                              ? const Color(0xFF122b88)
                              : const Color(0xFF94a3b8),
                          width: _emailFocusNode.hasFocus ? 2 : 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Password",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    CupertinoTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      enableInteractiveSelection: false,
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                            onTap: () {
                              setState(() {
                                showPwd = !showPwd;
                              });
                            },
                            child: showPwd
                                ? const Icon(IconsaxPlusLinear.eye)
                                : const Icon(IconsaxPlusLinear.eye_slash)),
                      ),
                      placeholder: "Input your password",
                      obscuringCharacter: "*",
                      obscureText: !showPwd,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _passwordFocusNode.hasFocus
                              ? const Color(0xFF122b88)
                              : const Color(0xFF94a3b8),
                          width: _passwordFocusNode.hasFocus ? 2 : 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CupertinoSwitch(
                              value: remember,
                              activeTrackColor: const Color(0xFF122b88),
                              onChanged: (value) {
                                setState(() {
                                  remember = value;
                                });
                              },
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            const Text(
                              "Remember me",
                              style: TextStyle(fontSize: 13),
                            )
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context, _goPage(const ForgotPassword()));
                          },
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w400),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          onPressed: () => loading || loadingGoogle
                              ? null
                              : _login("credentials"),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          minSize: 0,
                          color: const Color(0xFF122b88),
                          child: loading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.blue.shade50,
                                  ),
                                )
                              : const Text("Sign in",
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        )),
                    const SizedBox(
                      height: 10,
                    ),
                    const Divider(),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => loading || loadingGoogle
                              ? null
                              : _login('google'),
                          style: const ButtonStyle(
                            shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)))),
                            padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(vertical: 2)),
                          ),
                          child: loadingGoogle
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Color(0xFF122b88),
                                  ),
                                )
                              : const Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                        width: 35,
                                        child: Image(
                                            image: AssetImage(
                                                "assets/img/google.png"))),
                                    Text("Or sign in with Google",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400))
                                  ],
                                ),
                        )),
                    const SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w400),
                        ),
                        GestureDetector(
                          onTap: () {
                            _emailFocusNode.unfocus();
                            _passwordFocusNode.unfocus();
                            widget.pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutExpo);
                          },
                          child: const Text(
                            "Sign up now",
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
