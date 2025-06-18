import 'package:chat/services/local_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';

class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  _PersonalizationPageState createState() => _PersonalizationPageState();
}

Route _goPage(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    opaque: false,
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

class _PersonalizationPageState extends State<PersonalizationPage> {
  final LocalDatabase dbs = LocalDatabase.instance;
  late Map<String, dynamic> user;
  final ThemeController themeController = Get.find();

  @override
  void initState() {
    super.initState();
    user = Map.from(widget.user);
  }

  void clear() async {
    await dbs.resetDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 1,
          shadowColor: Color(0xFFf3f4f6),
          leading: IconButton(
            padding: EdgeInsets.all(5),
            icon: Icon(Icons.chevron_left, size: 30, color: Colors.grey[600]),
            onPressed: () => Navigator.pop(context),
          ),
          leadingWidth: 25,
          centerTitle: true,
          title: Text("Personalization",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
        body: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) {
              return Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              "Theme Mode",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            tileColor: Colors.white,
                            trailing: Obx(() {
                              ThemeMode mode = themeController.themeMode.value;
                              String theme = mode == ThemeMode.light
                                  ? 'light'
                                  : mode == ThemeMode.dark
                                      ? 'dark'
                                      : 'auto';
                              return Wrap(
                                direction: Axis.horizontal,
                                spacing: 5,
                                children: [
                                  ElevatedButton(
                                      style: ButtonStyle(
                                          padding: WidgetStatePropertyAll(
                                              EdgeInsets.symmetric(
                                                  horizontal: 5)),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                  theme == "light"
                                                      ? Colors.blue
                                                      : Colors.white),
                                          shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5)))),
                                      onPressed: () {
                                        themeController.setThemeMode("light");
                                      },
                                      child: Wrap(
                                        direction: Axis.horizontal,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 2,
                                        children: [
                                          Icon(
                                            Icons.light_mode,
                                            color: theme == "light"
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          Text(
                                            "Light",
                                            style: TextStyle(
                                              color: theme == "light"
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          )
                                        ],
                                      )),
                                  ElevatedButton(
                                      style: ButtonStyle(
                                          padding: WidgetStatePropertyAll(
                                              EdgeInsets.symmetric(
                                                  horizontal: 5)),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                  theme == "dark"
                                                      ? Colors.blue
                                                      : Colors.white),
                                          shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5)))),
                                      onPressed: () {
                                        themeController.setThemeMode("dark");
                                      },
                                      child: Wrap(
                                        direction: Axis.horizontal,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 2,
                                        children: [
                                          Icon(
                                            Icons.dark_mode,
                                            color: theme == "dark"
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          Text(
                                            "Dark",
                                            style: TextStyle(
                                              color: theme == "dark"
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          )
                                        ],
                                      )),
                                  ElevatedButton(
                                      style: ButtonStyle(
                                          padding: WidgetStatePropertyAll(
                                              EdgeInsets.symmetric(
                                                  horizontal: 5)),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                  theme == "auto"
                                                      ? Colors.blue
                                                      : Colors.white),
                                          shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5)))),
                                      onPressed: () {
                                        themeController.setThemeMode("auto");
                                      },
                                      child: Wrap(
                                        direction: Axis.horizontal,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 2,
                                        children: [
                                          Icon(
                                            Icons.phone_android,
                                            color: theme == "auto"
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          Text(
                                            "Auto",
                                            style: TextStyle(
                                              color: theme == "auto"
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          )
                                        ],
                                      )),
                                ],
                              );
                            }),
                            shape: Border(
                                bottom:
                                    BorderSide(color: Colors.grey.shade300)),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            }));
  }
}
