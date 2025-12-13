import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Các tab menu bên dưới
enum BottomTab { none, colors, patterns, styles }

class ArNailTryOnPage extends StatefulWidget {
  const ArNailTryOnPage({super.key});

  @override
  State<ArNailTryOnPage> createState() => _ArNailTryOnPageState();
}

class _ArNailTryOnPageState extends State<ArNailTryOnPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  HandLandmarkerPlugin? _handPlugin;

  List<Hand> _hands = [];

  bool _isInitialized = false;
  bool _isDetecting = false;

  // UI state
  bool showSkeleton = true;
  late AnimationController _pulseAnim;
  BottomTab activeTab = BottomTab.none;

  // Nail state
  Color selectedColor = const Color(0xFFE91E63); // Pink default
  int selectedPattern = 0; // 0: Solid
  int selectedStyle = 2; // 2: Oval default

  // Dữ liệu cho UI Tabs
  final List<Color> colorPalette = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
  ];

  final List<String> patternNames = [
    "Solid",
    "Glitter",
    "Gradient",
    "French",
    "Ombre",
  ];

  final List<IconData> patternIcons = [
    Icons.circle,
    Icons.star,
    Icons.gradient,
    Icons.brush,
    Icons.blur_on,
  ];

  final List<String> styleNames = [
    "Square",
    "Round",
    "Oval",
    "Almond",
    "Stiletto",
    "Coffin",
  ];

  @override
  void initState() {
    super.initState();

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        debugPrint('Camera permission denied');
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Ưu tiên camera sau
      final camera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _handPlugin = HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.7,
        delegate: HandLandmarkerDelegate.GPU,
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo camera/hand plugin: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !_isInitialized || _handPlugin == null) return;

    _isDetecting = true;
    try {
      final hands = _handPlugin!.detect(
        image,
        _cameraController!.description.sensorOrientation,
      );

      if (mounted) {
        setState(() {
          _hands = hands;
        });
      }
    } catch (e) {
      debugPrint('Lỗi detect hand: $e');
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _flipCamera() async {
    if (_cameraController == null) return;

    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) return;

      final currentDesc = _cameraController!.description;
      final newCamera = cameras.firstWhere(
            (c) => c.lensDirection != currentDesc.lensDirection,
        orElse: () => cameras.first,
      );

      await _cameraController!.stopImageStream();
      await _cameraController!.dispose();

      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Lỗi flip camera: $e');
    }
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _handPlugin?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
    }

    final controller = _cameraController!;
    final previewSize = controller.value.previewSize!;
    final previewAspectRatio = previewSize.height / previewSize.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Vùng camera + AR
            Center(
              child: AspectRatio(
                aspectRatio: previewAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(controller),
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: HandArPainter(
                            hands: _hands,
                            previewSize: previewSize,
                            lensDirection: controller.description.lensDirection,
                            sensorOrientation:
                            controller.description.sensorOrientation,
                            showSkeleton: showSkeleton,
                            nailColor: selectedColor,
                            patternIndex: selectedPattern,
                            styleIndex: selectedStyle,
                            pulseValue: _pulseAnim.value,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // UI overlays
            _buildTopBar(),
            _buildBottomMenu(),
            _buildActivePanel(),
          ],
        ),
      ),
    );
  }

  // ================== UI TOP BAR ==================

  Widget _buildTopBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => showSkeleton = !showSkeleton),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: showSkeleton ? Colors.pink : Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    showSkeleton ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.cameraswitch,
                      color: Colors.white, size: 20),
                  onPressed: _flipCamera,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================== UI BOTTOM BAR ==================

  Widget _buildBottomMenu() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _menuItem("Colors", Icons.color_lens, BottomTab.colors),
          _menuItem("Patterns", Icons.brush, BottomTab.patterns),
          _menuItem("Styles", Icons.style, BottomTab.styles),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.pink,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Tính năng chụp ảnh chưa sẵn sàng"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _menuItem(String label, IconData icon, BottomTab tab) {
    final active = activeTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          activeTab = active ? BottomTab.none : tab;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.pink.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.pink : Colors.white70),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.pink : Colors.white70,
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== UI PANEL (COLORS / PATTERNS / STYLES) ==================

  Widget _buildActivePanel() {
    if (activeTab == BottomTab.none) return const SizedBox.shrink();

    Widget panelContent;
    switch (activeTab) {
      case BottomTab.colors:
        panelContent = _buildColorPanel();
        break;
      case BottomTab.patterns:
        panelContent = _buildPatternPanel();
        break;
      case BottomTab.styles:
        panelContent = _buildStylePanel();
        break;
      default:
        panelContent = const SizedBox.shrink();
    }

    return Positioned(
      bottom: 90,
      left: 10,
      right: 10,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: panelContent,
      ),
    );
  }

  Widget _buildColorPanel() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: colorPalette.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final color = colorPalette[index];
        final isSelected = selectedColor == color;

        return GestureDetector(
          onTap: () => setState(() => selectedColor = color),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ]
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatternPanel() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: patternNames.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final isSelected = selectedPattern == index;
        return GestureDetector(
          onTap: () => setState(() => selectedPattern = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.pink : Colors.white12,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? Colors.pinkAccent : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(patternIcons[index], color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  patternNames[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStylePanel() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: styleNames.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final isSelected = selectedStyle == index;
        return GestureDetector(
          onTap: () => setState(() => selectedStyle = index),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isSelected ? Colors.pink : Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              styleNames[index],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================== PAINTER: HAND + NAIL AR ==================

class HandArPainter extends CustomPainter {
  final List<Hand> hands;
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;
  final bool showSkeleton;
  final Color nailColor;
  final int patternIndex;
  final int styleIndex;
  final double pulseValue;

  HandArPainter({
    required this.hands,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
    required this.showSkeleton,
    required this.nailColor,
    required this.patternIndex,
    required this.styleIndex,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hands.isEmpty) return;

    // Scale để fit preview vào widget
    final scale = size.width / previewSize.height;

    canvas.save();

    // Đưa gốc tọa độ về giữa
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);

    // Xoay theo orientation của sensor
    canvas.rotate(sensorOrientation * math.pi / 180);

    // Nếu là camera trước thì lật lại cho đúng gương
    if (lensDirection == CameraLensDirection.front) {
      canvas.scale(-1, 1);
      canvas.rotate(math.pi);
    }

    canvas.scale(scale);

    final logicalWidth = previewSize.width;
    final logicalHeight = previewSize.height;

    for (final hand in hands) {
      if (showSkeleton) {
        _drawSkeleton(canvas, hand, logicalWidth, logicalHeight);
      }
      _drawNails(canvas, hand, logicalWidth, logicalHeight);
    }

    canvas.restore();
  }

  Offset _point(
      Hand hand, int index, double logicalWidth, double logicalHeight) {
    final lm = hand.landmarks[index];
    final dx = (lm.x - 0.5) * logicalWidth;
    final dy = (lm.y - 0.5) * logicalHeight;
    return Offset(dx, dy);
  }

  void _drawSkeleton(
      Canvas canvas, Hand hand, double logicalWidth, double logicalHeight) {
    final bonePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill;

    final edges = [
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 4], // Ngón cái
      [0, 5],
      [5, 6],
      [6, 7],
      [7, 8], // Ngón trỏ
      [5, 9],
      [9, 10],
      [10, 11],
      [11, 12], // Ngón giữa
      [9, 13],
      [13, 14],
      [14, 15],
      [15, 16], // Ngón áp út
      [13, 17],
      [0, 17],
      [17, 18],
      [18, 19],
      [19, 20], // Ngón út
    ];

    for (var edge in edges) {
      canvas.drawLine(
        _point(hand, edge[0], logicalWidth, logicalHeight),
        _point(hand, edge[1], logicalWidth, logicalHeight),
        bonePaint,
      );
    }

    for (int i = 0; i < hand.landmarks.length; i++) {
      canvas.drawCircle(
        _point(hand, i, logicalWidth, logicalHeight),
        5,
        jointPaint,
      );
    }
  }

  void _drawNails(
      Canvas canvas, Hand hand, double logicalWidth, double logicalHeight) {
    final fingertips = [4, 8, 12, 16, 20];
    final dipJoints = [3, 7, 11, 15, 19];

    for (int i = 0; i < fingertips.length; i++) {
      final tipIdx = fingertips[i];
      final dipIdx = dipJoints[i];

      final tipPos = _point(hand, tipIdx, logicalWidth, logicalHeight);
      final dipPos = _point(hand, dipIdx, logicalWidth, logicalHeight);

      final baseSize = logicalWidth * 0.035;
      final animatedSize = baseSize * (1 + pulseValue * 0.15);

      final dx = tipPos.dx - dipPos.dx;
      final dy = tipPos.dy - dipPos.dy;
      final angle = math.atan2(dy, dx) + math.pi / 2;

      canvas.save();
      canvas.translate(tipPos.dx, tipPos.dy);
      canvas.rotate(angle);

      _drawSingleNail(canvas, Offset.zero, animatedSize);

      canvas.restore();
    }
  }

  void _drawSingleNail(Canvas canvas, Offset center, double s) {
    switch (patternIndex) {
      case 1:
        _drawGlitter(canvas, center, s);
        break;
      case 2:
        _drawGradient(canvas, center, s);
        break;
      case 3:
        _drawFrench(canvas, center, s);
        break;
      case 4:
        _drawOmbre(canvas, center, s);
        break;
      default:
        _drawSolid(canvas, center, s);
    }
  }

  Paint _getBasePaint() => Paint()
    ..color = nailColor
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  void _drawShape(Canvas canvas, Offset c, double s, Paint p) {
    final width = s * 1.8;
    final height = s * 2.2;
    final rect = Rect.fromCenter(center: c, width: width, height: height);

    switch (styleIndex) {
      case 0: // Square
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          p,
        );
        break;
      case 1: // Round
        canvas.drawCircle(c, s, p);
        break;
      case 3: // Almond
        _drawAlmondPath(canvas, rect, p);
        break;
      case 4: // Stiletto
        _drawStilettoPath(canvas, rect, p);
        break;
      case 5: // Coffin
        _drawCoffinPath(canvas, rect, p);
        break;
      default: // Oval
        canvas.drawOval(rect, p);
    }
  }

  void _drawAlmondPath(Canvas canvas, Rect rect, Paint p) {
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..quadraticBezierTo(
          rect.right, rect.top + rect.height * 0.3, rect.right,
          rect.bottom - rect.height * 0.2)
      ..quadraticBezierTo(rect.right, rect.bottom, rect.center.dx, rect.bottom)
      ..quadraticBezierTo(
          rect.left, rect.bottom, rect.left, rect.bottom - rect.height * 0.2)
      ..quadraticBezierTo(
          rect.left, rect.top + rect.height * 0.3, rect.center.dx, rect.top);
    canvas.drawPath(path, p);
  }

  void _drawStilettoPath(Canvas canvas, Rect rect, Paint p) {
    final path = Path()
      ..moveTo(rect.center.dx, rect.top - rect.height * 0.1)
      ..lineTo(rect.right, rect.bottom - rect.height * 0.3)
      ..quadraticBezierTo(rect.right, rect.bottom, rect.center.dx, rect.bottom)
      ..quadraticBezierTo(
          rect.left, rect.bottom, rect.left, rect.bottom - rect.height * 0.3)
      ..close();
    canvas.drawPath(path, p);
  }

  void _drawCoffinPath(Canvas canvas, Rect rect, Paint p) {
    final path = Path()
      ..moveTo(rect.center.dx - rect.width * 0.3, rect.top)
      ..lineTo(rect.center.dx + rect.width * 0.3, rect.top)
      ..lineTo(rect.right, rect.bottom - rect.height * 0.2)
      ..quadraticBezierTo(rect.right, rect.bottom, rect.center.dx, rect.bottom)
      ..quadraticBezierTo(
          rect.left, rect.bottom, rect.left, rect.bottom - rect.height * 0.2)
      ..close();
    canvas.drawPath(path, p);
  }

  void _drawSolid(Canvas canvas, Offset c, double s) {
    _drawShape(canvas, c, s, _getBasePaint());
  }

  void _drawGlitter(Canvas canvas, Offset c, double s) {
    _drawSolid(canvas, c, s);

    final rnd = math.Random();
    final glitterPaint = Paint()..color = Colors.white.withOpacity(0.8);

    canvas.save();
    canvas.clipRect(
      Rect.fromCenter(center: c, width: s * 2, height: s * 2.5),
    );

    for (int i = 0; i < 20; i++) {
      final dx = c.dx + (rnd.nextDouble() * 2 - 1) * s * 0.8;
      final dy = c.dy + (rnd.nextDouble() * 2 - 1) * s * 1.0;
      canvas.drawCircle(
        Offset(dx, dy),
        s * (0.05 + rnd.nextDouble() * 0.05),
        glitterPaint,
      );
    }
    canvas.restore();
  }

  void _drawGradient(Canvas canvas, Offset c, double s) {
    final rect = Rect.fromCenter(center: c, width: s * 2, height: s * 2.5);
    final p = Paint()
      ..shader = RadialGradient(
        colors: [nailColor.withOpacity(0.4), nailColor],
        stops: const [0.2, 1.0],
        center: Alignment.topLeft,
      ).createShader(rect);
    _drawShape(canvas, c, s, p);
  }

  void _drawFrench(Canvas canvas, Offset c, double s) {
    final baseColor = nailColor.withOpacity(0.3);
    _drawShape(canvas, c, s, Paint()..color = baseColor);

    final tipPaint = Paint()..color = Colors.white;
    final width = s * 1.8;
    final height = s * 2.2;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy - height * 0.3),
        width: width,
        height: height * 0.6,
      ),
      math.pi,
      math.pi,
      true,
      tipPaint,
    );

    _drawShape(
      canvas,
      c,
      s,
      Paint()
        ..color = nailColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawOmbre(Canvas canvas, Offset c, double s) {
    final rect = Rect.fromCenter(center: c, width: s * 2, height: s * 2.5);
    final p = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.2), nailColor],
      ).createShader(rect);
    _drawShape(canvas, c, s, p);
  }

  @override
  bool shouldRepaint(covariant HandArPainter oldDelegate) {
    return oldDelegate.hands != hands ||
        oldDelegate.showSkeleton != showSkeleton ||
        oldDelegate.nailColor != nailColor ||
        oldDelegate.patternIndex != patternIndex ||
        oldDelegate.styleIndex != styleIndex ||
        oldDelegate.pulseValue != pulseValue;
  }
}
