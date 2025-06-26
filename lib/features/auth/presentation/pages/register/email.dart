import 'package:chat/features/auth/presentation/pages/otp.dart';
import 'package:chat/components/popup.dart';
import 'package:chat/controllers/auth_controller.dart';
import 'package:chat/controllers/register_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Email extends StatefulWidget {
  const Email({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EmailState createState() => _EmailState();
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

class _EmailState extends State<Email> {
  final RegisterController controller = Get.put(RegisterController());
  bool loading = true;

  void next() async {
    try {
      setState(() {
        loading = true;
        controller.emailStatus.value = "";
        controller.usernameStatus.value = "";
      });

      bool status = await AuthController()
          .sendOtp(context, controller.emailController.text);

      if (status) {
        await Navigator.push(
            // ignore: use_build_context_synchronously
            context,
            _goPage(Otp(
              email: controller.emailController.text,
              type: "register",
            )));
      }

      setState(() {
        controller.emailController.clear();
        loading = false;
      });
    } catch (e) {
      setState(() {
        controller.emailController.clear();
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
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        CupertinoTextField(
          controller: controller.emailController,
          placeholder: "Input your email",
          keyboardType: TextInputType.emailAddress,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Obx(
          () {
            return Text(
              controller.isEmailAvailable.value
                  ? "email available"
                  : controller.emailStatus.string,
              style: TextStyle(
                  color: controller.isEmailAvailable.value
                      ? Colors.green
                      : Colors.red),
            );
          },
        ),
        const SizedBox(
          height: 15,
        ),
        SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: () =>
                  controller.isEmailAvailable.value ? next() : null,
              color: controller.isEmailAvailable.value
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
