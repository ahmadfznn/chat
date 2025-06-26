import 'package:chat/controllers/register_controller.dart';
import 'package:chat/core/widgets/layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class Password extends StatefulWidget {
  const Password({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PasswordState createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  final RegisterController controller = Get.put(RegisterController());
  bool showPwd = false;
  bool showPwdConf = false;
  bool pwdNotSame = false;
  bool hasMinLength = false;
  bool hasNumber = false;
  bool hasSymbol = false;
  bool policy = false;
  double progressValue = 0.0;

  @override
  void initState() {
    super.initState();

    controller.passwordController.addListener(() {
      _validatePassword(controller.passwordController.text);
    });
  }

  void next() async {
    final res = await controller.register();
    if (res) {
      controller.page.value = 4;
    }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        CupertinoTextField(
          controller: controller.passwordController,
          enableInteractiveSelection: false,
          obscuringCharacter: "*",
          onChanged: (value) {
            if (controller.confirmPasswordController.text.isNotEmpty) {
              if (value != controller.confirmPasswordController.text) {
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
                    showPwd = !showPwd;
                  });
                },
                child: showPwd
                    ? const Icon(IconsaxPlusLinear.eye)
                    : const Icon(IconsaxPlusLinear.eye_slash)),
          ),
          placeholder: "Input your password",
          obscureText: !showPwd,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            // border: Border.all(
            //   color: _pwFocusNode.hasFocus
            //       ? const Color(0xFF122b88)
            //       : const Color(0xFF94a3b8),
            //   width: _pwFocusNode.hasFocus ? 2 : 1,
            // ),
          ),
        ),
        const SizedBox(height: 15),
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Confirm Password",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        CupertinoTextField(
          controller: controller.confirmPasswordController,
          enableInteractiveSelection: false,
          obscuringCharacter: "*",
          onChanged: (value) {
            if (controller.passwordController.text.isNotEmpty) {
              if (value != controller.passwordController.text) {
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
                    showPwdConf = !showPwdConf;
                  });
                },
                child: showPwdConf
                    ? const Icon(IconsaxPlusLinear.eye)
                    : const Icon(IconsaxPlusLinear.eye_slash)),
          ),
          placeholder: "Confirm your password",
          obscureText: !showPwdConf,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            // border: Border.all(
            //   color: _pwConfirmFocusNode.hasFocus
            //       ? const Color(0xFF122b88)
            //       : const Color(0xFF94a3b8),
            //   width: _pwConfirmFocusNode.hasFocus ? 2 : 1,
            // ),
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
        controller.passwordController.text.isNotEmpty
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
                        hasMinLength ? Icons.circle : Icons.circle_outlined,
                        color:
                            hasMinLength ? Colors.purple : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 5),
                      const Text("8 characters minimum")
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        hasNumber ? Icons.circle : Icons.circle_outlined,
                        color: hasNumber ? Colors.purple : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 5),
                      const Text("a nummber")
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        hasSymbol ? Icons.circle : Icons.circle_outlined,
                        color: hasSymbol ? Colors.purple : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 5),
                      const Text("a symbol")
                    ],
                  ),
                ],
              )
            : Container(),
        const SizedBox(height: 15),
        Row(
          children: [
            CupertinoSwitch(
              value: policy,
              activeTrackColor: const Color(0xFF122b88),
              onChanged: (value) {
                setState(() {
                  policy = value;
                });
              },
            ),
            const SizedBox(
              width: 5,
            ),
            const Text(
              "i agree with privacy policy and Term & Condition",
              style: TextStyle(fontSize: 10),
            )
          ],
        ),
        const SizedBox(
          height: 15,
        ),
        SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: () =>
                  hasMinLength && hasNumber && hasSymbol ? next() : null,
              color: hasMinLength && hasNumber && hasSymbol
                  ? const Color(0xFF122b88)
                  : Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 10),
              minSize: 0,
              child: const Text("Next",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )),
      ],
    );
  }
}
