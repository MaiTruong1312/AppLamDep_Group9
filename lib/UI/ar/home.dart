import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

enum BottomTab { none, designs, adjust }

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
  bool _isCapturing = false; // Thêm biến trạng thái chụp ảnh

  // UI state
  bool showSkeleton = true;
  late AnimationController _pulseAnim;
  BottomTab activeTab = BottomTab.none;

  // Chọn mẫu nail
  int selectedDesign = 0;

  // DANH SÁCH MẪU NAIL
  final List<String> nailDesigns = [
    'assets/images/nail_designs/des1.png',
    'assets/images/nail_designs/des2.png',
    'assets/images/nail_designs/des3.png',
    'assets/images/nail_designs/des4.png',
    'assets/images/nail_designs/des5.png',
    'assets/images/nail_designs/des6.png',
    'assets/images/nail_designs/des7.png',
    'assets/images/nail_designs/des8.png',
    'assets/images/nail_designs/des9.png',
    'assets/images/nail_designs/des10.png',
  ];

  // CACHE để lưu ảnh đã tải
  final Map<int, ui.Image> _cachedImages = {};
  bool _isPreloading = false;

  // ================== THÊM CÁC BIẾN TÙY CHỈNH ==================
  double nailSize = 1.0;
  Offset nailOffset = Offset.zero;
  double nailRotation = 0.0;
  double nailOpacity = 1.0;
  Color? blendColor;
  bool enableShadow = false;
  bool enableGlow = false;

  final List<Map<String, dynamic>> _savedPresets = [];

  // Key cho RenderRepaintBoundary (để chụp widget)
  final GlobalKey _renderKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initialize();
    _preloadNailDesigns();
  }

  Future<void> _preloadNailDesigns() async {
    if (_isPreloading) return;
    _isPreloading = true;

    for (int i = 0; i < nailDesigns.length; i++) {
      try {
        final ByteData data = await rootBundle.load(nailDesigns[i]);
        final Uint8List bytes = data.buffer.asUint8List();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frame = await codec.getNextFrame();
        _cachedImages[i] = frame.image;
        debugPrint('✅ Đã tải mẫu nail: ${nailDesigns[i]}');
      } catch (e) {
        debugPrint('❌ Lỗi tải ảnh ${nailDesigns[i]}: $e');
      }
    }
    _isPreloading = false;

    if (mounted) {
      setState(() {});
    }
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

  // ================== HÀM CHỤP ẢNH ==================

  Future<void> _captureAndSaveImage() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // 1. Kiểm tra quyền lưu ảnh
      final permission = await Permission.photos.request();
      if (!permission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cần cấp quyền truy cập thư viện ảnh'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Hiệu ứng flash khi chụp
      await _showFlashEffect();

      // 3. Chụp ảnh từ camera
      final XFile? rawImage = await _cameraController?.takePicture();
      if (rawImage == null) {
        throw Exception('Không thể chụp ảnh');
      }

      // 4. Tạo ảnh AR composite
      final Uint8List? arImage = await _captureArScene();

      if (arImage != null) {
        // 5. Lưu ảnh vào thư viện
        await _saveImageToGallery(arImage);
      } else {
        // Fallback: Lưu ảnh camera thường
        await _saveImageFileToGallery(rawImage);
      }

    } catch (e) {
      debugPrint('Lỗi chụp ảnh: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _showFlashEffect() async {
    // Hiệu ứng flash trắng
    final overlayColor = Colors.white.withOpacity(0.7);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) => Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: overlayColor,
          child: const SizedBox.expand(),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    await Future.delayed(const Duration(milliseconds: 50));
  }
  // THÊM HÀM NÀY (thiếu trong code của bạn)
  Future<void> _saveImageFileToGallery(XFile imageFile) async {
    try {
      // Kiểm tra quyền
      final permission = await Permission.photos.status;
      if (permission != PermissionStatus.granted) {
        final newPermission = await Permission.photos.request();
        if (newPermission != PermissionStatus.granted) {
          throw Exception('Không có quyền truy cập thư viện ảnh');
        }
      }

      // Lưu trực tiếp file từ camera
      await Gal.putImage(
        imageFile.path,
        album: 'Nail AR',
      );

      // Hiển thị thông báo
      if (mounted) {
        _showSuccessDialog(imageFile.path.split('/').last);
      }

      debugPrint('✅ Đã lưu ảnh từ camera: ${imageFile.path}');

    } on PlatformException catch (e) {
      debugPrint('Lỗi PlatformException: ${e.message}');
      throw Exception('Lỗi hệ thống: ${e.message}');
    } catch (e) {
      debugPrint('Lỗi không xác định: $e');
      throw Exception('Không thể lưu ảnh: $e');
    }
  }
  Future<Uint8List?> _captureArScene() async {
    try {
      // Tạo RenderRepaintBoundary để chụp widget
      final renderObject = _renderKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        return null;
      }

      // Chuyển widget thành ảnh
      final ui.Image image = await renderObject.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Lỗi chụp AR scene: $e');
      return null;
    }
  }

  Future<void> _saveImageToGallery(Uint8List imageBytes) async {
    try {
      // Kiểm tra quyền trước khi lưu
      final permission = await Permission.photos.status;
      if (permission != PermissionStatus.granted) {
        final newPermission = await Permission.photos.request();
        if (newPermission != PermissionStatus.granted) {
          throw Exception('Không có quyền truy cập thư viện ảnh');
        }
      }

      // Tạo file với chất lượng tốt
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Nail_AR_$timestamp.png';
      final filePath = '${tempDir.path}/$fileName';

      // Lưu file với độ nén tốt
      final imageFile = File(filePath);
      await imageFile.writeAsBytes(imageBytes, flush: true);

      // Lưu vào gallery
      await Gal.putImage(
        filePath,
        album: 'Nail AR',
      );

      // Hiển thị thông báo
      if (mounted) {
        _showSuccessDialog(fileName);
      }

      // Log cho debug
      debugPrint('✅ Đã lưu ảnh: $fileName');

      // Dọn dẹp file tạm
      _cleanupTempFile(imageFile);

    } on PlatformException catch (e) {
      debugPrint('Lỗi PlatformException: ${e.message}');
      throw Exception('Lỗi hệ thống: ${e.message}');
    } catch (e) {
      debugPrint('Lỗi không xác định: $e');
      throw Exception('Không thể lưu ảnh: $e');
    }
  }

