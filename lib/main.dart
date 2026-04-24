import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String _homeUrl = 'https://aminosocial.com/';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AminoSocialApp());
}

class AminoSocialApp extends StatelessWidget {
  const AminoSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AminoSocial',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WebviewHomePage(),
    );
  }
}

class WebviewHomePage extends StatefulWidget {
  const WebviewHomePage({super.key});

  @override
  State<WebviewHomePage> createState() => _WebviewHomePageState();
}

class _WebviewHomePageState extends State<WebviewHomePage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _isSplashVisible = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (!mounted) {
              return;
            }
            setState(() => _progress = value);
          },
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }
            setState(() => _loadError = null);
          },
          onPageFinished: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _progress = 100;
              _isSplashVisible = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) {
              return;
            }
            setState(() {
              _loadError = error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_homeUrl));
  }

  Future<void> _reloadPage() async {
    setState(() {
      _loadError = null;
      _isSplashVisible = true;
      _progress = 0;
    });
    await _controller.reload();
  }

  Future<bool> _handleBackNavigation() async {
    final canGoBack = await _controller.canGoBack();
    if (canGoBack) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        final shouldPop = await _handleBackNavigation();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AminoSocial'),
          actions: [
            IconButton(
              onPressed: () => _controller.loadRequest(Uri.parse(_homeUrl)),
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Home',
            ),
            IconButton(
              onPressed: _reloadPage,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload',
            ),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => _controller.reload(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: WebViewWidget(controller: _controller),
                  ),
                ],
              ),
            ),
            if (_progress < 100 && _loadError == null)
              LinearProgressIndicator(value: _progress / 100),
            if (_isSplashVisible && _loadError == null) const _SplashOverlay(),
            if (_loadError != null)
              _ErrorOverlay(
                errorMessage: _loadError!,
                onRetry: _reloadPage,
              ),
          ],
        ),
      ),
    );
  }
}

class _SplashOverlay extends StatelessWidget {
  const _SplashOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public, size: 64),
            SizedBox(height: 12),
            Text(
              'AminoSocial',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.errorMessage, required this.onRetry});

  final String errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 52),
              const SizedBox(height: 16),
              const Text(
                'Could not load AminoSocial',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
