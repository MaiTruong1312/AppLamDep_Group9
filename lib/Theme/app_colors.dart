import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor để chặn khởi tạo

  // ===========================================================================
  // 1. PRIMARY COLORS (BRAND) - ROSE
  // Màu chủ đạo của App (Pionail)
  //
  // ===========================================================================
  static const Color primary50  = Color(0xFFFFF3F5);
  static const Color primary100 = Color(0xFFFFE4E8);
  static const Color primary200 = Color(0xFFFDCED7);
  static const Color primary300 = Color(0xFFFBA6B6);
  static const Color primary400 = Color(0xFFF97390);
  static const Color primary500 = Color(0xFFF25278); // <-- MAIN BRAND COLOR
  static const Color primary600 = Color(0xFFDE2057);
  static const Color primary700 = Color(0xFFBB1549);
  static const Color primary800 = Color(0xFF9D1443);
  static const Color primary900 = Color(0xFF86153F);
  static const Color primary950 = Color(0xFF4C0519);

  // Alias (Tên gọi tắt cho dễ dùng)
  static const Color primary = primary500;

  // ===========================================================================
  // 2. BACKGROUND COLORS
  // Màu nền, màu tối
  //
  // ===========================================================================
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Backgrounds cụ thể trong Design
  static const Color whiteSmoke  = Color(0xFFFAFAFA); // Nền sáng (thường dùng cho Scaffold)
  static const Color darkToneInk = Color(0xFF121212); // Nền tối (Dark mode hoặc Text chính)

  // White Scale (Dải màu trắng đục - thường dùng làm nền thẻ/card)
  static const Color white5  = Color(0xFFF9F9F9);
  static const Color white10 = Color(0xFFF5F5F5);
  static const Color white20 = Color(0xFFF0F0F0);
  static const Color white30 = Color(0xFFEBEBEB);
  static const Color white40 = Color(0xFFE6E6E6);
  static const Color white50 = Color(0xFFE0E0E0);
  static const Color white60 = Color(0xFFDBDBDB);

  // Glass Effect
  static const Color glass5  = Color(0xDF5F5F5); // 5% opacity
  static const Color glass10 = Color(0x1AF5F5F5); // 10% opacity
  static const Color glass20 = Color(0x33F5F5F5); // 20% opacity
  static const Color glass30 = Color(0x4DF5F5F5); // 30% opacity
  static const Color glass40 = Color(0x66F5F5F5); // 40% opacity
  static const Color glass50 = Color(0x80F5F5F5); // 50% opacity
  static const Color glass60 = Color(0x99F5F5F5); // 60% opacity
  static const Color glass70 = Color(0xB3F5F5F5); // 70% opacity
  static const Color glass80 = Color(0xCCF5F5F5); // 80% opacity
  static const Color glass90 = Color(0xE6F5F5F5); // 90% opacity
  static const Color glass95 = Color(0xF2F5F5F5); // 95% opacity

  // ===========================================================================
  // 3. SEMANTIC COLORS
  // Màu biểu thị trạng thái (Trung tính, Lỗi, Cảnh báo, Thành công)
  //
  // ===========================================================================

  // --- NEUTRAL (Xám - Slate) ---
  // Dùng cho Text, Border, Divider
  static const Color neutral50  = Color(0xFFF6F6F7);
  static const Color neutral100 = Color(0xFFEEF0F1);
  static const Color neutral200 = Color(0xFFE0E2E5);
  static const Color neutral300 = Color(0xFFCDD0D4);
  static const Color neutral400 = Color(0xFFB8BCC1);
  static const Color neutral500 = Color(0xFF9A9EA7);
  static const Color neutral600 = Color(0xFF8F929C);
  static const Color neutral700 = Color(0xFF7B7D87);
  static const Color neutral800 = Color(0xFF65686E);
  static const Color neutral900 = Color(0xFF54565B);
  static const Color neutral950 = Color(0xFF313235);

  // --- ERROR (Đỏ - Red) ---
  static const Color error50  = Color(0xFFFFF3F1);
  static const Color error100 = Color(0xFFFFE5E0);
  static const Color error200 = Color(0xFFFFCFC6);
  static const Color error300 = Color(0xFFFFAD9E);
  static const Color error400 = Color(0xFFFF7E67);
  static const Color error500 = Color(0xFFFC573A);
  static const Color error600 = Color(0xFFEA3B18);
  static const Color error700 = Color(0xFFC52E10);
  static const Color error800 = Color(0xFFA32911); // Icon lỗi, viền lỗi
  static const Color error900 = Color(0xFF862916);
  static const Color error950 = Color(0xFF491106);

  // --- WARNING (Vàng - Amber) ---
  // Sao đánh giá, cảnh báo
  static const Color warning50  = Color(0xFFFFFFEA);
  static const Color warning100 = Color(0xFFFFFCC5);
  static const Color warning200 = Color(0xFFFFFA85);
  static const Color warning300 = Color(0xFFFFF146);
  static const Color warning400 = Color(0xFFFFE31B);
  static const Color warning500 = Color(0xFFFFC60A);
  static const Color warning600 = Color(0xFFE29700);
  static const Color warning700 = Color(0xFFBB6C02);
  static const Color warning800 = Color(0xFF985308);
  static const Color warning900 = Color(0xFF7C440B);
  static const Color warning950 = Color(0xFF482300);

  // --- SUCCESS (Xanh lá - Green) ---
  // Trạng thái hoàn thành
  static const Color success50  = Color(0xFFF2FBF3);
  static const Color success100 = Color(0xFFE0F8E4);
  static const Color success200 = Color(0xFFC3EFCA);
  static const Color success300 = Color(0xFF94E1A2);
  static const Color success400 = Color(0xFF5ECA71);
  static const Color success500 = Color(0xFF3FC157);
  static const Color success600 = Color(0xFF29903C);
  static const Color success700 = Color(0xFF247133);
  static const Color success800 = Color(0xFF215A2D);
  static const Color success900 = Color(0xFF1D4A27);
  static const Color success950 = Color(0xFF0B2812);


  // ===========================================================================
  // 4. SECONDARY COLORS
  // Các màu phụ trợ (Dùng cho Tag, Category, Chart...)
  //
  // ===========================================================================
  // Blue gray
  static const Color blueGray50  = Color(0xFFF3F6FB);
  static const Color blueGray100  = Color(0xFFE4E9F5);
  static const Color blueGray200  = Color(0xFFD0DAED);
  static const Color blueGray300  = Color(0xFFAFC1E1);
  static const Color blueGray400  = Color(0xFF89A1D1);
  static const Color blueGray500  = Color(0xFF6C84C5);
  static const Color blueGray600  = Color(0xFF596CB7);
  static const Color blueGray700  = Color(0xFF4E5BA6);
  static const Color blueGray800  = Color(0xFF444C89);
  static const Color blueGray900  = Color(0xFF3A426E);
  static const Color blueGray950  = Color(0xFF272B44);

  // Blue Light (Sky)
  static const Color blueLight50  = Color(0xFFF0F9FF);
  static const Color blueLight100 = Color(0xFFE0F2FE);
  static const Color blueLight200 = Color(0xFFB9E6FE);
  static const Color blueLight300 = Color(0xFF7BD3FE);
  static const Color blueLight400 = Color(0xFF35BDFB);
  static const Color blueLight500 = Color(0xFF0BA5EC);
  static const Color blueLight600 = Color(0xFF0084CA);
  static const Color blueLight700 = Color(0xFF0169A3);
  static const Color blueLight800 = Color(0xFF055987);
  static const Color blueLight900 = Color(0xFF0B496F);
  static const Color blueLight950 = Color(0xFF072F4A);

  // Blue (Blue)
  static const Color blue50  = Color(0xFFEFF8FF);
  static const Color blue100 = Color(0xFFDAEEFF);
  static const Color blue200 = Color(0xFFBEE2FF);
  static const Color blue300 = Color(0xFF91D0FF);
  static const Color blue400 = Color(0xFF5DB5FD);
  static const Color blue500 = Color(0xFF2E90FA);
  static const Color blue600 = Color(0xFF2176EF);
  static const Color blue700 = Color(0xFF1960DC);
  static const Color blue800 = Color(0xFF1B4DB2);
  static const Color blue900 = Color(0xFF1C448C);
  static const Color blue950 = Color(0xFF162A55);

  // Royal Blue (Indigo)
  static const Color royalBlue50  = Color(0xFFEEF4FF);
  static const Color royalBlue100 = Color(0xFFE0EAFF);
  static const Color royalBlue200 = Color(0xFFC6D7FF);
  static const Color royalBlue300 = Color(0xFFA4BBFD);
  static const Color royalBlue400 = Color(0xFF7F97FA);
  static const Color royalBlue500 = Color(0xFF6172F3);
  static const Color royalBlue600 = Color(0xFF444BE7);
  static const Color royalBlue700 = Color(0xFF3639CC);
  static const Color royalBlue800 = Color(0xFF2E31A5);
  static const Color royalBlue900 = Color(0xFF2D3282);
  static const Color royalBlue950 = Color(0xFF1A1C4C);

  // Electric Violet (Violet)
  static const Color violet50  = Color(0xFFF4F3FF);
  static const Color violet100 = Color(0xFFEBE9FE);
  static const Color violet200 = Color(0xFFD9D6FE);
  static const Color violet300 = Color(0xFFBDB4FE);
  static const Color violet400 = Color(0xFF9B8AFB);
  static const Color violet500 = Color(0xFF7A5AF8);
  static const Color violet600 = Color(0xFF6938EF);
  static const Color violet700 = Color(0xFF5B26DB);
  static const Color violet800 = Color(0xFF4C1FB8);
  static const Color violet900 = Color(0xFF401C96);
  static const Color violet950 = Color(0xFF250F66);

  // Pink
  static const Color pink50  = Color(0xFFFDF2FA);
  static const Color pink100 = Color(0xFFFCE7F7);
  static const Color pink200 = Color(0xFFFCCEF2);
  static const Color pink300 = Color(0xFFFAA7E5);
  static const Color pink400 = Color(0xFFF670D2);
  static const Color pink500 = Color(0xFFEE46BC);
  static const Color pink600 = Color(0xFFDD259D);
  static const Color pink700 = Color(0xFFC01680);
  static const Color pink800 = Color(0xFF9F156A);
  static const Color pink900 = Color(0xFF84175A);
  static const Color pink950 = Color(0xFF510634);

  //Radical Red
  static const Color radicalRed50 = Color(0xFFFFF1F3);
  static const Color radicalRed100 = Color(0xFFFFE4E8);
  static const Color radicalRed200 = Color(0xFFFFCCD6);
  static const Color radicalRed300 = Color(0xFFFEA3B4);
  static const Color radicalRed400 = Color(0xFFFD6F8D);
  static const Color radicalRed500 = Color(0xFFF63D68);
  static const Color radicalRed600 = Color(0xFFE31B53);
  static const Color radicalRed700 = Color(0xFFC01046);
  static const Color radicalRed800 = Color(0xFFA11041);
  static const Color radicalRed900 = Color(0xFF89123E);
  static const Color radicalRed950 = Color(0xFF4D041D);

  // Orange
  static const Color orange50  = Color(0xFFFFF6ED);
  static const Color orange100 = Color(0xFFFFEBD5);
  static const Color orange200 = Color(0xFFFFD2A9);
  static const Color orange300 = Color(0xFFFEB273);
  static const Color orange400 = Color(0xFFFD863A);
  static const Color orange500 = Color(0xFFFB6514);
  static const Color orange600 = Color(0xFFEC4A0A);
  static const Color orange700 = Color(0xFFC4350A);
  static const Color orange800 = Color(0xFF9B2B11);
  static const Color orange900 = Color(0xFF7D2711);
  static const Color orange950 = Color(0xFF441006);
}