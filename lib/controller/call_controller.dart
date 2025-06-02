import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CallController extends GetxController {
  RxList<Map<String, dynamic>> data = <Map<String, dynamic>>[].obs;
  RxBool showSelect = false.obs;

  Future<void> deleteData(BuildContext context, List<dynamic> d) async {}
}
