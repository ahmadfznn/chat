import 'package:chat/core/utils/crypto.dart';
import 'package:chat/services/api_service.dart';
import 'package:chat/services/cookie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat/components/popup.dart';

class RegisterController extends GetxController {
  var isLoading = false.obs;
  var isUsernameAvailable = false.obs;
  var usernameStatus = "".obs;
  var isEmailAvailable = false.obs;
  var emailStatus = "".obs;
  var username = ''.obs;
  var email = ''.obs;
  var page = 1.obs;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Future<void> _createUserInFirestore(User user) async {
  //   await _postRequest("$_apiUrl/auth/user/add", {
  //     "displayName": user.displayName,
  //     "email": user.email,
  //     "photo": user.photoURL,
  //     "telephone_number": user.phoneNumber,
  //   });

  @override
  void onInit() {
    super.onInit();
    usernameController.addListener(() {
      username.value = usernameController.text;
    });
    emailController.addListener(() {
      email.value = emailController.text;
    });

    debounce(
      username,
      (_) => checkUsername(username.value),
      time: const Duration(milliseconds: 500),
    );

    debounce(
      email,
      (_) => checkEmail(email.value),
      time: const Duration(milliseconds: 500),
    );
  }

  Future<void> checkUsername(username) async {
    if (username.isEmpty) {
      usernameStatus.value = 'username cannot be empty';
      isUsernameAvailable.value = false;
      return;
    }

    if (username.toString().length < 3) {
      usernameStatus.value = 'username cannot be less than 3 digits';
      isUsernameAvailable.value = false;
      return;
    }

    try {
      bool available = await ApiService().checkUsername(username);
      if (available) {
        usernameStatus.value = 'username available';
        isUsernameAvailable.value = true;
      } else {
        usernameStatus.value = 'username not available';
        isUsernameAvailable.value = false;
      }
    } catch (e) {
      usernameStatus.value = 'error while checking username';
      isUsernameAvailable.value = false;
    }
  }

  Future<void> checkEmail(email) async {
    if (email.isEmpty) {
      emailStatus.value = 'email cannot be empty';
      isEmailAvailable.value = false;
      return;
    }

    try {
      bool available = await ApiService().checkEmail(email);
      if (available) {
        emailStatus.value = 'email available';
        isEmailAvailable.value = true;
      } else {
        emailStatus.value = 'email not available';
        isEmailAvailable.value = false;
      }
    } catch (e) {
      emailStatus.value = 'error while checking email';
      isUsernameAvailable.value = false;
    }
  }

  Future<bool> register() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      final token = await FirebaseAuth.instance.currentUser!.getIdToken(true);

      final publicKey = await generateKeyPair();
      final res = await ApiService().register({
        "email": emailController.text,
        "username": usernameController.text,
        "publicKey": publicKey
      }, token!);

      print("Result : $res");
      final cookies = res.headers['set-cookie'];
      if (cookies != null) {
        final cookieManager = CookieManager();
        final sessionCookie =
            cookieManager.extractCookieValue(cookies, 'session');

        if (sessionCookie != null) {
          print("Cookie : $sessionCookie");
          await cookieManager.saveSessionCookie(sessionCookie);
          await generateKeyPair();
          // ignore: avoid_print
          print('Session cookie saved successfully!');
          return true;
        } else {
          // ignore: avoid_print
          print('Session cookie not found in response!');
          return false;
        }
      } else {
        // ignore: avoid_print
        print('No cookies found in response headers!');
        return false;
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
      return false;
    }
  }

  void _handleFirebaseAuthError(BuildContext context, FirebaseAuthException e) {
    Popup().show(
        context, e.message ?? "An unknown FirebaseAuth error occurred.", false);
  }

  void _handleGenericError(BuildContext context, dynamic error) {
    Popup().show(context, "An error occurred: $error", false);
  }
}
