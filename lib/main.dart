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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              const Text('AminoSocial'),
            ],
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.9),
            colorScheme.surface,
            colorScheme.tertiaryContainer.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'AminoSocial',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'aminosocial.com',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
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
