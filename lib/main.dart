import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tflite_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'firebase_options.dart';

// Coffee-themed colors
const Color primaryColor = Color(0xFF6D4C41); // Brown 700
const Color primaryColorLight = Color(0xFF8D6E63); // Brown 500
const Color primaryColorDark = Color(0xFF4E342E); // Brown 900
const Color backgroundColor = Color(0xFFF5F5F5); // Grey 100 - clean and modern
const Color cardColor = Colors.white;
const Color accentColor = Color(0xFFA1887F); // Brown 300
const Color successColor = Color(0xFF388E3C); // Green 700
const Color warningColor = Color(0xFFD84315); // Deep Orange 800

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CaffioLens',
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        textTheme: GoogleFonts.latoTextTheme(textTheme).copyWith(
          bodyLarge: GoogleFonts.lato(textStyle: textTheme.bodyLarge),
          bodyMedium: GoogleFonts.lato(textStyle: textTheme.bodyMedium),
          titleLarge: GoogleFonts.lato(textStyle: textTheme.titleLarge, fontWeight: FontWeight.bold),
          headlineSmall: GoogleFonts.lato(textStyle: textTheme.headlineSmall, fontWeight: FontWeight.bold),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
        ), colorScheme: ColorScheme.fromSeed(seedColor: primaryColor).copyWith(surface: backgroundColor),
      ),
      home: const HomeScreen(),
    );
  }
}

