import 'package:get/get.dart';

class ChatController extends GetxController {
  RxList<String> selectedChat = <String>[].obs;

  RxBool showSelect = false.obs;
  RxBool isLoading = false.obs;

  // For chat search
  RxString searchQuery = ''.obs;

  Future openRoom(String id) async {}
}
