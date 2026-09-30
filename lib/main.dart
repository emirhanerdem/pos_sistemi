import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  runApp(const ZanhaPayApp());
}

class ZanhaPayApp extends StatelessWidget {
  const ZanhaPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'ZanhaPay Mobil Pos',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(
            ThemeController.instance.option,
            ThemeController.instance.accent,
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}
