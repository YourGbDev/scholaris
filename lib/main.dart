import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/supabase_config.dart';
import 'core/auth/tab_scoped_local_storage.dart';
import 'core/security/login_lockout_service.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The web deep-link targets (email confirmation and password recovery) are
  // path-based URLs (e.g. /verify-email), so the web app must route on the
  // path rather than go_router's default hash strategy.
  usePathUrlStrategy();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: kIsWeb
          ? TabScopedLocalStorage(
              persistSessionKey:
                  'sb-${Uri.parse(SupabaseConfig.url).host.split('.').first}-auth-token',
            )
          : null,
    ),
  );

  await LoginLockoutService.instance.initPrefs();

  runApp(const ProviderScope(child: ScholarisApp()));
}

class ScholarisApp extends ConsumerWidget {
  const ScholarisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Scholaris',
      debugShowCheckedModeBanner: false,
      theme: scholarisTheme(),
      routerConfig: router,
    );
  }
}