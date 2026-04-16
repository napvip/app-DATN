// Firebase configuration loaded from .env file.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
/// All credentials are loaded from .env file — never hardcoded.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // -------------------------------------------------------------------------
  // Web
  // -------------------------------------------------------------------------
  static FirebaseOptions get web => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_WEB_API_KEY']!,
        appId: dotenv.env['FIREBASE_WEB_APP_ID']!,
        messagingSenderId: dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['FIREBASE_WEB_PROJECT_ID']!,
        authDomain: dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'],
        storageBucket: dotenv.env['FIREBASE_WEB_STORAGE_BUCKET'],
        measurementId: dotenv.env['FIREBASE_WEB_MEASUREMENT_ID'],
      );

  // -------------------------------------------------------------------------
  // Android
  // -------------------------------------------------------------------------
  static FirebaseOptions get android => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY']!,
        appId: dotenv.env['FIREBASE_ANDROID_APP_ID']!,
        messagingSenderId: dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['FIREBASE_ANDROID_PROJECT_ID']!,
        storageBucket: dotenv.env['FIREBASE_ANDROID_STORAGE_BUCKET'],
      );

  // -------------------------------------------------------------------------
  // iOS
  // -------------------------------------------------------------------------
  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_IOS_API_KEY']!,
        appId: dotenv.env['FIREBASE_IOS_APP_ID']!,
        messagingSenderId: dotenv.env['FIREBASE_IOS_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['FIREBASE_IOS_PROJECT_ID']!,
        storageBucket: dotenv.env['FIREBASE_IOS_STORAGE_BUCKET'],
        iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'],
      );
}
