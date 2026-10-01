import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

const String websiteUrl =
    'https://shansari901-dot.github.io/Apna-Cheetr/';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ApnaChetrApp());
}

class ApnaChetrApp extends StatelessWidget {
  const ApnaChetrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Apna Chhetr',
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final webController = WebViewController();

    if (webController.platform is AndroidWebViewController) {
      final androidController =
          webController.platform as AndroidWebViewController;

      await androidController.setGeolocationEnabled(true);

      await androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          final locationStatus = await Permission.location.request();

          return GeolocationPermissionsResponse(
            allow: locationStatus.isGranted,
            retain: locationStatus.isGranted,
          );
        },
      );
    }

    webController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F1729))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;

            if (url.startsWith('http://') || url.startsWith('https://')) {
              if (url.contains('shansari901-dot.github.io')) {
                return NavigationDecision.navigate;
              }

              _openExternal(url);
              return NavigationDecision.prevent;
            }

            _openExternal(url);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(websiteUrl));

    if (mounted) {
      setState(() {
        controller = webController;
      });
    }
  }

  Future<void> _openExternal(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not open $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1729),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.green,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: controller!),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