// Hàm dọn dẹp file tạm
  void _cleanupTempFile(File file) {
    try {
      Future.delayed(const Duration(seconds: 30), () async {
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑️ Đã xóa file tạm');
        }
      });
    } catch (e) {
      debugPrint('Lỗi xóa file tạm: $e');
    }
  }

  // SỬA HÀM NÀY
  void _showSuccessDialog(String fileName) {  // Thay đổi tham số từ String? thành String
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '✅ Đã lưu ảnh',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ảnh đã được lưu vào thư viện ảnh',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Tên file: $fileName',  // Sử dụng fileName thay vì filePath
              style: const TextStyle(color: Colors.grey, fontSize: 12),  // Tăng fontSize từ 10 lên 12
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.pink)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Có thể thêm chức năng chia sẻ ảnh ở đây
            },
            child: const Text('Chia sẻ', style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  // ================== HÀM TÙY CHỈNH ==================

  void _resetAdjustments() {
    setState(() {
      nailSize = 1.0;
      nailOffset = Offset.zero;
      nailRotation = 0.0;
      nailOpacity = 1.0;
      blendColor = null;
      enableShadow = true;
      enableGlow = false;
    });
  }

  void _saveCurrentPreset() {
    final preset = {
      'name': 'Preset ${_savedPresets.length + 1}',
      'size': nailSize,
      'offset': nailOffset,
      'rotation': nailRotation,
      'opacity': nailOpacity,
      'blendColor': blendColor,
      'enableShadow': enableShadow,
      'enableGlow': enableGlow,
      'designIndex': selectedDesign,
    };
    setState(() {
      _savedPresets.add(preset);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu preset'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _loadPreset(int index) {
    if (index < _savedPresets.length) {
      final preset = _savedPresets[index];
      setState(() {
        nailSize = preset['size'];
        nailOffset = preset['offset'];
        nailRotation = preset['rotation'];
        nailOpacity = preset['opacity'];
        blendColor = preset['blendColor'];
        enableShadow = preset['enableShadow'];
        enableGlow = preset['enableGlow'];
        selectedDesign = preset['designIndex'];
      });
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
            // Vùng camera + AR với RepaintBoundary để chụp ảnh
            RepaintBoundary(
              key: _renderKey,
              child: Center(
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
                              selectedDesign: selectedDesign,
                              cachedImages: _cachedImages,
                              pulseValue: _pulseAnim.value,
                              // Truyền các tham số tùy chỉnh
                              nailSize: nailSize,
                              nailOffset: nailOffset,
                              nailRotation: nailRotation,
                              nailOpacity: nailOpacity,
                              blendColor: blendColor,
                              enableShadow: enableShadow,
                              enableGlow: enableGlow,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // UI overlays
            _buildTopBar(),
            _buildBottomMenu(),
            _buildActivePanel(),

            // Hiển thị thông số tùy chỉnh (khi đang adjust)
            if (activeTab == BottomTab.adjust) _buildAdjustmentOverlay(),

            // Loading overlay khi đang chụp ảnh
            if (_isCapturing) _buildCaptureOverlay(),
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
            _menuItem("Mẫu", Icons.brush, BottomTab.designs),
            _menuItem("Tùy chỉnh", Icons.tune, BottomTab.adjust),
            // Nút chụp ảnh với trạng thái loading
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: _isCapturing
                  ? const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: Colors.pink,
                  strokeWidth: 3,
                ),
              )
                  : CircleAvatar(
                radius: 24,
                backgroundColor: Colors.pink,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: _captureAndSaveImage,
                ),
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

  // ================== OVERLAY KHI CHỤP ẢNH ==================

  Widget _buildCaptureOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.pink),
              SizedBox(height: 20),
              Text(
                'Đang xử lý ảnh...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================== UI PANEL (DESIGNS) ==================

  Widget _buildActivePanel() {
    if (activeTab == BottomTab.none) return const SizedBox.shrink();

    if (activeTab == BottomTab.designs) {
      return Positioned(
        bottom: 90,
        left: 10,
        right: 10,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  "CHỌN MẪU NAIL",
                  style: TextStyle(
                    color: Colors.pink[200],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: nailDesigns.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final isSelected = selectedDesign == index;
                    return GestureDetector(
                      onTap: () => setState(() => selectedDesign = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.pink
                                : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Image.asset(
                                nailDesigns[index],
                                fit: BoxFit.cover,
                              ),
                              if (isSelected)
                                Container(
                                  color: Colors.pink.withOpacity(0.15),
                                  child: const Center(
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

    return const SizedBox.shrink();
  }

  // ================== PANEL TÙY CHỈNH ==================

  Widget _buildAdjustmentOverlay() {
    return Positioned(
      bottom: 90,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TÙY CHỈNH NAIL",
                  style: TextStyle(
                    color: Colors.pink[200],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.save, color: Colors.pink, size: 20),
                      onPressed: _saveCurrentPreset,
                      tooltip: 'Lưu preset',
                    ),
                    IconButton(
                      icon: Icon(Icons.restart_alt, color: Colors.white70, size: 20),
                      onPressed: _resetAdjustments,
                      tooltip: 'Reset',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kích thước
            _buildSlider(
              label: "Kích thước",
              value: nailSize,
              min: 0.5,
              max: 2.0,
              onChange: (value) => setState(() => nailSize = value),
              format: (value) => '${(value * 100).toInt()}%',
            ),

            // Độ trong suốt
            _buildSlider(
              label: "Độ trong suốt",
              value: nailOpacity,
              min: 0.0,
              max: 1.0,
              onChange: (value) => setState(() => nailOpacity = value),
              format: (value) => '${(value * 100).toInt()}%',
            ),

            // Góc xoay
            _buildSlider(
              label: "Góc xoay",
              value: nailRotation,
              min: -math.pi,
              max: math.pi,
              onChange: (value) => setState(() => nailRotation = value),
              format: (value) => '${(value * 180 / math.pi).round()}°',
            ),

            // Vị trí (Offset)
            Row(
              children: [
                Expanded(
                  child: _buildSlider(
                    label: "Dịch ngang",
                    value: nailOffset.dx,
                    min: -50,
                    max: 50,
                    onChange: (value) => setState(() => nailOffset = Offset(value, nailOffset.dy)),
                    format: (value) => '${value.round()}px',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSlider(
                    label: "Dịch dọc",
                    value: nailOffset.dy,
                    min: -50,
                    max: 50,
                    onChange: (value) => setState(() => nailOffset = Offset(nailOffset.dx, value)),
                    format: (value) => '${value.round()}px',
                  ),
                ),
              ],
            ),

            // Các toggle
            Row(
              children: [
                _buildToggle(
                  label: "Đổ bóng",
                  value: enableShadow,
                  onChange: (value) => setState(() => enableShadow = value),
                ),
                const SizedBox(width: 16),
                _buildToggle(
                  label: "Hiệu ứng sáng",
                  value: enableGlow,
                  onChange: (value) => setState(() => enableGlow = value),
                ),
              ],
            ),

            // Màu blend
            const SizedBox(height: 12),
            Text(
              "Màu pha trộn:",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => blendColor = null),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: blendColor == null ? Colors.pink : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text("None", style: TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    ),
                  ),
                  ..._buildColorOptions(),
                ],
              ),
            ),

            // Hiển thị preset đã lưu
            if (_savedPresets.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "PRESET ĐÃ LƯU:",
                style: TextStyle(color: Colors.pink[200], fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _savedPresets.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _loadPreset(index),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.pink),
                        ),
                        child: Center(
                          child: Text(
                            _savedPresets[index]['name'],
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChange,
    required String Function(double) format,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              format(value),
              style: TextStyle(color: Colors.pink, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChange,
          activeColor: Colors.pink,
          inactiveColor: Colors.grey[700],
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required Function(bool) onChange,
  }) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChange,
          activeColor: Colors.pink,
          activeTrackColor: Colors.pink[200],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  List<Widget> _buildColorOptions() {
    final colors = [
      Colors.pink.withOpacity(0.5),
      Colors.red.withOpacity(0.5),
      Colors.orange.withOpacity(0.5),
      Colors.yellow.withOpacity(0.5),
      Colors.green.withOpacity(0.5),
      Colors.blue.withOpacity(0.5),
      Colors.purple.withOpacity(0.5),
      Colors.white.withOpacity(0.5),
      Colors.black.withOpacity(0.5),
    ];

    return colors.map((color) {
      return GestureDetector(
        onTap: () => setState(() => blendColor = color),
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: blendColor == color ? Colors.pink : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ================== PAINTER: HAND + NAIL AR ==================

class HandArPainter extends CustomPainter {
  final List<Hand> hands;
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;
  final bool showSkeleton;
  final int selectedDesign;
  final Map<int, ui.Image> cachedImages; // ĐÃ CÓ
  final double pulseValue;

  // Thêm các tham số tùy chỉnh
  final double nailSize;
  final Offset nailOffset;
  final double nailRotation;
  final double nailOpacity;
  final Color? blendColor;
  final bool enableShadow;
  final bool enableGlow;

  HandArPainter({
    required this.hands,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
    required this.showSkeleton,
    required this.selectedDesign,
    required this.cachedImages,
    required this.pulseValue,
    // Thêm các tham số tùy chỉnh
    this.nailSize = 1.0,
    this.nailOffset = Offset.zero,
    this.nailRotation = 0.0,
    this.nailOpacity = 1.0,
    this.blendColor,
    this.enableShadow = true,
    this.enableGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hands.isEmpty) return;

    final scale = size.width / previewSize.height;
    canvas.save();
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sensorOrientation * math.pi / 180);

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
      _drawNailsWithAdjustments(canvas, hand, logicalWidth, logicalHeight);
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
      [0, 1], [1, 2], [2, 3], [3, 4],
      [0, 5], [5, 6], [6, 7], [7, 8],
      [5, 9], [9, 10], [10, 11], [11, 12],
      [9, 13], [13, 14], [14, 15], [15, 16],
      [13, 17], [0, 17], [17, 18], [18, 19], [19, 20],
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

  void _drawNailsWithAdjustments(
      Canvas canvas, Hand hand, double logicalWidth, double logicalHeight) {
    final fingertips = [4, 8, 12, 16, 20];
    final dipJoints = [3, 7, 11, 15, 19];

    // SỬA: Lấy ảnh trực tiếp từ cachedImages
    final ui.Image? designImage = cachedImages[selectedDesign];

    // Nếu chưa có ảnh, vẽ placeholder
    if (designImage == null) {
      _drawPlaceholderNails(canvas, hand, logicalWidth, logicalHeight);
      return;
    }

    final srcWidth = designImage.width.toDouble();
    final srcHeight = designImage.height.toDouble();
    final srcRect = Rect.fromLTWH(0, 0, srcWidth, srcHeight);

    for (int i = 0; i < fingertips.length; i++) {
      final tipIdx = fingertips[i];
      final dipIdx = dipJoints[i];

      final tipPos = _point(hand, tipIdx, logicalWidth, logicalHeight);
      final dipPos = _point(hand, dipIdx, logicalWidth, logicalHeight);

      // Kích thước cơ bản với multiplier
      final baseSize = logicalWidth * 0.035 * nailSize;
      final animatedSize = baseSize * (1 + pulseValue * 0.15);
      final displayWidth = animatedSize * 3.0;
      final displayHeight = animatedSize * 3.5;

      // Tính góc xoay theo hướng ngón tay + góc bổ sung
      final dx = tipPos.dx - dipPos.dx;
      final dy = tipPos.dy - dipPos.dy;
      final fingerAngle = math.atan2(dy, dx) + math.pi / 2;
      final totalRotation = fingerAngle + nailRotation;

      canvas.save();

      // Áp dụng offset
      final adjustedTipPos = tipPos + nailOffset;
      canvas.translate(adjustedTipPos.dx, adjustedTipPos.dy);
      canvas.rotate(totalRotation);

      // Vẽ shadow nếu bật
      if (enableShadow) {
        _drawShadow(canvas, displayWidth, displayHeight);
      }

      // Vẽ ảnh mẫu với opacity
      final dstRect = Rect.fromCenter(
        center: Offset.zero,
        width: displayWidth,
        height: displayHeight,
      );

      final paint = Paint();
      if (blendColor != null) {
        paint.colorFilter = ColorFilter.mode(blendColor!, BlendMode.color);
      }
      paint.color = paint.color.withOpacity(nailOpacity);

      canvas.drawImageRect(designImage, srcRect, dstRect, paint);

      // Vẽ glow effect nếu bật
      if (enableGlow) {
        _drawGlowEffect(canvas, displayWidth, displayHeight);
      }

      // Thêm viền trang trí
      if (showSkeleton) {
        canvas.drawRect(
          dstRect.deflate(1),
          Paint()
            ..color = Colors.white.withOpacity(0.3 * nailOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      canvas.restore();
    }
  }

  void _drawShadow(Canvas canvas, double width, double height) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(4, 4), // Độ lệch shadow
        width: width,
        height: height,
      ),
      shadowPaint,
    );
  }

  void _drawGlowEffect(Canvas canvas, double width, double height) {
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: width * 1.1,
      height: height * 1.1,
    );

    canvas.drawRect(rect, glowPaint);
  }

  void _drawPlaceholderNails(
      Canvas canvas, Hand hand, double logicalWidth, double logicalHeight) {
    final fingertips = [4, 8, 12, 16, 20];
    final dipJoints = [3, 7, 11, 15, 19];

    final placeholderPaint = Paint()
      ..color = Colors.pink.withOpacity(0.7 * nailOpacity)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < fingertips.length; i++) {
      final tipIdx = fingertips[i];
      final dipIdx = dipJoints[i];

      final tipPos = _point(hand, tipIdx, logicalWidth, logicalHeight);
      final dipPos = _point(hand, dipIdx, logicalWidth, logicalHeight);

      final baseSize = logicalWidth * 0.035 * nailSize;
      final animatedSize = baseSize * (1 + pulseValue * 0.15);

      final dx = tipPos.dx - dipPos.dx;
      final dy = tipPos.dy - dipPos.dy;
      final fingerAngle = math.atan2(dy, dx) + math.pi / 2;
      final totalRotation = fingerAngle + nailRotation;

      canvas.save();
      final adjustedTipPos = tipPos + nailOffset;
      canvas.translate(adjustedTipPos.dx, adjustedTipPos.dy);
      canvas.rotate(totalRotation);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: animatedSize * 1.8,
          height: animatedSize * 2.2,
        ),
        placeholderPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant HandArPainter oldDelegate) {
    return oldDelegate.hands != hands ||
        oldDelegate.showSkeleton != showSkeleton ||
        oldDelegate.selectedDesign != selectedDesign ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.nailSize != nailSize ||
        oldDelegate.nailOffset != nailOffset ||
        oldDelegate.nailRotation != nailRotation ||
        oldDelegate.nailOpacity != nailOpacity ||
        oldDelegate.blendColor != blendColor ||
        oldDelegate.enableShadow != enableShadow ||
        oldDelegate.enableGlow != enableGlow;
  }
}