// --- NEW ANIMATED BUTTON WIDGET ---
class AnimatedButtonWrapper extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const AnimatedButtonWrapper({
    Key? key,
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  _AnimatedButtonWrapperState createState() => _AnimatedButtonWrapperState();
}

class _AnimatedButtonWrapperState extends State<AnimatedButtonWrapper> {
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent event) {
    if (widget.enabled) {
      setState(() => _isPressed = true);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (widget.enabled) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transform = widget.enabled && _isPressed
        ? (Matrix4.identity()..scale(1.02))
        : Matrix4.identity();

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: transform,
        transformAlignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

// --- TOP NAVIGATION BAR WIDGET ---
class TopNavigationBar extends StatelessWidget {
  final String currentSection;

  const TopNavigationBar({
    Key? key,
    required this.currentSection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(
            context,
            icon: Icons.home,
            label: 'Home',
            sectionName: 'home',
            onTap: () {
              if (currentSection != 'home') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
          _buildNavButton(
            context,
            icon: Icons.camera_alt,
            label: 'Scan Image',
            sectionName: 'scan',
            onTap: () {
              if (currentSection != 'scan') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                  (route) => false,
                );
              }
            },
          ),
          _buildNavButton(
            context,
            icon: Icons.photo_library,
            label: 'Pick Gallery',
            sectionName: 'gallery',
            onTap: () async {
              final picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GalleryProcessingScreen(imagePath: image.path),
                  ),
                );
              }
            },
          ),
          _buildNavButton(
            context,
            icon: Icons.history,
            label: 'History',
            sectionName: 'history',
            onTap: () {
              if (currentSection != 'history') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const PredictionsScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sectionName,
    required VoidCallback onTap,
  }) {
    final isActive = currentSection == sectionName;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? primaryColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? primaryColor : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? primaryColor : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HOME SCREEN WIDGET ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.coffee_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'CaffioLens',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 4.0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const TopNavigationBar(currentSection: 'home'),
          Expanded(
            // Use two StreamBuilders: one for all scans (stats) and one for recent scans (display)
            child: StreamBuilder<QuerySnapshot>(
              // First stream: Get ALL scans for accurate statistics
              stream: FirebaseFirestore.instance
                  .collection('Monoy_coffeepacks')
                  .snapshots(),
              builder: (context, allScansSnapshot) {
                if (allScansSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                if (allScansSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading scans',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                if (!allScansSnapshot.hasData || allScansSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.coffee_maker, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No scans yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start scanning coffee packs to see results here',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const CameraScreen()),
                            );
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Start Scanning'),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate stats from ALL scans
                final allScans = allScansSnapshot.data!.docs;
                final totalScans = allScans.length;
                int successfulScans = 0;
                int todayScans = 0;
                
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                
                for (var doc in allScans) {
                  final data = doc.data() as Map<String, dynamic>;
                  final itemName = data['ClassType'] ?? '';
                  
                  if (itemName != 'Item Not Identified') {
                    successfulScans++;
                  }
                  
                  final timestamp = data['displayTime'] as String?;
                  if (timestamp != null) {
                    try {
                      final scanDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestamp);
                      if (scanDate.isAfter(todayStart)) {
                        todayScans++;
                      }
                    } catch (e) {}
                  }
                }
                
                final successRate = totalScans > 0 ? (successfulScans / totalScans * 100) : 0.0;

                // Second stream: Get recent 10 scans for display
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Monoy_coffeepacks')
                      .orderBy('time', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, recentScansSnapshot) {
                    if (!recentScansSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      );
                    }

                    final recentScans = recentScansSnapshot.data!.docs;

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Stats Cards (using ALL scans data)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primaryColor.withOpacity(0.15), Colors.white],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.assessment, color: primaryColor, size: 32),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$totalScans',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        Text(
                                          'Total Scans',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [successColor.withOpacity(0.15), Colors.white],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: successColor.withOpacity(0.3), width: 2),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.check_circle, color: successColor, size: 32),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${successRate.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: successColor,
                                          ),
                                        ),
                                        Text(
                                          'Success Rate',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [accentColor.withOpacity(0.15), Colors.white],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.today, color: accentColor, size: 32),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$todayScans',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                          ),
                                        ),
                                        Text(
                                          'Today',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Section Header for Recent Scans
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Scans',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColorDark,
                                  ),
                                ),
                                Text(
                                  'Last 10',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Display recent scans list
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: recentScans.length,
                            itemBuilder: (context, index) {
                              final scan = recentScans[index].data() as Map<String, dynamic>;
                              final itemName = scan['ClassType'] ?? 'Unknown';
                              final confidence = scan['Accuracy_Rate'] as double? ?? 0.0;
                              final timestamp = scan['displayTime'] ?? 'No timestamp';
                              final isIdentified = itemName != 'Item Not Identified';
                              final imagePath = scan['imagePath'] as String?;

                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isIdentified 
                                        ? successColor.withOpacity(0.3) 
                                        : warningColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Image/Avatar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: imagePath != null && File(imagePath).existsSync()
                                            ? Image.file(
                                                File(imagePath),
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: isIdentified 
                                                      ? successColor.withOpacity(0.1) 
                                                      : warningColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  isIdentified ? Icons.coffee : Icons.help_outline,
                                                  color: isIdentified ? successColor : warningColor,
                                                  size: 32,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Item details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              itemName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColorDark,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.analytics,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    timestamp,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Confidence badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isIdentified 
                                              ? successColor 
                                              : warningColor,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${(confidence * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- GALLERY PROCESSING SCREEN ---
class GalleryProcessingScreen extends StatefulWidget {
  final String imagePath;

  const GalleryProcessingScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<GalleryProcessingScreen> createState() => _GalleryProcessingScreenState();
}

class _GalleryProcessingScreenState extends State<GalleryProcessingScreen> {
  final TFLiteHelper _tfliteHelper = TFLiteHelper();
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      await _tfliteHelper.loadModel();
      final imageFile = File(widget.imagePath);
      final predictions = _tfliteHelper.predictImage(imageFile);
      
      if (mounted && predictions != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              imagePath: widget.imagePath,
              predictions: predictions,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process image')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 20),
            Text(
              'Analyzing image...',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tfliteHelper.dispose();
    super.dispose();
  }
}

class CameraScreen extends StatefulWidget {

  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String _status = 'Initializing...';
  final TFLiteHelper _tfliteHelper = TFLiteHelper();
  bool _isModelLoaded = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('Initializing app...');
    setState(() { _status = 'Loading model...'; });
    try {
      await _tfliteHelper.loadModel();
      setState(() { _isModelLoaded = true; _status = 'Model loaded. Initializing camera...'; });
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      setState(() { _status = 'Error loading model: $e'; });
      return;
    }
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    print('Initializing camera...');
    try {
      final status = await Permission.camera.request();
      print('Camera permission status: $status');
      if (status != PermissionStatus.granted) {
        print('Camera permission denied');
        setState(() { _status = 'Camera permission denied'; });
        return;
      }
      _cameras = await availableCameras();
      print('Available cameras: ${_cameras?.length ?? 0}');
      if (_cameras!.isEmpty) {
        print('No cameras found');
        setState(() { _status = 'No cameras found'; });
        return;
      }
      print('Initializing camera controller...');
      _cameraController = CameraController(_cameras![0], ResolutionPreset.high, enableAudio: false);
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);
      print('Camera controller initialized and flash set to off');
      if (mounted) {
        setState(() { _isInitialized = true; _status = 'Ready to scan'; });
      }
    } catch (e) {
      print('Camera error: $e');
      setState(() { _status = 'Camera error: $e'; });
    }
  }

  Future<void> _processImage(XFile image) async {
    if (!_isModelLoaded) return;
    try {
      setState(() { _status = 'Processing image...'; });
      final imageFile = File(image.path);
      final predictions = _tfliteHelper.predictImage(imageFile);
      if (mounted && predictions != null) {
        await Navigator.push(context, MaterialPageRoute(
            builder: (context) => ResultsScreen(imagePath: image.path, predictions: predictions),
        ));
        setState(() { _status = 'Ready to scan'; });
      } else {
        setState(() { _status = 'Error processing image'; });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to process image'), duration: Duration(seconds: 2)));
      }
    } catch (e) {
      setState(() { _status = 'Error: $e'; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), duration: const Duration(seconds: 2)));
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    final XFile image = await _cameraController!.takePicture();
    _processImage(image);
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _processImage(image);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _tfliteHelper.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.coffee_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'CaffioLens',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 4.0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const TopNavigationBar(currentSection: 'scan'),
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: _isInitialized && _isModelLoaded
                  ? CameraPreview(_cameraController!)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(_status, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
            ),
          ),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: primaryColorDark, // Darker brown
            child: Text(
              _status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            color: backgroundColor, // Match scaffold background
            child: Row(
              children: [
                Expanded(
                  child: AnimatedButtonWrapper(
                    enabled: _isInitialized && _isModelLoaded,
                    child: ElevatedButton.icon(
                      onPressed: (_isInitialized && _isModelLoaded) ? _takePicture : null,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scan'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnimatedButtonWrapper(
                    enabled: _isModelLoaded,
                    child: ElevatedButton.icon(
                      onPressed: _isModelLoaded ? _pickImageFromGallery : null,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResultsScreen extends StatefulWidget {
  final String imagePath;
  final List<Map<String, dynamic>> predictions;

  const ResultsScreen({
    super.key,
    required this.imagePath,
    required this.predictions,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const confidenceThreshold = 0.9;
      final topPredictions = widget.predictions.take(10).toList();

      if (topPredictions.isNotEmpty) {
        final topPrediction = topPredictions[0];
        final bool isPredictionConfident = topPrediction['confidence'] >= confidenceThreshold;

        if (isPredictionConfident) {
          _saveToDatabase(context, topPrediction['label'], topPrediction['confidence']);
        } else {
          _saveToDatabase(context, 'Item Not Identified', topPrediction['confidence']);
        }
      } else {
        _saveToDatabase(context, 'Item Not Identified', 0.0);
      }
    });
  }

  Future<void> _saveToDatabase(BuildContext context, String prediction, double confidence) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final firestore = FirebaseFirestore.instance;
      final String formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final double roundedConfidence = (confidence * 10000).round() / 10000.0;

      // Save image to local storage
      String? savedImagePath;
      try {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String localPath = '${appDir.path}/scan_$timestamp.jpg';
        
        // Copy the image to app directory
        final File imageFile = File(widget.imagePath);
        if (await imageFile.exists()) {
          await imageFile.copy(localPath);
          savedImagePath = localPath;
        }
      } catch (e) {
        print('Error saving image locally: $e');
      }

      await firestore.collection('Monoy_coffeepacks').add({
        'ClassType': prediction,
        'Accuracy_Rate': roundedConfidence,
        'time': FieldValue.serverTimestamp(),
        'displayTime': formattedTimestamp,
        'imagePath': savedImagePath, // Store local image path
      });

      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('Prediction saved to Firestore!'),
        backgroundColor: successColor,
      ));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('Error saving to database: $e'),
        backgroundColor: warningColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPredictions = widget.predictions.take(10).toList();
    const confidenceThreshold = 0.9;
    final bool isPredictionConfident = 
        topPredictions.isNotEmpty && topPredictions[0]['confidence'] >= confidenceThreshold;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.coffee_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'CaffioLens',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 4.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 250,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            if (topPredictions.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isPredictionConfident ? successColor : warningColor),
                ),
                child: Column(
                  children: [
                    if (isPredictionConfident) ...[
                      const Text(
                        'Top Prediction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColorDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              topPredictions[0]['label'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${(topPredictions[0]['confidence'] * 100).toStringAsFixed(2)}%',
                            style: const TextStyle(
                              fontSize: 20,
                              color: primaryColorLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'Item Not Identified',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: warningColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confidence below ${(confidenceThreshold * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Conditionally display the bar chart and predictions list
            if (isPredictionConfident) ...[
              // Bar chart
              _buildChartContainer(context, topPredictions),

              // List of all predictions
              _buildPredictionsListContainer(context, topPredictions),
            ],

            // Back button
            Container(
              margin: const EdgeInsets.all(16),
              child: AnimatedButtonWrapper(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Scan Another Image'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer(BuildContext context, List<Map<String, dynamic>> topPredictions) {
    final topPrediction = topPredictions.isNotEmpty ? topPredictions[0] : null;
    final topLabel = topPrediction != null ? topPrediction['label'] as String : 'No Data';
    final topConfidence = topPrediction != null ? topPrediction['confidence'] as double : 0.0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor,
            primaryColorLight.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.donut_large,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Confidence Distribution',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: primaryColorDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Analysis of ${topPredictions.length} predictions',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          // Donut Chart - centered without legend
          Center(
            child: SizedBox(
              height: 240,
              width: 240,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 60,
                  startDegreeOffset: -90,
                  sections: topPredictions.take(10).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final prediction = entry.value;
                    final confidence = prediction['confidence'] as double;
                    final barColor = _getVibrantColorForIndex(index);
                    
                    return PieChartSectionData(
                      color: barColor,
                      value: confidence * 100,
                      title: '',  // No text inside segments
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 0,
                      ),
                    );
                  }).toList(),
                  pieTouchData: PieTouchData(
                    enabled: true,
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Top Prediction Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getVibrantColorForIndex(0).withOpacity(0.15),
                  _getVibrantColorForIndex(0).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getVibrantColorForIndex(0).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getVibrantColorForIndex(0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Prediction',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryColorDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getVibrantColorForIndex(0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(topConfidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsListContainer(BuildContext context, List<Map<String, dynamic>> topPredictions) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.list_alt_rounded,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'All Predictions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: primaryColorDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Detailed breakdown of confidence scores',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ...topPredictions.asMap().entries.map((entry) {
            final index = entry.key;
            final prediction = entry.value;
            final confidence = prediction['confidence'] as double;
            final percentage = (confidence * 100).toStringAsFixed(1);
            final barColor = _getVibrantColorForIndex(index);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: barColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction['label'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: primaryColorDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: confidence,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Percentage
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getVibrantColorForIndex(int index) {
    // Vibrant, high-contrast colors for donut chart
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF8BC34A), // Light Green
    ];
    return colors[index % colors.length];
  }
  
  Color _getGradientColorForIndex(int index) {
    // Vibrant, modern coffee-themed gradient colors
    final colors = [
      const Color(0xFF6D4C41), // Primary brown - medium roast
      const Color(0xFF8D6E63), // Light brown
      const Color(0xFF5D4037), // Dark roast
      const Color(0xFF795548), // Regular coffee
      const Color(0xFFA1887F), // Latte
      const Color(0xFF4E342E), // Espresso
      const Color(0xFF9E9E9E), // Gray - neutral
      const Color(0xFFBCAAA4), // Milk
      const Color(0xFF757575), // Dark gray
      const Color(0xFFD7CCC8), // Foam
    ];
    return colors[index % colors.length];
  }
  
  // Keep old function for backward compatibility if needed elsewhere
  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF3E2723), // Espresso
      const Color(0xFF5D4037), // Dark Roast
      const Color(0xFF6D4C41), // Medium Roast
      const Color(0xFF795548), // Regular Coffee
      const Color(0xFF8D6E63), // Light Roast
      const Color(0xFFA1887F), // Latte
      const Color(0xFFBCAAA4), // Milk
      const Color(0xFFD7CCC8), // Foam
      const Color(0xFFEFEBE9), // Light Foam
      const Color(0xFFF5F5F5), // Extra Light
    ];
    return colors[index % colors.length];
  }
}

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan History',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 4.0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const TopNavigationBar(currentSection: 'history'),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Monoy_coffeepacks').orderBy('time', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No scan history found.'));
          }

          final predictionsList = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: predictionsList.length,
            itemBuilder: (context, index) {
              final prediction = predictionsList[index].data() as Map<String, dynamic>;
              final isIdentified = prediction['ClassType'] != 'Item Not Identified';
              final confidence = prediction['Accuracy_Rate'] as double;
              final displayTimestamp = prediction.containsKey('displayTime') 
                  ? prediction['displayTime'] 
                  : 'No timestamp available';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isIdentified ? successColor.withOpacity(0.5) : warningColor.withOpacity(0.5),
                    width: 1,
                  )
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIdentified ? successColor : warningColor,
                    child: Icon(
                      isIdentified ? Icons.check : Icons.question_mark,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    prediction['ClassType'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Accuracy Rate: ${(confidence * 100).toStringAsFixed(2)}%\n$displayTimestamp',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
            ),
          ),
        ],
      ),
    );
  }
}
