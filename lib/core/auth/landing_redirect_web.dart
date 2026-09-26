import 'package:web/web.dart' as web;

/// Redirects the browser window to the Scholaris marketing landing page.
///
/// In local development (localhost / port 5000), redirects to the landing page
/// running on port 8080. In production, navigates to the root domain (`/`).
void redirectToLandingPage() {
  final hostname = web.window.location.hostname;
  final port = web.window.location.port;
  final isDev = hostname == 'localhost' ||
      hostname == '127.0.0.1' ||
      port == '5000';

  final targetHost = hostname.isNotEmpty ? hostname : 'localhost';
  final targetUrl = isDev ? 'http://$targetHost:8080' : '/';
  web.window.location.href = targetUrl;
}
