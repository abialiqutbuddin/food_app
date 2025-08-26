import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project_structure/screens/sidebar.dart';
import 'package:project_structure/state/controllers/event.dart';
import 'package:toastification/toastification.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(EventController());
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: GetMaterialApp(
        showSemanticsDebugger: false,
        title: 'Catering Demo',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        home: const Sidebar(),
      ),
    );
  }
}