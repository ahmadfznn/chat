import 'package:chat/core/utils/crypto.dart';
import 'package:chat/services/api_service.dart';
import 'package:chat/services/cookie.dart';
import 'package:chat/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chat/components/popup.dart';
import 'package:http/http.dart' as http;

class AuthController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<Map<String, dynamic>> login(
      BuildContext context, Map<String, dynamic> data, String provider) async {
    try {
      UserCredential userCredential;

      if (provider == "credentials") {
        userCredential = await _loginWithEmailAndPassword(
            data['email'].trim(), data['password'].trim());
      } else {
        userCredential = await _loginWithGoogle();
      }

      bool status = await _processLogin(userCredential, provider);
      if (status) {
        if (userCredential.user != null) {
          final res = await FirebaseFirestore.instance
              .collection("users")
              .where("email", isEqualTo: userCredential.user!.email)
              .get();
          if (res.docs.isNotEmpty) {
            final result = res.docs[0];
            await UserService(result.id).setUserSignInStatus(result.id, true);
            return {
              "user": {"id": result.id, ...result.data()}
            };
          } else {
            return {"user": null};
          }
        } else {
          return {"user": null};
        }
      } else {
        return {"user": null};
      }
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      _handleFirebaseAuthError(context, e);
      return {"user": null};
    } catch (e) {
      // ignore: use_build_context_synchronously
      _handleGenericError(context, e);
      return {"user": null};
    }
  }

  Future<UserCredential> _loginWithEmailAndPassword(
      String email, String password) {
    return FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> _loginWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Google sign-in aborted by user.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<bool> _processLogin(
      UserCredential userCredential, String provider) async {
    if (userCredential.user == null) {
      throw FirebaseAuthException(
          code: 'ERROR_NO_USER', message: 'No user found.');
    }

    User user = userCredential.user!;
    await user.reload();

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .where("email", isEqualTo: user.email)
        .get();

    // ignore: prefer_typing_uninitialized_variables
    var res;
    if (userDoc.docs.isEmpty && provider == "google") {
      bool status = await _createUserInFirestore(user);
      return status;
    }

    if (provider == "credentials") {
      res = await createToken(user);
      bool status = await _onLoginSuccess(res);
      return status;
    }
    return false;

    // final isVerified =
    //     userDoc.docs.isNotEmpty && userDoc.docs[0]['verified'] == true;

    // if (isVerified) {
    // } else {
    //   throw FirebaseAuthException(
    //       code: 'ERROR_USER_NOT_VERIFIED', message: 'User is not verified.');
    // }
  }

  Future<bool> _createUserInFirestore(User user) async {
    try {
      final token = await FirebaseAuth.instance.currentUser!.getIdToken(true);

      final publicKey = await generateKeyPair();
      String username = user.displayName != null
          ? user.displayName!
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
              .trim()
              .replaceAll(RegExp(r'\s+'), '-')
          : '';

      final res = await ApiService().register(
          {"email": user.email, "username": username, "publicKey": publicKey},
          token!);

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

  Future<http.Response> createToken(User user) async {
    final token = await user.getIdToken(true);

    String? fcm = await messaging.getToken();

    final res =
        await ApiService().login({"email": user.email, "fcm": fcm}, token!);

    return res;
  }

  Future<bool> _onLoginSuccess(http.Response res) async {
    final cookies = res.headers['set-cookie'];
    bool status;
    if (cookies != null) {
      final cookieManager = CookieManager();
      final sessionCookie =
          cookieManager.extractCookieValue(cookies, 'session');

      if (sessionCookie != null) {
        print("Cookie : $sessionCookie");
        await cookieManager.saveSessionCookie(sessionCookie);
        // ignore: avoid_print
        print('Session cookie saved successfully!');
        status = true;
      } else {
        // ignore: avoid_print
        print('Session cookie not found in response!');
        status = false;
      }
    } else {
      // ignore: avoid_print
      print('No cookies found in response headers!');
      status = false;
    }

    Popup().show(Get.context!, "Sign in successfully", true);
    return status;
  }

  Future<bool> sendOtp(BuildContext context, String email) async {
    try {
      final res = await ApiService().sendOtp(email);

      if (res['status']) {
        Popup().show(
            // ignore: use_build_context_synchronously
            context,
            "OTP code has been successfully sent to email",
            true);
        return true;
      } else {
        // ignore: use_build_context_synchronously
        Popup().show(context, res['message'], false);
        return false;
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      Popup().show(context, "OTP code failed to send", false);
      return false;
    }
  }

  Future<bool> verifyOtp(
      BuildContext context, String type, Map<String, dynamic> data) async {
    try {
      final response = await ApiService().verifyOtp(data);

      if (response['status']) {
        // ignore: use_build_context_synchronously
        Popup().show(context, response['message'], true);
        return true;
      } else {
        // ignore: use_build_context_synchronously
        Popup().show(context, response['message'], false);
        return false;
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      Popup().show(context, "An error occurred while verifying OTP", false);
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
