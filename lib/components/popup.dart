import 'package:flutter/material.dart';

class Popup {
  void show(BuildContext context, String message, bool status) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
      closeIconColor: Colors.white,
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: status ? Colors.green : Colors.red,
      duration: const Duration(seconds: 3),
    );
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
