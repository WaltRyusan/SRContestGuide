import 'package:sr_contest_guide/importer.dart';

// 画面遷移検知
final RouteObserver<ModalRoute<dynamic>> routeObserver = RouteObserver<ModalRoute<dynamic>>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Ads：パッケージの初期化
  Future<InitializationStatus> _initGoogleMobileAds() {
    return MobileAds.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primary, // テキストフィールドのカーソル色
        ),
        fontFamily: 'Georgia',
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.buttonText,
        ),
      ),
      home: const MainView(),
      // 画面遷移検知
      navigatorObservers: [routeObserver],
    );
  }
}