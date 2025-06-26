import 'package:chat/features/auth/presentation/pages/auth.dart';
import 'package:chat/controllers/register_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat/features/auth/presentation/pages/reset_password.dart';
import 'package:chat/components/popup.dart';
import 'package:chat/controllers/auth_controller.dart';

class Otp extends StatefulWidget {
  const Otp({super.key, this.user, required this.email, required this.type});
  final User? user;
  final String email;
  final String type;

  @override
  // ignore: library_private_types_in_public_api
  _OtpState createState() => _OtpState();
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

class _OtpState extends State<Otp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RegisterController controller = Get.put(RegisterController());
  final List<TextEditingController> _controllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool loading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void checkFieldsAndVerify() {
    if (_controllers.length < 4) {
      Popup().show(context, "Please fill in the column code first", false);
      return;
    }

    verify();
  }

  void verify() async {
    try {
      setState(() {
        loading = true;
      });

      String code = _controllers.map((controller) => controller.text).join();
      bool status = await AuthController().verifyOtp(
          context, widget.type, {"email": widget.email, "otp": code});

      setState(() {
        loading = false;
      });

      if (status) {
        if (widget.type == "register") {
          // final String? token = await widget.user!.getIdToken();
          // final SharedPreferences prefs = await SharedPreferences.getInstance();
          // await prefs.setString("user_id", widget.user!.uid);
          // await prefs.setString("token", token!);

          controller.page.value = 3;
          await Navigator.pushAndRemoveUntil(
            // ignore: use_build_context_synchronously
            context,
            _goPage(const Auth(
              page: 1,
            )),
            (route) => false,
          );
        } else {
          await Navigator.pushAndRemoveUntil(
            // ignore: use_build_context_synchronously
            context,
            _goPage(ResetPassword(
              email: widget.email,
            )),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      Popup().show(
        // ignore: use_build_context_synchronously
        context,
        "Check your internet connection or restart the application.",
        false,
      );
    }
  }

  void resendEmail() async {
    await AuthController().sendOtp(context, widget.email);
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
                child: Image(image: AssetImage("assets/img/logo-auth.png")),
              ),
              Container(
                color: Colors.white,
                height: MediaQuery.of(context).size.height - 213,
                padding: const EdgeInsets.only(
                    top: 15, right: 30, bottom: 30, left: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Verification",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Enter your 4-digit verification code",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                                decoration: InputDecoration(
                                    counterText: '',
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade200)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF4285F4)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 18)),
                                autofocus: index == 0,
                                onChanged: (value) {
                                  if (value.length > 1) {
                                    _controllers[index].text = value[0];
                                    return;
                                  }

                                  if (value.isNotEmpty) {
                                    if (index < 3) {
                                      FocusScope.of(context)
                                          .requestFocus(_focusNodes[index + 1]);
                                    } else {
                                      FocusScope.of(context).unfocus();
                                    }
                                  }

                                  if (value.isEmpty && index > 0) {
                                    FocusScope.of(context)
                                        .requestFocus(_focusNodes[index - 1]);
                                  }
                                },
                              ),
                            ),
                            if (index < 3) const SizedBox(width: 10),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 30),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text:
                                "We have sent a verification code to your email ",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.blue,
                            ),
                          ),
                          const TextSpan(
                            text: ". You can check your inbox.",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        onPressed: () =>
                            loading ? null : checkFieldsAndVerify(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minSize: 0,
                        color: const Color(0xFF122B88),
                        child: Text(
                          loading ? "Verifying..." : "Verify",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "i didn’t receive the code?",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            resendEmail();
                          },
                          child: const Text(
                            "Send again",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
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
