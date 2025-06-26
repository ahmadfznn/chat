import 'package:chat/controllers/register_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Name extends StatefulWidget {
  const Name({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NameState createState() => _NameState();
}

class _NameState extends State<Name> {
  final RegisterController controller = Get.put(RegisterController());

  void next() {
    controller.page.value = 5;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("First Name", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        CupertinoTextField(
          controller: controller.firstNameController,
          placeholder: "Input your first name",
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          autofocus: true,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Last Name", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        CupertinoTextField(
          controller: controller.lastNameController,
          placeholder: "Input your last name",
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          autofocus: true,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: () => next(),
              color: const Color(0xFF122b88),
              padding: const EdgeInsets.symmetric(vertical: 10),
              minSize: 0,
              child: const Text("Next",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )),
      ],
    );
  }
}
