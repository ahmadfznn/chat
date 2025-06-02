import 'dart:convert';

import 'package:chat/services/api.dart';

class ApiService {
  Future<bool> checkUsername(username) async {
    final response =
        await Api().post({"username": username}, "auth/check-username");
    Map<String, dynamic> res = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (res['available']) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<bool> checkEmail(email) async {
    final response = await Api().post({"email": email}, "auth/check-email");
    Map<String, dynamic> res = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (res['available']) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await Api().post({"email": email}, "otp/send");

      Map<String, dynamic> res = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {...res, "status": true};
      } else {
        return {...res, "status": false};
      }
    } catch (e) {
      return {"message": "Something wrong", "status": false};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(Map<String, dynamic> data) async {
    try {
      final response = await Api().post(data, "otp/verify");

      Map<String, dynamic> res = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {...res, "status": true};
      } else {
        return {...res, "status": false};
      }
    } catch (e) {
      return {"message": "Something wrong", "status": false};
    }
  }

  Future register(Map<String, dynamic> data, String header) async {
    try {
      final res = await Api()
          .post(data, "auth/register", {"Authorization": "Bearer $header"});

      return res;
    } catch (e) {
      return {"message": "Something wrong", "status": false};
    }
  }

  Future login(Map<String, dynamic> data, String header) async {
    try {
      final res = await Api()
          .post(data, "auth/login", {"Authorization": "Bearer $header"});

      return res;
    } catch (e) {
      return {"message": "Something wrong", "status": false};
    }
  }
}
