import 'package:chat/controller/register_controller.dart';
import 'package:chat/controller/user_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Username extends StatefulWidget {
  const Username({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UsernameState createState() => _UsernameState();
}

class _UsernameState extends State<Username> {
  final RegisterController controller = Get.put(RegisterController());

  void next() async {
    controller.page.value = 2;
    controller.emailStatus.value = "";
    controller.usernameStatus.value = "";

    final res = await UserController().getUserData();
    print(res);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Username", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        CupertinoTextField(
          controller: controller.usernameController,
          placeholder: "Input your username",
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Obx(
          () {
            return Text(
              controller.isUsernameAvailable.value
                  ? "username available"
                  : controller.usernameStatus.string,
              style: TextStyle(
                  color: controller.isUsernameAvailable.value
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
                  controller.isUsernameAvailable.value ? next() : null,
              color: controller.isUsernameAvailable.value
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
