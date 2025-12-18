import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

const String _projectId = 'finalproject-11310';
const String _storageBucket = 'tm_flutter_app.appspot.com';
const String _messagingSenderId = '000000000000';
const String _apiKey = 'AIzaSyDUMMYKEY';
const String _androidAppId = '1:000:android:abcdef123456';
const String _iosAppId = '1:000:ios:abcdef123456';
const String _webAppId = '1:000:web:abcdef123456';

const FirebaseOptions _android = FirebaseOptions(
  apiKey: _apiKey,
  appId: _androidAppId,
  messagingSenderId: _messagingSenderId,
  projectId: _projectId,
  storageBucket: _storageBucket,
);

const FirebaseOptions _ios = FirebaseOptions(
  apiKey: _apiKey,
  appId: _iosAppId,
  messagingSenderId: _messagingSenderId,
  projectId: _projectId,
  storageBucket: _storageBucket,
);

const FirebaseOptions _web = FirebaseOptions(
  apiKey: _apiKey,
  appId: _webAppId,
  messagingSenderId: _messagingSenderId,
  projectId: _projectId,
  storageBucket: _storageBucket,
  measurementId: 'G-XXXXXXXXXX',
);

const FirebaseOptions _macos = _ios;
const FirebaseOptions _windows = _android;
const FirebaseOptions _linux = _android;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return _web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      case TargetPlatform.macOS:
        return _macos;
      case TargetPlatform.windows:
        return _windows;
      case TargetPlatform.linux:
        return _linux;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported on this platform.');
    }
  }
}
