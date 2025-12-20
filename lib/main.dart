import 'package:applamdep/UI/main_layout.dart';
import 'package:applamdep/welcome/screen1.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'welcome/welcome_flow.dart';
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
      // BẮT ĐẦU CẤU HÌNH THEME DATA
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
          surface: AppColors.white, // Màu nền của Card, Dialog
          background: AppColors.whiteSmoke, // Màu nền Scaffold
          onBackground: AppColors.darkToneInk,

          primaryContainer: AppColors.primary100,
          onSurface: AppColors.neutral900,
        ),

        // 2. Cấu hình Text Theme (Kiểu chữ) - Ánh xạ từ AppTypography
        textTheme: TextTheme(
          // Display
          displayLarge: AppTypography.headline3XL, // 32px
          displayMedium: AppTypography.headline2XL, // 28px
          displaySmall: AppTypography.headlineXL, // 24px

          // Headline (Tiêu đề nội dung)
          headlineLarge: AppTypography.headlineLG, // 20px
          headlineMedium: AppTypography.headlineMD, // 18px
          headlineSmall: AppTypography.headlineSM, // 16px

          // Title (Tiêu đề nhỏ, card, app bar)
          titleLarge: AppTypography.textXL, // 20px
          titleMedium: AppTypography.textLG, // 18px
          titleSmall: AppTypography.headlineXS, // 14px (SemiBold)

          // Body (Nội dung chính)
          bodyLarge: AppTypography.textMD, // 16px
          bodyMedium: AppTypography.textSM, // 14px
          bodySmall: AppTypography.textXS, // 12px

          // Label (Nhãn, Button, chú thích)
          labelLarge: AppTypography.buttonLG, // Button LG (16px) - Dùng cho Text trong nút
          labelMedium: AppTypography.labelMD, // Label MD (14px)
          labelSmall: AppTypography.labelSM, // Label SM (12px)
        ),

        // 3. Cấu hình Scaffold (Nền màn hình)
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

        // 6. Cấu hình Card (Sử dụng CardThemeData để tránh lỗi)
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),

        // 7. Cấu hình Input Decoration (Trường nhập liệu Text Field)
        inputDecorationTheme: InputDecorationThemeData( // Sử dụng InputDecorationThemeData
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
      // =====================================================================
      // Decide home screen based on login status
      home: isLoggedIn ? const MainLayout() : const SplashScreen1(),
    );
  }
}
