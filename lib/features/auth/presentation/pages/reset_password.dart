import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:chat/components/popup.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key, required this.email});
  final String email;

  @override
  // ignore: library_private_types_in_public_api
  _ResetPasswordState createState() => _ResetPasswordState();
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

class _ResetPasswordState extends State<ResetPassword> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _newPwController = TextEditingController();
  final TextEditingController _confirmPwController = TextEditingController();
  late FocusNode _pwFocusNode;
  late FocusNode _pwConfirmFocusNode;
  bool pwdNotSame = false;
  bool loading = false;
  bool showPwd = false;
  bool newPwd = false;
  bool confirmPwd = false;
  bool hasMinLength = false;
  bool hasNumber = false;
  bool hasSymbol = false;
  double progressValue = 0.0;

  @override
  void initState() {
    super.initState();

    _pwFocusNode = FocusNode();
    _pwConfirmFocusNode = FocusNode();

    _newPwController.addListener(() {
      _validatePassword(_newPwController.text);
    });

    _pwFocusNode.addListener(() {
      setState(() {});
    });

    _pwConfirmFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _newPwController.dispose();
    _pwFocusNode.dispose();
    _pwConfirmFocusNode.dispose();
    super.dispose();
  }

  void _validatePassword(String password) {
    if (password.isNotEmpty) {
      setState(() {
        hasMinLength = password.length >= 8;
        hasNumber = RegExp(r'\d').hasMatch(password);
        hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
        _updateProgress();
      });
    } else {
      setState(() {
        hasMinLength = false;
        hasNumber = false;
        hasSymbol = false;
        progressValue = 0.0;
      });
    }
  }

  void _updateProgress() {
    int fulfilledRequirements = 0;

    if (hasMinLength) fulfilledRequirements++;
    if (hasNumber) fulfilledRequirements++;
    if (hasSymbol) fulfilledRequirements++;

    setState(() {
      progressValue = fulfilledRequirements / 3.0;
    });
  }

  void _checkFieldsAndReset() {
    if (_newPwController.text.isEmpty || _confirmPwController.text.isEmpty) {
      Popup().show(context, "Please fill all the fields", false);
      return;
    }

    _resetPwd();
  }

  void _resetPwd() async {
    try {
      setState(() {
        loading = true;
      });

      // bool status = await AuthController().resetPw(context,
      //     {"email": widget.email, "newPassword": _newPwController.text});

      setState(() {
        _newPwController.clear();
        _confirmPwController.clear();
        loading = false;
      });

      // if (status) {
      //   await Navigator.push(
      //       // ignore: use_build_context_synchronously
      //       context,
      //       _goPage(const Auth()));
      // }
    } catch (e) {
      setState(() {
        _newPwController.clear();
        _confirmPwController.clear();
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
                        "Reset Password",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        "Your new password must be different from old password",
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
                      Text("New password",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  CupertinoTextField(
                    controller: _newPwController,
                    focusNode: _pwFocusNode,
                    enableInteractiveSelection: false,
                    onChanged: (value) {
                      if (_confirmPwController.text.isNotEmpty) {
                        if (value != _confirmPwController.text) {
                          setState(() {
                            pwdNotSame = true;
                          });
                        } else {
                          setState(() {
                            pwdNotSame = false;
                          });
                        }
                      }
                    },
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                          onTap: () {
                            setState(() {
                              newPwd = !newPwd;
                            });
                          },
                          child: newPwd
                              ? const Icon(IconsaxPlusLinear.eye)
                              : const Icon(IconsaxPlusLinear.eye_slash)),
                    ),
                    obscuringCharacter: "*",
                    obscureText: !newPwd,
                    placeholder: "Input your new password",
                    autofocus: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _pwFocusNode.hasFocus
                            ? const Color(0xFF122b88)
                            : const Color(0xFF94a3b8),
                        width: _pwFocusNode.hasFocus ? 2 : 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  _newPwController.text.isNotEmpty
                      ? Column(
                          children: [
                            const SizedBox(
                              height: 5,
                            ),
                            LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(5),
                              minHeight: 10,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Row(
                              children: [
                                Icon(
                                  hasMinLength
                                      ? Icons.circle
                                      : Icons.circle_outlined,
                                  color: hasMinLength
                                      ? Colors.purple
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 5),
                                const Text("8 characters minimum")
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  hasNumber
                                      ? Icons.circle
                                      : Icons.circle_outlined,
                                  color: hasNumber
                                      ? Colors.purple
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 5),
                                const Text("a number")
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  hasSymbol
                                      ? Icons.circle
                                      : Icons.circle_outlined,
                                  color: hasSymbol
                                      ? Colors.purple
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 5),
                                const Text("a symbol")
                              ],
                            ),
                          ],
                        )
                      : Container(),
                  const SizedBox(height: 15),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Confirm new password",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  CupertinoTextField(
                    controller: _confirmPwController,
                    focusNode: _pwConfirmFocusNode,
                    enableInteractiveSelection: false,
                    onChanged: (value) {
                      if (_newPwController.text.isNotEmpty) {
                        if (value != _newPwController.text) {
                          setState(() {
                            pwdNotSame = true;
                          });
                        } else {
                          setState(() {
                            pwdNotSame = false;
                          });
                        }
                      }
                    },
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                          onTap: () {
                            setState(() {
                              confirmPwd = !confirmPwd;
                            });
                          },
                          child: confirmPwd
                              ? const Icon(IconsaxPlusLinear.eye)
                              : const Icon(IconsaxPlusLinear.eye_slash)),
                    ),
                    placeholder: "Confirm your new password",
                    obscuringCharacter: "*",
                    obscureText: !confirmPwd,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _pwConfirmFocusNode.hasFocus
                            ? const Color(0xFF122b88)
                            : const Color(0xFF94a3b8),
                        width: _pwConfirmFocusNode.hasFocus ? 2 : 1,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  pwdNotSame
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Passwords are not the same",
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.start,
                            )
                          ],
                        )
                      : Container(),
                  const SizedBox(height: 30),
                  SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        onPressed: () =>
                            loading ? null : {_checkFieldsAndReset()},
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
                            : const Text("Create",
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
