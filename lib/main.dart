import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

const String WEBSITE_URL = 'https://shansari901-dot.github.io/Apna-Cheetr/';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apna Chhetr',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// 🔥 SPLASH SCREEN - Permissions request karega
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    // 🔥 Request location permission
    await _requestPermissions();
    
    // Small delay for splash
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WebViewScreen()),
      );
    }
  }

  Future<void> _requestPermissions() async {
    // Location permission
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
    if (await Permission.locationWhenInUse.isDenied) {
      await Permission.locationWhenInUse.request();
    }
    // Camera (for story uploads)
    if (await Permission.camera.isDenied) {
      await Permission.camera.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1729),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text('🏘️', style: TextStyle(fontSize: 65)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'अपना क्षेत्र',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'लोकल जानकारी • अपनी सेवा',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0f1729))
      // 🔥 Enable geolocation in WebView
      ..setGeolocationEnabled(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (url.startsWith('http://') || url.startsWith('https://')) {
              if (!url.contains('shansari901-dot.github.io')) {
                _openExternal(url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            }
            _openExternal(url);
            return NavigationDecision.prevent;
          },
          // 🔥 Handle permission requests from webview (location)
          onPermissionRequest: (request) {
            request.grant();
          },
        ),
      )
      ..loadRequest(Uri.parse(WEBSITE_URL));
  }

  Future<void> _openExternal(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await controller.canGoBack()) {
          await controller.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: controller),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
