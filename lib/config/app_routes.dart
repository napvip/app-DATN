import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/auth/onboarding_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/main/main_screen.dart';
import '../presentation/screens/main/home_screen.dart';
import '../presentation/screens/main/alerts_screen.dart';
import '../presentation/screens/main/insights_screen.dart';
import '../presentation/screens/articles/articles_screen.dart';
import '../presentation/screens/articles/article_detail_screen.dart';
import '../presentation/screens/main/maintenance_screen.dart';
import '../presentation/screens/main/profile_screen.dart';
import '../presentation/screens/main/book_service_screen.dart';
import '../presentation/screens/main/service_detail_screen.dart';
import '../presentation/screens/hive/hive_detail_screen.dart';
import '../presentation/screens/main/chat_screen.dart';
import '../presentation/screens/main/qr_scanner_screen.dart';
import '../presentation/screens/main/sos_alert_screen.dart';

/// Lắng nghe thay đổi trạng thái xác thực Firebase để router tự redirect.
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _sub;

  _AuthNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRoutes {
  AppRoutes._();

  // ---------------------------------------------------------------------------
  // Tên các route
  // ---------------------------------------------------------------------------

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String main = '/app';
  static const String alerts = '/app/alerts';
  static const String insights = '/app/insights';
  static const String articles = '/app/articles';
  static const String articleDetail = '/article';
  static const String maintenance = '/app/maintenance';
  static const String profile = '/app/profile';
  static const String hiveDetail = '/hive/:id';

  // Maintenance feature routes
  static const String bookService = '/book-service';
  static const String serviceDetail = '/service-detail';
  static const String chat = '/chat';

  // Tracking feature routes
  static const String qrScanner = '/qr-scanner';
  static const String sosAlert = '/sos-alert';

  // ---------------------------------------------------------------------------
  // Router
  // ---------------------------------------------------------------------------

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  // Các trang chỉ dành cho người chưa đăng nhập
  static const _authOnlyPaths = {login, register, onboarding, forgotPassword};

  // Prefix của các trang yêu cầu đăng nhập
  static const _protectedPrefix = '/app';

  // Notifier để router tự refresh khi auth state thay đổi
  static final _authNotifier = _AuthNotifier();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: splash,
    refreshListenable: _authNotifier,

    /// Redirect logic:
    /// - Splash tự xử lý chuyển trang → không redirect
    /// - Chưa đăng nhập + vào trang bảo mật → chuyển đến /login
    /// - Đã đăng nhập + còn trên trang auth → chuyển đến /app
    redirect: (BuildContext context, GoRouterState state) {
      final path = state.uri.path;

      // Splash tự quản lý navigation
      if (path == splash) return null;

      final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

      if (!isLoggedIn && path.startsWith(_protectedPrefix)) return login;
      if (isLoggedIn && _authOnlyPaths.contains(path)) return main;

      return null;
    },

    routes: [
      // -----------------------------------------------------------------------
      // Auth routes
      // -----------------------------------------------------------------------
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // -----------------------------------------------------------------------
      // Main app (yêu cầu đăng nhập) – ShellRoute với Bottom Nav
      // -----------------------------------------------------------------------
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: main,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: alerts,
            builder: (context, state) => const AlertsScreen(),
          ),
          GoRoute(
            path: insights,
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: articles,
            builder: (context, state) => const ArticlesScreen(),
          ),
          GoRoute(
            path: maintenance,
            builder: (context, state) => const MaintenanceScreen(),
          ),
          GoRoute(
            path: profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // Standalone routes
      // -----------------------------------------------------------------------
      GoRoute(
        path: hiveDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return HiveDetailScreen(hiveId: id);
        },
      ),
      GoRoute(
        path: '$articleDetail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ArticleDetailScreen(articleId: id);
        },
      ),
      // -----------------------------------------------------------------------
      // Maintenance feature routes
      // -----------------------------------------------------------------------
      GoRoute(
        path: bookService,
        builder: (context, state) => const BookServiceScreen(),
      ),
      GoRoute(
        path: '$serviceDetail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ServiceDetailScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: chat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: qrScanner,
        builder: (context, state) => const QRScannerScreen(),
      ),
      GoRoute(
        path: sosAlert,
        builder: (context, state) => const SOSAlertScreen(),
      ),
    ],
  );
}
