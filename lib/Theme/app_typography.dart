import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._(); // Private constructor

  // ---------------------------------------------------------------------------
  // 1. CẤU HÌNH FONT CHUNG VÀ FONT WEIGHTS
  // ---------------------------------------------------------------------------
  static const String fontFamily = 'Inter';

  // Màu chữ mặc định (Dựa trên AppColors.darkToneInk và neutral900)
  static const Color _defaultHeadlineColor = AppColors.darkToneInk;
  static const Color _defaultBodyColor = AppColors.neutral900;

  // Định nghĩa 4 FontWeight chính
  static const FontWeight regular = FontWeight.w400; // Text/Body
  static const FontWeight medium = FontWeight.w500; // Label/Button
  static const FontWeight semiBold = FontWeight.w600; // Headline/Title/Label
  static const FontWeight bold = FontWeight.w700; // Headline/Display

  // Hàm tiện ích để tạo nhanh TextStyle và tính height chính xác
  // Height = Line Height (px) / Size (px)
  static TextStyle _style({
    required double sizePx,
    required double lineHeightPx,
    required FontWeight weight,
    Color color = _defaultHeadlineColor,
    double letterSpacing = 0.0,
  }) {
    // Tính toán hệ số height chính xác theo công thức
    final double heightMultiplier = lineHeightPx / sizePx;

    return TextStyle(
      fontFamily: fontFamily,
      fontSize: sizePx,
      fontWeight: weight,
      color: color,
      height: heightMultiplier,
      letterSpacing: letterSpacing,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. TEXT STYLE ĐỊNH NGHĨA (THEO DỮ LIỆU TỪ BẢNG PDF)
  // ---------------------------------------------------------------------------

  // ===========================================================================
  // I. HEADLINE (Thường dùng Bold hoặc SemiBold)
  // ===========================================================================

  // Headline 3xl (32px / 38px)
  static final TextStyle headline3XL = _style(
    sizePx: 32,
    lineHeightPx: 38,
    weight: bold,
  );

  // Headline 2xl (28px / 34px)
  static final TextStyle headline2XL = _style(
    sizePx: 28,
    lineHeightPx: 34,
    weight: bold,
  );

  // Headline xl (24px / 28px)
  static final TextStyle headlineXL = _style(
    sizePx: 24,
    lineHeightPx: 28,
    weight: bold,
  );

  // Headline lg (20px / 24px)
  static final TextStyle headlineLG = _style(
    sizePx: 20,
    lineHeightPx: 24,
    weight: semiBold, // Chuyển sang SemiBold
  );

  // Headline md (18px / 22px)
  static final TextStyle headlineMD = _style(
    sizePx: 18,
    lineHeightPx: 22,
    weight: semiBold,
  );

  // Headline sm (16px / 20px)
  static final TextStyle headlineSM = _style(
    sizePx: 16,
    lineHeightPx: 20,
    weight: semiBold,
  );

  // Headline xs (14px / 16px)
  static final TextStyle headlineXS = _style(
    sizePx: 14,
    lineHeightPx: 16,
    weight: semiBold,
  );


  // ===========================================================================
  // II. TEXT (Body/Nội dung chính - Thường dùng Regular)
  // ===========================================================================

  // Text xl (20px / 30px)
  static final TextStyle textXL = _style(
    sizePx: 20,
    lineHeightPx: 30,
    weight: regular,
    color: _defaultBodyColor,
  );

  // Text lg (18px / 28px)
  static final TextStyle textLG = _style(
    sizePx: 18,
    lineHeightPx: 28,
    weight: regular,
    color: AppColors.neutral800,
  );

  // Text md (16px / 24px)
  static final TextStyle textMD = _style(
    sizePx: 16,
    lineHeightPx: 24,
    weight: regular,
    color: AppColors.neutral700,
  );

  // Text sm (14px / 20px)
  static final TextStyle textSM = _style(
    sizePx: 14,
    lineHeightPx: 20,
    weight: regular,
    color: AppColors.neutral600,
  );

  // Text xs (12px / 18px)
  static final TextStyle textXS = _style(
    sizePx: 12,
    lineHeightPx: 18,
    weight: regular,
    color: AppColors.neutral500,
  );


  // ===========================================================================
  // III. LABEL & BUTTON (Thường dùng Medium hoặc SemiBold)
  // ===========================================================================

  // Label lg (16px / 20px)
  static final TextStyle labelLG = _style(
    sizePx: 16,
    lineHeightPx: 20,
    weight: semiBold,
    color: AppColors.neutral800,
  );

  // Label md (14px / 16px)
  static final TextStyle labelMD = _style(
    sizePx: 14,
    lineHeightPx: 16,
    weight: medium, // Dùng Medium
    color: AppColors.neutral700,
  );

  // Label sm (12px / 14px)
  static final TextStyle labelSM = _style(
    sizePx: 12,
    lineHeightPx: 14,
    weight: medium,
    color: AppColors.neutral600,
  );

  // Label xs (8px / 14px)
  static final TextStyle labelXS = _style(
    sizePx: 8,
    lineHeightPx: 14,
    weight: medium,
    color: AppColors.neutral500,
  );

  // Button lg (16px / 20px)
  static final TextStyle buttonLG = _style(
    sizePx: 16,
    lineHeightPx: 20,
    weight: semiBold, // Thường dùng SemiBold cho nút lớn
    color: AppColors.white,
  );

  // Button md (14px / 16px)
  static final TextStyle buttonMD = _style(
    sizePx: 14,
    lineHeightPx: 16,
    weight: semiBold,
    color: AppColors.white,
  );
}