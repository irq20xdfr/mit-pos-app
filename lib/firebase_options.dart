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
    apiKey: 'AIzaSyBc84FWYz-ffPdIHP4XtBNK-5o32RiVWkY',
    appId: '1:33573767162:web:599ca61a35b5f4ffcd4643',
    messagingSenderId: '33573767162',
    projectId: 'mitpos-1b0e0',
    authDomain: 'mitpos-1b0e0.firebaseapp.com',
    storageBucket: 'mitpos-1b0e0.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCmyZdsqbu0PYmE9p6DVEznuWieerwCXNU',
    appId: '1:33573767162:android:a78ab8b76ae0b0e1cd4643',
    messagingSenderId: '33573767162',
    projectId: 'mitpos-1b0e0',
    storageBucket: 'mitpos-1b0e0.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChLS7jGGO7apHUM9mhOBpj4tJz1VWztiQ',
    appId: '1:33573767162:ios:6867e5c409b7f5f0cd4643',
    messagingSenderId: '33573767162',
    projectId: 'mitpos-1b0e0',
    storageBucket: 'mitpos-1b0e0.appspot.com',
    iosBundleId: 'com.example.mitPos',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyChLS7jGGO7apHUM9mhOBpj4tJz1VWztiQ',
    appId: '1:33573767162:ios:6867e5c409b7f5f0cd4643',
    messagingSenderId: '33573767162',
    projectId: 'mitpos-1b0e0',
    storageBucket: 'mitpos-1b0e0.appspot.com',
    iosBundleId: 'com.example.mitPos',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBc84FWYz-ffPdIHP4XtBNK-5o32RiVWkY',
    appId: '1:33573767162:web:b985ddec7df63e58cd4643',
    messagingSenderId: '33573767162',
    projectId: 'mitpos-1b0e0',
    authDomain: 'mitpos-1b0e0.firebaseapp.com',
    storageBucket: 'mitpos-1b0e0.appspot.com',
  );
}
