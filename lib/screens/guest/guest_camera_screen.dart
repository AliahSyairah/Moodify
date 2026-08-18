import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../music/video_player_screen.dart';
import '../../services/youtube_service.dart';

class GuestCameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final bool isGuest;

  const GuestCameraScreen({
    super.key,
    required this.camera,
    this.isGuest = true,
  });

  @override
  State<GuestCameraScreen> createState() => _GuestCameraScreenState();
}

class _GuestCameraScreenState extends State<GuestCameraScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  AnimationController? _pulseController;
  
  late FaceDetector _faceDetector;

  bool isInitialized = false;
  bool isLoading = false;
  bool showGuidesCard = false; 
  bool isDetectingFace = false; 

  String instruction = "Position your face inside the guide";
  double loadingPercentage = 0.0; 

  static const Color themeYellow = Color(0xFFF9BA36);      
  static const Color themePurpleCard = Color(0xFF1E192E);  
  static const Color neonGreen = Color(0xFF00FFCC);

  Offset leftEyePos = const Offset(75, 120);
  Offset rightEyePos = const Offset(195, 120);
  Offset nosePos = const Offset(135, 180);
  Offset mouthLeftPos = const Offset(95, 250);
  Offset mouthRightPos = const Offset(175, 250);

  final List<String> guideSteps = [
    "😄 Happy: Smile, show teeth",
    "😢 Sad: Lower lips, slightly close eyes",
    "😠 Angry: Furrow eyebrows, pucker lips",
    "😐 Neutral: Don't smile, open eyes",
  ];

  @override
  void initState() {
    super.initState();
    
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true, 
        performanceMode: FaceDetectorMode.fast, 
      ),
    );

    _initCamera();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _faceDetector.close(); 
    _pulseController?.dispose();
    if (_controller != null) {
      _controller!.dispose();
    }
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      setState(() {
        instruction = "Camera permission denied";
      });
      return;
    }

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg, 
    );

    try {
      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        isInitialized = true;
        instruction = "Ready to scan emotion";
      });

      _controller!.startImageStream((CameraImage image) async {
        if (isLoading || isDetectingFace || !mounted) return;
        
        isDetectingFace = true;

        try {
          final WriteBuffer allBytes = WriteBuffer();
          for (final Plane plane in image.planes) {
            allBytes.putUint8List(plane.bytes);
          }
          final bytes = allBytes.done().buffer.asUint8List();

          final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
          
          const InputImageRotation imageRotation = InputImageRotation.rotation270deg; 
          final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

          final inputImageMetadata = InputImageMetadata(
            size: imageSize,
            rotation: imageRotation,
            format: inputImageFormat,
            bytesPerRow: image.planes[0].bytesPerRow,
          );

          final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
          
          final List<Face> faces = await _faceDetector.processImage(inputImage);

          if (faces.isNotEmpty && mounted && !isLoading) {
            final Face face = faces.first;

            final FaceLandmark? leftEye = face.landmarks[FaceLandmarkType.leftEye];
            final FaceLandmark? rightEye = face.landmarks[FaceLandmarkType.rightEye];
            final FaceLandmark? nose = face.landmarks[FaceLandmarkType.noseBase];
            final FaceLandmark? mouthLeft = face.landmarks[FaceLandmarkType.leftMouth];
            final FaceLandmark? mouthRight = face.landmarks[FaceLandmarkType.rightMouth];

            if (leftEye != null && rightEye != null && nose != null && mouthLeft != null && mouthRight != null) {
              setState(() {
                leftEyePos = Offset(280 - (leftEye.position.x / image.width * 280), (leftEye.position.y / image.height * 360) - 60);
                rightEyePos = Offset(280 - (rightEye.position.x / image.width * 280), (rightEye.position.y / image.height * 360) - 60);
                nosePos = Offset(280 - (nose.position.x / image.width * 280), (nose.position.y / image.height * 360) - 40);
                mouthLeftPos = Offset(280 - (mouthLeft.position.x / image.width * 280), (mouthLeft.position.y / image.height * 360) - 30);
                mouthRightPos = Offset(280 - (mouthRight.position.x / image.width * 280), (mouthRight.position.y / image.height * 360) - 30);
                
                instruction = "Face Detected! Keep still ✨";
              });
            }
          } else {
            if (mounted && !isLoading) {
              setState(() {
                instruction = "Position your face inside the oval frame";
              });
            }
          }
        } catch (e) {
          debugPrint("Live tracking error: $e");
        }

        isDetectingFace = false;
      });

    } catch (e) {
      setState(() {
        instruction = "Failed to initialize camera";
      });
    }
  }

  Future<void> saveEmotionHistory({
    required String emotion,
    required String musicTitle,
  }) async {
    // 🛑 SEKATAN UTAMA: Jika guest, terus exit dan jangan panggil ApiService langsung!
    if (widget.isGuest) return; 

    try {
      final user = await SessionService.getUser();
      if (user == null || user["id"] == null) return; 
      final userId = user["id"].toString();

      await ApiService.saveEmotionHistory(
        userId: userId,
        emotion: emotion,
        musicTitle: musicTitle,
      );
    } catch (_) {}
  }

  Future<void> _capture() async {
    if (isLoading || _controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      isLoading = true;
      showGuidesCard = false; 
      instruction = "Capturing image...";
      loadingPercentage = 0.15; 
    });

    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }

      final XFile file = await _controller!.takePicture();
      if (mounted) {
        setState(() {
          instruction = "Optimizing image...";
          loadingPercentage = 0.40; 
        });
      }
      final compressedPath = "${file.path}_compressed.jpg";

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        compressedPath,
        quality: 75,
        minWidth: 720,
        minHeight: 720,
      );

      if (compressedFile == null) {
        throw Exception("Compression failed");
      }

      final imageFile = File(compressedFile.path);

      if (mounted) {
        setState(() {
          instruction = "Analyzing emotion...";
          loadingPercentage = 0.65; 
        });
      }

      final result = await ApiService.detectEmotion(imageFile).timeout(
        const Duration(seconds: 20),
      );

      String emotion = (result["emotion"] ?? "neutral").toString().toLowerCase().trim();
      const allowed = ["happy", "sad", "angry", "neutral"];

      if (!allowed.contains(emotion)) {
        emotion = "neutral";
      }

      if (mounted) {
        setState(() {
          isLoading = true;
          instruction = "Fetching your personalized playlist...";
        });

        try {
          List youtubeSongs = await YoutubeService.getVideos(emotion);

          if (mounted) {
            await saveEmotionHistory(
              emotion: emotion,
              musicTitle: youtubeSongs.isNotEmpty ? youtubeSongs[0]['title'] : "Unknown Track",
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  songs: youtubeSongs,
                  currentIndex: 0,
                  emotion: emotion,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint("Ralat pemprosesan muzik kamera: $e");
          setState(() {
            instruction = "Failed to load playlist. Try again.";
          });
        } finally {
          if (mounted) {
            setState(() => isLoading = false);
          }
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          instruction = "Error detected. Try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Stream
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(.20))),
          
         // 2. Face Scanner Frame & Points Overlay (DIBAIKI PENUH: FRAME + TITIK MUKA AUTO-SCALE)
          Center(
            child: Builder(
              builder: (context) {
                // 1. Ambil saiz lebar penuh skrin peranti semasa
                final double screenWidth = MediaQuery.of(context).size.width;

                // 2. Semak jika peranti adalah Tablet (Lebar skrin > 600)
                final bool isTablet = screenWidth > 600;

                // 3. Set saiz dinamik mengikut peranti
                final double frameWidth = isTablet ? 450 : 280;
                final double frameHeight = isTablet ? 580 : 360;

                // 4. Hitung skala nisbah (Untuk menolak posisi titik muka mengikut saiz frame tablet)
                // Nisbah dikira berpandukan saiz asas asal iaitu 280 (lebar) dan 360 (tinggi)
                final double scaleX = frameWidth / 280;
                final double scaleY = frameHeight / 360;

                return SizedBox(
                  width: frameWidth,
                  height: frameHeight,
                  child: Stack(
                    children: [
                      // Garisan Frame Bujur Pengimbas Muka
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.elliptical(frameWidth / 2, frameHeight / 2)),
                          border: Border.all(color: neonGreen, width: isTablet ? 4.0 : 2.5),
                        ),
                      ),
                      
                      // 🚀 REPAIR TITIK: Posisi (dy & dx) didarab dengan Skala semasa supaya tidak lari atau senget
                      Positioned(
                        top: leftEyePos.dy * scaleY, 
                        left: leftEyePos.dx * scaleX, 
                        child: _buildScannerPoint(),
                      ),
                      Positioned(
                        top: rightEyePos.dy * scaleY, 
                        left: rightEyePos.dx * scaleX, 
                        child: _buildScannerPoint(),
                      ),
                      Positioned(
                        top: nosePos.dy * scaleY, 
                        left: nosePos.dx * scaleX, 
                        child: _buildScannerPoint(),
                      ),
                      
                      // Garisan & Titik Mulut (Kiri dan Kanan)
                      Positioned(
                        top: ((mouthLeftPos.dy + mouthRightPos.dy) / 2) * scaleY,
                        left: mouthLeftPos.dx * scaleX,
                        right: frameWidth - (mouthRightPos.dx * scaleX), // Menggunakan frameWidth dinamik & skala X
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildScannerPoint(),
                            Expanded(
                              child: Container(
                                height: isTablet ? 2.5 : 1.5, // Tebalkan sikit garisan mulut jika di tablet
                                color: neonGreen.withOpacity(0.6),
                              ),
                            ),
                            _buildScannerPoint(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          ),
          // =========================================================================
          // FIXED REPAIR: TOP BAR SECTION (SAMA SEPERTI DESIGN IMAGE_736F26.JPG)
          // =========================================================================
          Positioned(
            top: 55,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button (Kiri)
                    GestureDetector(
                      onTap: isLoading ? null : () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themePurpleCard.withOpacity(0.85),
                          shape: BoxShape.circle,
                          border: Border.all(color: themeYellow.withOpacity(0.3), width: 1),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    
                    // Column Sebelah Kanan (AI Face Scanner + Guides Button)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // AI Face Scanner Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: themePurpleCard.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: themeYellow.withOpacity(0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.face_retouching_natural, color: themeYellow, size: 16), 
                              SizedBox(width: 6),
                              Text("AI Face Scanner", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // BUTANG GUIDES (DIBAIKPULIH KEDUDUKAN & REKA BENTUK)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showGuidesCard = !showGuidesCard;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: themePurpleCard.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: showGuidesCard ? themeYellow : themeYellow.withOpacity(0.4), 
                                width: 1.5
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  showGuidesCard ? Icons.chrome_reader_mode_rounded : Icons.chrome_reader_mode_outlined, 
                                  color: themeYellow, 
                                  size: 15
                                ), 
                                const SizedBox(width: 6),
                                const Text("Guides", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // MINI CARD POPUP (MENGGUNAKAN ANIMATEDOPACITY DI ATAS SCANNER FRAME TANPA MENGGANGGU PROSES)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: showGuidesCard ? 1.0 : 0.0,
                  child: Visibility(
                    visible: showGuidesCard,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themePurpleCard.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: themeYellow.withOpacity(0.5), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4)
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.lightbulb_rounded, color: themeYellow, size: 16),
                              SizedBox(width: 6),
                              Text(
                                "Expression Guides",
                                style: TextStyle(color: themeYellow, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 16, thickness: 1),
                          ...guideSteps.map((step) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("• ", style: TextStyle(color: themeYellow, fontSize: 13)),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: const TextStyle(
                                      color: Color(0xFFEEEEEE),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Controls and Instruction Text
          Positioned(
            bottom: 145,
            left: 40,
            right: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading) ...[
                  Text("${(loadingPercentage * 100).toInt()}%", style: const TextStyle(color: themeYellow, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    width: 220,
                    height: 6,
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: loadingPercentage,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(themeYellow),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 4. Capture Button Trigger Area
          Positioned(
            bottom: 35,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: isLoading ? null : _capture,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!isLoading && _pulseController != null)
                      AnimatedBuilder(
                        animation: _pulseController!,
                        builder: (context, child) {
                          return Container(
                            width: 82 + (_pulseController!.value * 18),
                            height: 82 + (_pulseController!.value * 18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeYellow.withOpacity(0.35 * (1.0 - _pulseController!.value)),
                            ),
                          );
                        },
                      ),
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isLoading ? [const Color(0xFF555555), const Color(0xFF333333)] : [const Color(0xFFFFFF00), themeYellow], 
                        ),
                        border: Border.all(color: isLoading ? Colors.white60 : Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: isLoading ? Colors.black38 : themeYellow.withOpacity(0.5), blurRadius: isLoading ? 6 : 14, spreadRadius: isLoading ? 1 : 3)],
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : const Icon(Icons.center_focus_strong_rounded, color: Color(0xFF111111), size: 36),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerPoint() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150), 
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: neonGreen, 
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: neonGreen, blurRadius: 6, spreadRadius: 2)],
      ),
    );
  }
}