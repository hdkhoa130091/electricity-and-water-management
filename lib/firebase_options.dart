
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA4K4zmWxysgA56ZkEw_YcrUtuMbfal2nY',
    appId: '1:864637371545:web:abb23596d3314137436408',
    messagingSenderId: '864637371545',
    projectId: 'dienthoai-21482',
    authDomain: 'dienthoai-21482.firebaseapp.com',
    databaseURL: 'https://dienthoai-21482-default-rtdb.firebaseio.com',
    storageBucket: 'dienthoai-21482.firebasestorage.app',
    measurementId: 'G-7LX8CPN3C9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABXXHIe-4cvj0HEN7hrjtQoh_Za0jawc8',
    appId: '1:864637371545:android:374b01c0c9b63d87436408',
    messagingSenderId: '864637371545',
    projectId: 'dienthoai-21482',
    databaseURL: 'https://dienthoai-21482-default-rtdb.firebaseio.com',
    storageBucket: 'dienthoai-21482.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAUgG-g_FKwFvyt_0aBr3HKXmIQ3bMvMaY',
    appId: '1:864637371545:ios:aafb06225d668469436408',
    messagingSenderId: '864637371545',
    projectId: 'dienthoai-21482',
    databaseURL: 'https://dienthoai-21482-default-rtdb.firebaseio.com',
    storageBucket: 'dienthoai-21482.firebasestorage.app',
    iosBundleId: 'com.example.done',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAUgG-g_FKwFvyt_0aBr3HKXmIQ3bMvMaY',
    appId: '1:864637371545:ios:aafb06225d668469436408',
    messagingSenderId: '864637371545',
    projectId: 'dienthoai-21482',
    databaseURL: 'https://dienthoai-21482-default-rtdb.firebaseio.com',
    storageBucket: 'dienthoai-21482.firebasestorage.app',
    iosBundleId: 'com.example.done',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA4K4zmWxysgA56ZkEw_YcrUtuMbfal2nY',
    appId: '1:864637371545:web:3e22b558570264ef436408',
    messagingSenderId: '864637371545',
    projectId: 'dienthoai-21482',
    authDomain: 'dienthoai-21482.firebaseapp.com',
    databaseURL: 'https://dienthoai-21482-default-rtdb.firebaseio.com',
    storageBucket: 'dienthoai-21482.firebasestorage.app',
    measurementId: 'G-ZYCKT4GSJ7',
  );
}
