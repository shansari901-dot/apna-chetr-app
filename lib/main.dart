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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
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
  late final WebViewController controller;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    // Android location permission
    await Permission.location.request();

    final webViewController = WebViewController();

    // Android WebView location configuration
    if (webViewController.platform is AndroidWebViewController) {
      final androidController =
          webViewController.platform as AndroidWebViewController;

      await androidController.setGeolocationEnabled(true);

      await androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          final status = await Permission.location.status;

          if (status.isGranted) {
            return const GeolocationPermissionsResponse(
              allow: true,
              retain: true,
            );
          }

          final result = await Permission.location.request();

          return GeolocationPermissionsResponse(
            allow: result.isGranted,
            retain: result.isGranted,
          );
        },
      );
    }

    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F1729))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            if (url.startsWith('http://') ||
                url.startsWith('https://')) {
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

    controller = webViewController;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openExternal(String url) async {
    try {
      final uri = Uri.parse(url);

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not open $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
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
            WebViewWidget(
              controller: controller,
            ),

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

  bool get isInitialized => _controllerReady;

  bool _controllerReady = false;

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);

      if (controllerInitialized) {
        _controllerReady = true;
      }
    }
  }

  bool get controllerInitialized {
    try {
      return controller != null;
    } catch (_) {
      return false;
    }
  }
}
