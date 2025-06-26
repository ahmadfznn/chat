import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chat/features/auth/presentation/pages/otp.dart';
import 'package:chat/components/popup.dart';
import 'package:chat/controllers/auth_controller.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ForgotPasswordState createState() => _ForgotPasswordState();
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

class _ForgotPasswordState extends State<ForgotPassword> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _emailController = TextEditingController();
  bool loading = false;
  bool showPwd = false;
  bool confirmPwd = false;

  void _checkFieldsAndSend() {
    if (_emailController.text.isEmpty) {
      Popup().show(context, "Please fill in the email column first", false);
      return;
    }

    _sendEmail();
  }

  void _sendEmail() async {
    try {
      setState(() {
        loading = true;
      });

      bool status =
          await AuthController().sendOtp(context, _emailController.text);

      if (status) {
        await Navigator.push(
            // ignore: use_build_context_synchronously
            context,
            _goPage(Otp(
              email: _emailController.text,
              type: "reset",
            )));
      }

      setState(() {
        _emailController.clear();
        loading = false;
      });
    } catch (e) {
      setState(() {
        _emailController.clear();
        loading = false;
      });

      Popup().show(
          // ignore: use_build_context_synchronously
          context,
          "Check your internet connection or restart the application.",
          false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        "Forgot Password",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        "Enter your email to reset your password",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Email",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  TextField(
                    controller: _emailController,
                    minLines: 1,
                    maxLines: null,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      hintText: "Input your email",
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                            width: 1, color: Color(0xFFC3C3C3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                            width: 2, color: Color(0xFF122B88)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        onPressed: () =>
                            loading ? null : {_checkFieldsAndSend()},
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minSize: 0,
                        color: const Color(0xFF122B88),
                        child: loading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.blue.shade50,
                                ),
                              )
                            : const Text("Send email verification",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                      )),
                ],
              ),
            )
          ],
        ),
      )),
    );
  }
}
