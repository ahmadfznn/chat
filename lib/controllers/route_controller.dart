import 'package:get/get.dart';

class RouteController extends GetxController {
  RxString currentRoute = "/chat".obs;
}

final RouteController routeController = Get.put(RouteController());
