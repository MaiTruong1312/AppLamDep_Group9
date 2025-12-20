import 'package:applamdep/UI/main_layout.dart';
import 'package:applamdep/welcome/screen1.dart';
import 'package:flutter/material.dart';
import 'welcome/welcome_flow.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'UI/ar/home.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';
import 'providers/store_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check login status
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => StoreProvider()),
        ],
        child: MyApp(isLoggedIn: isLoggedIn),
      ), // Pass the status
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Làm Đẹp',
      debugShowCheckedModeBanner: false,

      // =====================================================================
      // CẤU HÌNH NAVIGATION - CHỈ CHỌN 1 TRONG 2 CÁCH DƯỚI ĐÂY:
      // =====================================================================

      // CÁCH 1: Dùng initialRoute + routes (cho navigation phức tạp)
      // initialRoute: isLoggedIn ? '/' : '/welcome',
      // routes: {
      //   '/': (context) => const MainLayout(initialTabIndex: 0),
      //   '/main-layout': (context) => const MainLayout(initialTabIndex: 0),
      //   '/main-layout/collection': (context) => const MainLayout(initialTabIndex: 1),
      //   '/main-layout/booking': (context) => const MainLayout(initialTabIndex: 2),
      //   '/main-layout/discover': (context) => const MainLayout(initialTabIndex: 3),
      //   '/main-layout/profile': (context) => const MainLayout(initialTabIndex: 4),
      //   '/welcome': (context) => const SplashScreen1(),
      // },

      // CÁCH 2: Dùng home đơn giản (khuyên dùng nếu không cần route name)
      home: isLoggedIn ? const MainLayout(initialTabIndex: 0) : const SplashScreen1(),

      // =====================================================================
      // CẤU HÌNH THEME DATA
      // =====================================================================
      theme: ThemeData(
        useMaterial3: true,

        // 1. Cấu hình Color Scheme (Màu sắc)
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary500,
          onPrimary: AppColors.white,
          secondary: AppColors.blueLight500,
          onSecondary: AppColors.white,
          error: AppColors.error500,
          onError: AppColors.white,
          surface: AppColors.white,
          background: AppColors.whiteSmoke,
          onBackground: AppColors.darkToneInk,

          primaryContainer: AppColors.primary100,
          onSurface: AppColors.neutral900,
        ),

        // 2. Cấu hình Text Theme (Kiểu chữ)
        textTheme: TextTheme(
          // Display
          displayLarge: AppTypography.headline3XL,
          displayMedium: AppTypography.headline2XL,
          displaySmall: AppTypography.headlineXL,

          // Headline
          headlineLarge: AppTypography.headlineLG,
          headlineMedium: AppTypography.headlineMD,
          headlineSmall: AppTypography.headlineSM,

          // Title
          titleLarge: AppTypography.textXL,
          titleMedium: AppTypography.textLG,
          titleSmall: AppTypography.headlineXS,

          // Body
          bodyLarge: AppTypography.textMD,
          bodyMedium: AppTypography.textSM,
          bodySmall: AppTypography.textXS,

          // Label
          labelLarge: AppTypography.buttonLG,
          labelMedium: AppTypography.labelMD,
          labelSmall: AppTypography.labelSM,
        ),

        // 3. Cấu hình Scaffold
        scaffoldBackgroundColor: AppColors.whiteSmoke,

        // 4. Cấu hình AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.darkToneInk,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          // Sử dụng TextStyle từ Theme (hoặc AppTypography)
          titleTextStyle: AppTypography.headlineMD.copyWith(
            color: AppColors.darkToneInk,
          ),
        ),

        // 5. Cấu hình ElevatedButton (Sử dụng Button LG/MD)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary600,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            // Sử dụng TextStyle đã được định nghĩa cho Button LG
            textStyle: AppTypography.buttonLG,
          ),
        ),

        // 6. Cấu hình Card
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),

        // 7. Cấu hình Input Decoration
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: AppColors.white5,
          hintStyle: AppTypography.textMD.copyWith(color: AppColors.neutral500),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.neutral200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.neutral200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.primary500, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppColors.error500),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
