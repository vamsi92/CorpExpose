// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyC2MSlTtv_-1IzDWREUkGoJHjhuBarWdnc',
    appId: '1:461542063805:web:9895908ff013d9561b81d4',
    messagingSenderId: '461542063805',
    projectId: 'corpexpose-b720d',
    authDomain: 'corpexpose-b720d.firebaseapp.com',
    databaseURL: 'https://corpexpose-b720d-default-rtdb.firebaseio.com',
    storageBucket: 'corpexpose-b720d.appspot.com',
    measurementId: 'G-6L0LLW3XCQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAyqxx_Zyw4WpJYfZ0RLb4j_1akpd1wP3Y',
    appId: '1:461542063805:android:7c2e1a177bb8886f1b81d4',
    messagingSenderId: '461542063805',
    projectId: 'corpexpose-b720d',
    databaseURL: 'https://corpexpose-b720d-default-rtdb.firebaseio.com',
    storageBucket: 'corpexpose-b720d.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCt-CUTlBZAQDrpTDtRiYtQdvKel2_OwQk',
    appId: '1:461542063805:ios:e37d75433f0231191b81d4',
    messagingSenderId: '461542063805',
    projectId: 'corpexpose-b720d',
    databaseURL: 'https://corpexpose-b720d-default-rtdb.firebaseio.com',
    storageBucket: 'corpexpose-b720d.appspot.com',
    iosClientId: '461542063805-2ldavrqi41ohftg16sqg1ab73h5cdu75.apps.googleusercontent.com',
    iosBundleId: 'com.nologicapps.corpExpose',
  );

}